import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/models/note_item.dart';
import 'package:toolbox_everything_mobile/core/services/backup_service.dart';
import 'package:toolbox_everything_mobile/core/services/notes_service.dart';
import 'package:toolbox_everything_mobile/core/services/qr_history_service.dart';
import 'package:toolbox_everything_mobile/core/services/quick_actions_service.dart';
import 'package:toolbox_everything_mobile/core/services/usage_stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupService & QuickActionsService', () {
    const backupService = BackupService();
    const notesService = NotesService();
    const qrService = QrHistoryService();

    test('exporte un JSON complet puis restaure en mode remplacer', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.utc(2026, 11, 18, 10, 0);

      await notesService.upsertNote(
        NoteItem(
          id: 'n1',
          title: 'Note A',
          content: 'Contenu A',
          tags: const ['perso'],
          isPinned: true,
          createdAt: now,
          updatedAt: now,
        ),
        preferences: prefs,
      );
      await UsageStatsService.saveFavorites([
        'notes',
        'qr-code',
      ], preferences: prefs);
      await UsageStatsService.recordToolUsage('qr-code', preferences: prefs);
      await qrService.add(
        'https://toolbox.doalo.fr',
        isScanned: false,
        preferences: prefs,
      );
      await prefs.setStringList('timer_custom_presets', ['420']);
      await prefs.setStringList('recent_colors', ['ff2544d8']);
      await prefs.setBool('low_resource_mode', true);
      await prefs.setString('pref_theme_mode', 'dark');
      await prefs.setInt('pomodoro_work_min', 30);
      await prefs.setBool('pomodoro_auto_continue', true);
      await prefs.setString(
        'stopwatch_laps_v2',
        json.encode([
          {'index': 1, 'totalMs': 12340, 'lapMs': 12340},
        ]),
      );

      final rawBackup = await backupService.createBackupJson(
        preferences: prefs,
      );
      final parsed = json.decode(rawBackup) as Map<String, dynamic>;
      expect(parsed['schemaVersion'], BackupService.currentSchemaVersion);
      expect((parsed['notes'] as List), hasLength(1));
      expect(parsed['favorites'], containsAll(['notes', 'qr-code']));
      expect((parsed['pomodoroPrefs'] as Map)['pomodoro_work_min'], 30);

      // Réinitialisation simulée sur un nouvel appareil
      SharedPreferences.setMockInitialValues({});
      final freshPrefs = await SharedPreferences.getInstance();
      final result = await backupService.restoreFromJson(
        rawBackup,
        merge: false,
        preferences: freshPrefs,
      );

      expect(result.notesCount, 1);
      expect(result.favoritesCount, 2);
      expect(result.qrHistoryCount, 1);
      expect(result.timerPresetsCount, 1);
      expect(result.recentColorsCount, 1);
      expect(freshPrefs.getBool('low_resource_mode'), isTrue);
      expect(freshPrefs.getString('pref_theme_mode'), 'dark');
      expect(freshPrefs.getInt('pomodoro_work_min'), 30);
      expect(freshPrefs.getBool('pomodoro_auto_continue'), isTrue);
      expect(freshPrefs.getString('stopwatch_laps_v2'), isNotEmpty);
      final restoredNotes = await notesService.loadNotes(
        preferences: freshPrefs,
      );
      expect(restoredNotes.first.title, 'Note A');
    });

    test(
      'fusionne deux jeux de données en gardant la note la plus récente',
      () async {
        final tOld = DateTime.utc(2026, 11, 17, 10, 0);
        final tNew = DateTime.utc(2026, 11, 18, 12, 0);

        final backupPayload = json.encode({
          'schemaVersion': 1,
          'notes': [
            NoteItem(
              id: 'shared-id',
              title: 'Ancienne version',
              content: 'old',
              createdAt: tOld,
              updatedAt: tOld,
            ).toJson(),
            NoteItem(
              id: 'from-backup',
              title: 'Nouvelle note backup',
              content: 'new',
              createdAt: tNew,
              updatedAt: tNew,
            ).toJson(),
          ],
          'favorites': ['hash-calculator'],
          'usageStats': {'hash-calculator': 5},
          'qrHistory': [],
          'timerPresets': [120],
          'stopwatchLaps': [
            {'index': 1, 'totalMs': 5000, 'lapMs': 5000},
          ],
          'recentColors': ['ff0f9d70'],
          'pomodoroPrefs': {'pomodoro_work_min': 35},
        });

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await notesService.upsertNote(
          NoteItem(
            id: 'shared-id',
            title: 'Version locale récente',
            content: 'fresh',
            createdAt: tOld,
            updatedAt: tNew,
          ),
          preferences: prefs,
        );
        await UsageStatsService.saveFavorites(['notes'], preferences: prefs);

        final result = await backupService.restoreFromJson(
          backupPayload,
          merge: true,
          preferences: prefs,
        );

        expect(result.notesCount, 2);
        expect(result.favoritesCount, 2);
        expect(prefs.getInt('pomodoro_work_min'), 35);
        expect(
          json.decode(prefs.getString('stopwatch_laps_v2')!),
          hasLength(1),
        );
        final mergedNotes = await notesService.loadNotes(preferences: prefs);
        expect(
          mergedNotes.firstWhere((n) => n.id == 'shared-id').title,
          'Version locale récente',
        );
        expect(
          await UsageStatsService.loadFavorites(preferences: prefs),
          containsAll(['notes', 'hash-calculator']),
        );
      },
    );

    test('rejette un JSON invalide ou sans schemaVersion', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await expectLater(
        backupService.restoreFromJson(
          '{not json',
          merge: false,
          preferences: prefs,
        ),
        throwsFormatException,
      );
      await expectLater(
        backupService.restoreFromJson(
          '{"notes":[]}',
          merge: false,
          preferences: prefs,
        ),
        throwsFormatException,
      );
    });

    test(
      'QuickActionsService priorise favoris puis les plus utilisés',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await UsageStatsService.saveFavorites([
          'notes',
          'hash-calculator',
        ], preferences: prefs);
        await UsageStatsService.recordToolUsage(
          'uuid-generator',
          preferences: prefs,
        );
        await UsageStatsService.recordToolUsage(
          'uuid-generator',
          preferences: prefs,
        );

        final selected = await QuickActionsService.instance.selectDynamicTools(
          preferences: prefs,
        );

        expect(selected, hasLength(4));
        final ids = selected.map((t) => t.id).toList();
        expect(
          ids,
          containsAll(['hash-calculator', 'notes', 'uuid-generator']),
        );
        // Les favoris doivent passer avant le simple "souvent utilisé"
        expect(
          ids.indexOf('hash-calculator'),
          lessThan(ids.indexOf('uuid-generator')),
        );
        expect(ids.indexOf('notes'), lessThan(ids.indexOf('uuid-generator')));
      },
    );
  });
}
