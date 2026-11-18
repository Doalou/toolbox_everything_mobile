import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/feature_flags/app_feature_flags.dart';
import 'package:toolbox_everything_mobile/core/models/note_item.dart';
import 'package:toolbox_everything_mobile/core/services/app_feedback.dart';
import 'package:toolbox_everything_mobile/core/services/downloads_saver.dart';
import 'package:toolbox_everything_mobile/core/services/haptics_service.dart';
import 'package:toolbox_everything_mobile/core/services/notes_service.dart';
import 'package:toolbox_everything_mobile/core/services/timestamp_service.dart';
import 'package:toolbox_everything_mobile/presentation/navigation/unified_navigation.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_components.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';
import 'package:toolbox_everything_mobile/shared/widgets/simple_markdown_view.dart';
import 'package:toolbox_everything_mobile/shared/widgets/status_badge.dart';

class NotesScreen extends StatefulWidget {
  final String heroTag;
  final String? initialSharedText;

  const NotesScreen({super.key, required this.heroTag, this.initialSharedText});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NotesService _notesService = const NotesService();
  final TimestampService _timestampService = const TimestampService();
  final TextEditingController _searchController = TextEditingController();

  List<NoteItem> _notes = [];
  bool _isLoading = true;
  bool _pinnedOnly = false;
  String? _selectedTag;
  bool _consumedInitialText = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    try {
      final loaded = await _notesService.loadNotes();
      if (!mounted) return;
      setState(() {
        _notes = loaded;
        _isLoading = false;
      });
      if (!_consumedInitialText &&
          widget.initialSharedText != null &&
          widget.initialSharedText!.trim().isNotEmpty) {
        _consumedInitialText = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _openEditor(initialContent: widget.initialSharedText);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openEditor({NoteItem? existing, String? initialContent}) async {
    final now = DateTime.now();
    final target =
        existing ??
        NoteItem(
          id: now.microsecondsSinceEpoch.toString(),
          title: '',
          content: initialContent ?? '',
          createdAt: now,
          updatedAt: now,
        );
    Future<void>? pendingSave;
    await Navigator.of(context).push(
      unifiedNavigation(
        context,
        _NoteEditorScreen(
          initialNote: target,
          isNew: existing == null,
          notesService: _notesService,
          onSaveStarted: (future) => pendingSave = future,
        ),
      ),
    );
    if (pendingSave != null) {
      await pendingSave;
    }
    if (mounted) {
      await _loadNotes();
    }
  }

  Future<void> _togglePin(NoteItem note) async {
    HapticsService.perform(context, HapticType.selection);
    final updated = await _notesService.upsertNote(
      note.copyWith(isPinned: !note.isPinned),
    );
    if (!mounted) return;
    setState(() => _notes = updated);
  }

  Future<void> _confirmDelete(NoteItem note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la note'),
        content: Text(
          'Supprimer « ${note.displayTitle} » ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final updated = await _notesService.deleteNote(note.id);
      if (!mounted) return;
      setState(() => _notes = updated);
      AppFeedback.show(context, 'Note supprimée');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allTags = _notesService.collectAllTags(_notes);
    final filtered = _notesService.filterNotes(
      _notes,
      query: _searchController.text,
      tag: _selectedTag,
      pinnedOnly: _pinnedOnly,
    );
    final pinnedCount = _notes.where((n) => n.isPinned).length;

    return EditorialToolScaffold(
      title: 'Bloc-notes',
      heroTag: widget.heroTag,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'notes_add',
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle note'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: EditorialToolIntro(
                    icon: Icons.note_alt_rounded,
                    title: 'Notes & checklists locales',
                    description:
                        '${_notes.length} note(s) · $pinnedCount épinglée(s)',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par titre, texte ou tag…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: _searchController.clear,
                              icon: const Icon(Icons.clear_rounded),
                            )
                          : null,
                    ),
                  ),
                ),
                if (_notes.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Toutes'),
                          selected: !_pinnedOnly && _selectedTag == null,
                          onSelected: (_) {
                            setState(() {
                              _pinnedOnly = false;
                              _selectedTag = null;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          avatar: const Icon(Icons.push_pin_rounded, size: 16),
                          label: const Text('Épinglées'),
                          selected: _pinnedOnly,
                          onSelected: (v) => setState(() => _pinnedOnly = v),
                        ),
                        for (final tag in allTags) ...[
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text('#$tag'),
                            selected: _selectedTag == tag,
                            onSelected: (v) {
                              setState(() => _selectedTag = v ? tag : null);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState(colorScheme)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) =>
                              _buildNoteCard(filtered[index], colorScheme),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    final hasFilter =
        _searchController.text.isNotEmpty ||
        _pinnedOnly ||
        _selectedTag != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilter ? Icons.search_off_rounded : Icons.note_add_rounded,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              hasFilter
                  ? 'Aucune note ne correspond au filtre'
                  : 'Aucune note enregistrée',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              hasFilter
                  ? 'Essayez un autre mot-clé ou réinitialisez les filtres.'
                  : 'Créez des notes Markdown avec listes de tâches, tags et export .md/.txt/PDF.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(NoteItem note, ColorScheme colorScheme) {
    final checklist = note.checklistStats;
    final excerpt = note.content
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(2)
        .join(' · ');

    return ExpressiveCard(
      onTap: () => _openEditor(existing: note),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.displayTitle,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => _togglePin(note),
                icon: Icon(
                  note.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  size: 19,
                  color: note.isPinned
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                tooltip: note.isPinned ? 'Désépingler' : 'Épingler',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => _confirmDelete(note),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: colorScheme.error,
                ),
                tooltip: 'Supprimer',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (excerpt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              excerpt,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(
                label: _timestampService.relativeFromNow(note.updatedAt),
                icon: Icons.schedule_rounded,
                tone: BadgeTone.neutral,
              ),
              if (checklist.total > 0)
                StatusBadge(
                  label: '${checklist.done}/${checklist.total}',
                  icon: Icons.checklist_rounded,
                  tone: checklist.done == checklist.total
                      ? BadgeTone.success
                      : BadgeTone.accent,
                ),
              for (final tag in note.tags)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: ShapeDecoration(
                    color: colorScheme.secondaryContainer,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoteEditorScreen extends StatefulWidget {
  final NoteItem initialNote;
  final bool isNew;
  final NotesService notesService;
  final ValueChanged<Future<void>>? onSaveStarted;

  const _NoteEditorScreen({
    required this.initialNote,
    required this.isNew,
    required this.notesService,
    this.onSaveStarted,
  });

  @override
  State<_NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<_NoteEditorScreen> {
  late NoteItem _note;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final FocusNode _contentFocus = FocusNode();

  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _previewMode = false;
  bool _deleted = false;

  @override
  void initState() {
    super.initState();
    _note = widget.initialNote;
    _titleController = TextEditingController(text: _note.title);
    _contentController = TextEditingController(text: _note.content);
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  bool get _hasAnyContent =>
      _titleController.text.trim().isNotEmpty ||
      _contentController.text.trim().isNotEmpty ||
      _note.tags.isNotEmpty;

  void _onChanged() {
    if (!mounted) return;
    setState(() {
      _hasUnsavedChanges = true;
    });
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), () {
      _saveNow(showFeedback: false);
    });
  }

  Future<void> _saveNow({bool showFeedback = true}) async {
    Future<void> performSave() async {
      _autoSaveTimer?.cancel();
      if (_deleted) return;
      if (widget.isNew && !_hasAnyContent) return;

      final updated = _note.copyWith(
        title: _titleController.text,
        content: _contentController.text,
        updatedAt: DateTime.now(),
      );
      await widget.notesService.upsertNote(updated);
      if (!mounted) return;
      setState(() {
        _note = updated;
        _hasUnsavedChanges = false;
      });
      if (showFeedback) {
        AppFeedback.show(
          context,
          'Note enregistrée',
          tone: FeedbackTone.success,
        );
      }
    }

    final future = performSave();
    widget.onSaveStarted?.call(future);
    await future;
  }

  void _insertSnippet(String snippet, {bool newLine = false}) {
    HapticsService.perform(context, HapticType.selection);
    final text = _contentController.text;
    final selection = _contentController.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final prefix = newLine && start > 0 && text[start - 1] != '\n' ? '\n' : '';
    final inserted = '$prefix$snippet';
    final nextText = text.replaceRange(start, end, inserted);
    _contentController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: start + inserted.length),
    );
    _contentFocus.requestFocus();
  }

  Future<void> _addTagDialog() async {
    var draftTag = '';
    final tag = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajouter un tag'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ex : courses, dev, idée',
          ),
          onChanged: (v) => draftTag = v,
          onSubmitted: (v) => Navigator.pop(dialogContext, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, draftTag),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (tag == null) return;
    final cleaned = tag.trim().replaceAll('#', '');
    if (cleaned.isEmpty || _note.tags.contains(cleaned)) return;
    setState(() {
      _note = _note.copyWith(tags: [..._note.tags, cleaned]);
      _hasUnsavedChanges = true;
    });
    await _saveNow(showFeedback: false);
  }

  Future<void> _exportTextFile(String ext) async {
    await _saveNow(showFeedback: false);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final rawTitle = _note.displayTitle
          .replaceAll(RegExp(r'[^\w\-]+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');
      final safeBase = rawTitle.isEmpty ? 'note' : rawTitle;
      final fileName =
          '${safeBase}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final file = File('${dir.path}/$fileName');
      final buffer = StringBuffer();
      if (_note.title.trim().isNotEmpty) {
        if (ext == 'md') {
          buffer.writeln('# ${_note.title.trim()}');
          buffer.writeln();
        } else {
          buffer.writeln(_note.title.trim());
          buffer.writeln();
        }
      }
      buffer.write(_contentController.text);
      await file.writeAsString(buffer.toString());
      final saved = await DownloadsSaver.saveFileToDownloads(
        file.path,
        displayName: fileName,
        mimeType: ext == 'md' ? 'text/markdown' : 'text/plain',
      );
      if (mounted) {
        AppFeedback.show(
          context,
          'Exporté : $saved',
          tone: FeedbackTone.success,
          icon: Icons.download_done_rounded,
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.show(
          context,
          'Erreur export : $e',
          tone: FeedbackTone.error,
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    if (!AppFeatureFlags.pdfExport) return;
    await _saveNow(showFeedback: false);
    try {
      final doc = pw.Document();
      final body = _contentController.text;
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (_) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                _note.displayTitle,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Paragraph(
              text: body.isEmpty ? ' ' : body,
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
            ),
          ],
        ),
      );
      await Printing.layoutPdf(onLayout: (_) async => doc.save());
    } catch (e) {
      if (mounted) {
        AppFeedback.show(
          context,
          'Erreur export PDF : $e',
          tone: FeedbackTone.error,
        );
      }
    }
  }

  Future<void> _deleteCurrent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette note'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _deleted = true;
      await widget.notesService.deleteNote(_note.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = _contentController.text;
    final chars = text.length;
    final words = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).length;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop &&
            !_deleted &&
            (_hasUnsavedChanges || (widget.isNew && _hasAnyContent))) {
          unawaited(_saveNow(showFeedback: false));
        }
      },
      child: EditorialToolScaffold(
        title: _note.displayTitle,
        heroTag: 'note-editor-${_note.id}',
        actions: [
          IconButton(
            onPressed: () async {
              HapticsService.perform(context, HapticType.selection);
              setState(() {
                _note = _note.copyWith(isPinned: !_note.isPinned);
                _hasUnsavedChanges = true;
              });
              await _saveNow(showFeedback: false);
            },
            icon: Icon(
              _note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: _note.isPinned ? colorScheme.primary : null,
            ),
            tooltip: _note.isPinned ? 'Désépingler' : 'Épingler',
          ),
          IconButton(
            onPressed: () {
              final full = _titleController.text.trim().isEmpty
                  ? text
                  : '${_titleController.text.trim()}\n\n$text';
              if (full.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: full));
                AppFeedback.copied(context, 'Note copiée');
              }
            },
            icon: const Icon(Icons.content_copy_rounded),
            tooltip: 'Copier',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'save':
                  _saveNow(showFeedback: true);
                case 'export_md':
                  _exportTextFile('md');
                case 'export_txt':
                  _exportTextFile('txt');
                case 'export_pdf':
                  _exportPdf();
                case 'delete':
                  _deleteCurrent();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.save_rounded),
                    SizedBox(width: 10),
                    Text('Enregistrer maintenant'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_md',
                child: Row(
                  children: [
                    Icon(Icons.description_rounded),
                    SizedBox(width: 10),
                    Text('Exporter en .md'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_txt',
                child: Row(
                  children: [
                    Icon(Icons.text_snippet_rounded),
                    SizedBox(width: 10),
                    Text('Exporter en .txt'),
                  ],
                ),
              ),
              if (AppFeatureFlags.pdfExport)
                const PopupMenuItem(
                  value: 'export_pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf_rounded),
                      SizedBox(width: 10),
                      Text('Exporter en PDF'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Supprimer',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.edit_rounded, size: 17),
                          label: Text('Éditer'),
                        ),
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.visibility_rounded, size: 17),
                          label: Text('Aperçu MD'),
                        ),
                      ],
                      selected: {_previewMode},
                      onSelectionChanged: (s) {
                        setState(() => _previewMode = s.first);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  StatusBadge(
                    label: _hasUnsavedChanges ? 'En cours…' : 'Sauvegardé',
                    icon: _hasUnsavedChanges
                        ? Icons.sync_rounded
                        : Icons.cloud_done_rounded,
                    tone: _hasUnsavedChanges
                        ? BadgeTone.accent
                        : BadgeTone.success,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _titleController,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: 'Fraunces',
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  hintText: 'Titre de la note…',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final tag in _note.tags) ...[
                    InputChip(
                      label: Text('#$tag'),
                      onDeleted: () async {
                        setState(() {
                          _note = _note.copyWith(
                            tags: _note.tags.where((t) => t != tag).toList(),
                          );
                          _hasUnsavedChanges = true;
                        });
                        await _saveNow(showFeedback: false);
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                  ActionChip(
                    avatar: const Icon(Icons.label_outline_rounded, size: 16),
                    label: const Text('Ajouter un tag'),
                    onPressed: _addTagDialog,
                  ),
                ],
              ),
            ),
            if (!_previewMode)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                child: Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.check_box_outlined, size: 16),
                      label: const Text('Tâche'),
                      onPressed: () => _insertSnippet('- [ ] ', newLine: true),
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      avatar: const Icon(Icons.title_rounded, size: 16),
                      label: const Text('Titre'),
                      onPressed: () => _insertSnippet('## ', newLine: true),
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      avatar: const Icon(Icons.format_bold_rounded, size: 16),
                      label: const Text('Gras'),
                      onPressed: () => _insertSnippet('**texte**'),
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      avatar: const Icon(Icons.code_rounded, size: 16),
                      label: const Text('Code'),
                      onPressed: () => _insertSnippet('`code`'),
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      avatar: const Icon(Icons.format_list_bulleted, size: 16),
                      label: const Text('Liste'),
                      onPressed: () => _insertSnippet('- ', newLine: true),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(
                    ExpressiveShapes.largeIncreased,
                  ),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: _previewMode
                    ? SingleChildScrollView(
                        child: SimpleMarkdownView(
                          content: _contentController.text,
                          onToggleChecklistLine: (lineIndex) {
                            HapticsService.perform(
                              context,
                              HapticType.selection,
                            );
                            final next = widget.notesService
                                .toggleChecklistLine(
                                  _contentController.text,
                                  lineIndex,
                                );
                            _contentController.text = next;
                            _saveNow(showFeedback: false);
                          },
                        ),
                      )
                    : TextField(
                        controller: _contentController,
                        focusNode: _contentFocus,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(height: 1.55, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'Écrivez en texte brut ou Markdown (# titre, - [ ] tâche, **gras**…)',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Text(
                    '$chars caractères · $words mots',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
