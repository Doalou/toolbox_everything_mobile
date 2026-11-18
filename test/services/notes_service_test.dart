import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/models/note_item.dart';
import 'package:toolbox_everything_mobile/core/services/notes_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotesService', () {
    const svc = NotesService();

    test('migre automatiquement temp_notes sans perte', () async {
      SharedPreferences.setMockInitialValues({
        NotesService.legacyNotesKey: 'Liste de courses\n- [ ] Lait\n- [x] Pain',
      });
      final prefs = await SharedPreferences.getInstance();

      final notes = await svc.loadNotes(preferences: prefs);

      expect(notes, hasLength(1));
      expect(notes.first.id, 'legacy-migrated-note');
      expect(notes.first.title, 'Liste de courses');
      expect(notes.first.isPinned, isTrue);
      expect(notes.first.checklistStats, (done: 1, total: 2));
      expect(prefs.getBool(NotesService.migratedKey), isTrue);
    });

    test(
      'trie les notes épinglées d’abord puis par date de mise à jour',
      () async {
        final t1 = DateTime.utc(2026, 1, 1, 10);
        final t2 = DateTime.utc(2026, 1, 2, 10);
        final t3 = DateTime.utc(2026, 1, 3, 10);

        final notes = [
          NoteItem(
            id: '1',
            title: 'Ancienne épinglée',
            content: '',
            isPinned: true,
            createdAt: t1,
            updatedAt: t1,
          ),
          NoteItem(
            id: '2',
            title: 'Récente normale',
            content: '',
            isPinned: false,
            createdAt: t3,
            updatedAt: t3,
          ),
          NoteItem(
            id: '3',
            title: 'Plus récente épinglée',
            content: '',
            isPinned: true,
            createdAt: t2,
            updatedAt: t2,
          ),
        ];

        final sorted = svc.sortNotes(notes);
        expect(sorted.map((e) => e.id).toList(), ['3', '1', '2']);
      },
    );

    test('filterNotes filtre par requête texte, tag et statut épinglé', () {
      final now = DateTime.now();
      final notes = [
        NoteItem(
          id: 'a',
          title: 'Recette pâtes',
          content: 'Tomates et basilic',
          tags: const ['cuisine'],
          isPinned: true,
          createdAt: now,
          updatedAt: now,
        ),
        NoteItem(
          id: 'b',
          title: 'Commandes Git',
          content: 'git status',
          tags: const ['dev'],
          isPinned: false,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      expect(svc.filterNotes(notes, query: 'basilic').map((n) => n.id), ['a']);
      expect(svc.filterNotes(notes, tag: 'dev').map((n) => n.id), ['b']);
      expect(svc.filterNotes(notes, pinnedOnly: true).map((n) => n.id), ['a']);
    });

    test('toggleChecklistLine bascule uniquement la ligne demandée', () {
      const content = '- [ ] Tâche 1\n- [x] Tâche 2\nParagraphe';
      final toggled1 = svc.toggleChecklistLine(content, 0);
      expect(toggled1, '- [x] Tâche 1\n- [x] Tâche 2\nParagraphe');

      final toggled2 = svc.toggleChecklistLine(toggled1, 1);
      expect(toggled2, '- [x] Tâche 1\n- [ ] Tâche 2\nParagraphe');
    });

    test(
      'upsertNote et deleteNote persistent dans SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now();

        final list1 = await svc.upsertNote(
          NoteItem(
            id: 'n1',
            title: 'Test',
            content: 'Contenu',
            tags: const ['tag1'],
            createdAt: now,
            updatedAt: now,
          ),
          preferences: prefs,
        );
        expect(list1, hasLength(1));
        expect(
          json.decode(prefs.getString(NotesService.notesKey)!),
          hasLength(1),
        );

        final list2 = await svc.deleteNote('n1', preferences: prefs);
        expect(list2, isEmpty);
      },
    );
  });
}
