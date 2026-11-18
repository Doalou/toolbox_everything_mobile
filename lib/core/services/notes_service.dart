import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/models/note_item.dart';

class NotesService {
  const NotesService();

  static const String notesKey = 'notes_v2_items';
  static const String migratedKey = 'notes_v2_migrated';
  static const String legacyNotesKey = 'temp_notes';

  static Future<SharedPreferences> _preferences(
    SharedPreferences? preferences,
  ) async => preferences ?? SharedPreferences.getInstance();

  List<NoteItem> decodeNotesList(dynamic rawList) {
    if (rawList is! List) return [];
    final items = <NoteItem>[];
    for (final entry in rawList) {
      if (entry is Map<String, dynamic>) {
        items.add(NoteItem.fromJson(entry));
      } else if (entry is Map) {
        items.add(
          NoteItem.fromJson(entry.map((k, v) => MapEntry(k.toString(), v))),
        );
      }
    }
    return sortNotes(items);
  }

  List<NoteItem> sortNotes(List<NoteItem> notes) {
    final copy = List<NoteItem>.from(notes);
    copy.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return copy;
  }

  Future<List<NoteItem>> loadNotes({SharedPreferences? preferences}) async {
    final prefs = await _preferences(preferences);
    final migrated = prefs.getBool(migratedKey) ?? false;

    List<NoteItem> current = [];
    final rawJson = prefs.getString(notesKey);
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        current = decodeNotesList(json.decode(rawJson));
      } catch (_) {
        current = [];
      }
    }

    if (!migrated) {
      final legacyText = prefs.getString(legacyNotesKey) ?? '';
      if (legacyText.trim().isNotEmpty &&
          !current.any((n) => n.id == 'legacy-migrated-note')) {
        final firstLine = legacyText
            .split('\n')
            .map((e) => e.trim())
            .firstWhere((e) => e.isNotEmpty, orElse: () => 'Note importée');
        final title = firstLine.length > 50
            ? '${firstLine.substring(0, 50)}…'
            : firstLine;
        final now = DateTime.now();
        current.add(
          NoteItem(
            id: 'legacy-migrated-note',
            title: title,
            content: legacyText,
            isPinned: true,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await prefs.setString(
          notesKey,
          json.encode(sortNotes(current).map((e) => e.toJson()).toList()),
        );
      }
      await prefs.setBool(migratedKey, true);
    }

    return sortNotes(current);
  }

  Future<void> saveNotes(
    List<NoteItem> notes, {
    SharedPreferences? preferences,
  }) async {
    final prefs = await _preferences(preferences);
    final sorted = sortNotes(notes);
    await prefs.setString(
      notesKey,
      json.encode(sorted.map((e) => e.toJson()).toList()),
    );
    await prefs.setBool(migratedKey, true);
  }

  Future<List<NoteItem>> upsertNote(
    NoteItem note, {
    SharedPreferences? preferences,
  }) async {
    final notes = await loadNotes(preferences: preferences);
    final index = notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      notes[index] = note;
    } else {
      notes.add(note);
    }
    final sorted = sortNotes(notes);
    await saveNotes(sorted, preferences: preferences);
    return sorted;
  }

  Future<List<NoteItem>> deleteNote(
    String id, {
    SharedPreferences? preferences,
  }) async {
    final notes = await loadNotes(preferences: preferences);
    notes.removeWhere((n) => n.id == id);
    await saveNotes(notes, preferences: preferences);
    return notes;
  }

  List<NoteItem> filterNotes(
    List<NoteItem> notes, {
    String query = '',
    String? tag,
    bool pinnedOnly = false,
  }) {
    final q = query.trim().toLowerCase();
    return notes.where((note) {
      if (pinnedOnly && !note.isPinned) return false;
      if (tag != null && !note.tags.contains(tag)) return false;
      if (q.isEmpty) return true;
      final haystack = '${note.title}\n${note.content}\n${note.tags.join(' ')}'
          .toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  List<String> collectAllTags(List<NoteItem> notes) {
    final tags = <String>{for (final note in notes) ...note.tags}.toList();
    tags.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return tags;
  }

  String toggleChecklistLine(String content, int lineIndex) {
    final lines = content.split('\n');
    if (lineIndex < 0 || lineIndex >= lines.length) return content;

    final match = RegExp(r'^(\s*- \[)( |x|X)(\].*)$')
        .firstMatch(lines[lineIndex]);
    if (match == null) return content;

    final current = match.group(2)!;
    final replacement = current == ' ' ? 'x' : ' ';
    lines[lineIndex] = '${match.group(1)}$replacement${match.group(3)}';
    return lines.join('\n');
  }
}
