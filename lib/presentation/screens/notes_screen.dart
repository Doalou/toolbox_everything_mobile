import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/services/app_feedback.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_components.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
import 'package:toolbox_everything_mobile/shared/widgets/status_badge.dart';

class NotesScreen extends StatefulWidget {
  final String heroTag;

  const NotesScreen({super.key, required this.heroTag});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _saveController;
  late Animation<double> _saveAnimation;

  bool _isLoading = true;
  bool _hasUnsavedChanges = false;
  String _lastSavedText = '';
  int _characterCount = 0;
  int _wordCount = 0;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();

    _saveController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _saveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _saveController, curve: Curves.easeOutBack),
    );

    _textController.addListener(_onTextChanged);
    _loadNotes();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _saveController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text;
    final hasChanges = text != _lastSavedText;

    setState(() {
      _hasUnsavedChanges = hasChanges;
      _characterCount = text.length;
      _wordCount = text.trim().isEmpty
          ? 0
          : text.trim().split(RegExp(r'\s+')).length;
    });

    _debounceAutoSave();
  }

  void _debounceAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (_hasUnsavedChanges) {
        _saveNotes(showFeedback: false);
      }
    });
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedText = prefs.getString('temp_notes') ?? '';

      if (!mounted) return;
      setState(() {
        _textController.text = savedText;
        _lastSavedText = savedText;
        _characterCount = savedText.length;
        _wordCount = savedText.trim().isEmpty
            ? 0
            : savedText.trim().split(RegExp(r'\s+')).length;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveNotes({bool showFeedback = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('temp_notes', _textController.text);

      if (!mounted) return;
      setState(() {
        _lastSavedText = _textController.text;
        _hasUnsavedChanges = false;
      });

      _saveController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _saveController.reverse();
        });
      });

      if (showFeedback) {
        AppFeedback.show(
          context,
          'Notes enregistrées',
          tone: FeedbackTone.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.show(
          context,
          'Erreur lors de la sauvegarde : $e',
          tone: FeedbackTone.error,
        );
      }
    }
  }

  void _clearNotes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer les notes'),
        content: const Text(
          'Êtes-vous sûr de vouloir effacer toutes vos notes ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              _textController.clear();
              _saveNotes(showFeedback: false);
              Navigator.pop(context);
              AppFeedback.show(this.context, 'Notes effacées');
            },
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }

  void _copyNotes() {
    if (_textController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _textController.text));
      AppFeedback.copied(context, 'Notes copiées dans le presse-papiers');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return EditorialToolScaffold(
        title: 'Bloc-notes',
        heroTag: widget.heroTag,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    return EditorialToolScaffold(
      title: 'Bloc-notes',
      heroTag: widget.heroTag,
      floatingActionButton: FloatingActionButton(
        heroTag: 'notes_edit',
        onPressed: () => _focusNode.requestFocus(),
        tooltip: 'Écrire',
        child: const Icon(Icons.edit_rounded),
      ),
      actions: [
        AnimatedBuilder(
          animation: _saveAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1 + (_saveAnimation.value * 0.15),
              child: IconButton(
                onPressed: () => _saveNotes(showFeedback: true),
                icon: Icon(
                  _hasUnsavedChanges
                      ? Icons.save_rounded
                      : Icons.check_circle_rounded,
                  color: _hasUnsavedChanges
                      ? colorScheme.primary
                      : colorScheme.tertiary,
                ),
                tooltip: 'Sauvegarder',
              ),
            );
          },
        ),
        IconButton(
          onPressed: _copyNotes,
          icon: Icon(Icons.content_copy_rounded, color: colorScheme.primary),
          tooltip: 'Copier',
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: colorScheme.primary),
          onSelected: (value) {
            switch (value) {
              case 'clear':
                _clearNotes();
              case 'focus':
                _focusNode.requestFocus();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'focus',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded),
                  SizedBox(width: 10),
                  Text('Focus écriture'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, color: colorScheme.error),
                  const SizedBox(width: 10),
                  Text(
                    'Effacer tout',
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: EditorialToolIntro(
              icon: Icons.note_alt_rounded,
              title: 'Notes locales',
              description: '$_characterCount caractères · $_wordCount mots',
              trailing: StatusBadge(
                label: _hasUnsavedChanges ? 'En cours…' : 'Sauvegardé',
                icon: _hasUnsavedChanges
                    ? Icons.sync_rounded
                    : Icons.cloud_done_rounded,
                tone: _hasUnsavedChanges ? BadgeTone.accent : BadgeTone.success,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(
                  ExpressiveShapes.largeIncreased,
                ),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: _focusNode.hasFocus ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.6, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Écrivez vos notes locales ici…',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
