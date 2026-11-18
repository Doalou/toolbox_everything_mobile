class NoteItem {
  static final RegExp checklistPattern = RegExp(
    r'^\s*- \[( |x|X)\](?:\s+(.*))?$',
  );

  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteItem({
    required this.id,
    required this.title,
    required this.content,
    this.tags = const [],
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayTitle {
    final trimmed = title.trim();
    if (trimmed.isNotEmpty) return trimmed;
    for (final rawLine in content.split('\n')) {
      final cleaned = rawLine
          .trim()
          .replaceFirst(RegExp(r'^#{1,6}\s+'), '')
          .replaceFirst(RegExp(r'^- \[( |x|X)\]\s*'), '')
          .trim();
      if (cleaned.isNotEmpty) {
        return cleaned.length > 48 ? '${cleaned.substring(0, 48)}…' : cleaned;
      }
    }
    return 'Note sans titre';
  }

  ({int done, int total}) get checklistStats {
    var done = 0;
    var total = 0;
    for (final line in content.split('\n')) {
      final match = checklistPattern.firstMatch(line);
      if (match != null) {
        total++;
        if ((match.group(1) ?? '').toLowerCase() == 'x') {
          done++;
        }
      }
    }
    return (done: done, total: total);
  }

  NoteItem copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'tags': tags,
    'isPinned': isPinned,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toUtc();
    return NoteItem(
      id: json['id']?.toString() ?? now.microsecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      tags:
          (json['tags'] as List?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList() ??
          const [],
      isPinned: json['isPinned'] == true,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
          now.toLocal(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toLocal() ??
          now.toLocal(),
    );
  }
}
