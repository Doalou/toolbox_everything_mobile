import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();

    _saveController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _saveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _saveController, curve: Curves.elasticOut),
    );

    _textController.addListener(_onTextChanged);
    _loadNotes();
  }

  @override
  void dispose() {
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

    // Auto-save après 2 secondes d'inactivité
    _debounceAutoSave();
  }

  Timer? _autoSaveTimer;
  void _debounceAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (_hasUnsavedChanges) {
        _saveNotes();
      }
    });
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedText = prefs.getString('temp_notes') ?? '';

      setState(() {
        _textController.text = savedText;
        _lastSavedText = savedText;
        _characterCount = savedText.length;
        _wordCount = savedText.trim().isEmpty
            ? 0
            : savedText.trim().split(RegExp(r'\s+')).length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('temp_notes', _textController.text);

      setState(() {
        _lastSavedText = _textController.text;
        _hasUnsavedChanges = false;
      });

      _saveController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) _saveController.reverse();
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Notes sauvegardées automatiquement'),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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
              _saveNotes();
              Navigator.pop(context);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.content_copy, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Notes copiées dans le presse-papiers'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Hero(
          tag: widget.heroTag,
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              'Bloc-notes temporaire',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          AnimatedBuilder(
            animation: _saveAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + (_saveAnimation.value * 0.2),
                child: IconButton(
                  onPressed: _saveNotes,
                  icon: Icon(
                    _hasUnsavedChanges ? Icons.save : Icons.check_circle,
                    color: _hasUnsavedChanges
                        ? colorScheme.primary
                        : Colors.green,
                  ),
                  tooltip: 'Sauvegarder',
                ),
              );
            },
          ),
          IconButton(
            onPressed: _copyNotes,
            icon: Icon(Icons.content_copy, color: colorScheme.primary),
            tooltip: 'Copier',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colorScheme.primary),
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _clearNotes();
                  break;
                case 'focus':
                  _focusNode.requestFocus();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'focus',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Focus écriture'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Effacer tout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header avec statistiques
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.note_add,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes temporaires',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatChip('$_characterCount caractères'),
                          const SizedBox(width: 8),
                          _buildStatChip('$_wordCount mots'),
                          const SizedBox(width: 8),
                          if (_hasUnsavedChanges)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Non sauvé',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Zone de texte principale
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.2),
                  width: _focusNode.hasFocus ? 2 : 1,
                ),
                boxShadow: [
                  if (_focusNode.hasFocus)
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
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
                  hintText:
                      'Écrivez vos notes temporaires ici...\n\n• Sauvegarde automatique\n• Persistance entre les sessions\n• Compteur de mots en temps réel',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    height: 1.6,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
          ),

          // Barre d'outils en bas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sauvegarde automatique activée',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  heroTag: "notes_edit",
                  onPressed: () => _focusNode.requestFocus(),
                  backgroundColor: colorScheme.primary,
                  child: Icon(Icons.edit, color: colorScheme.onPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
