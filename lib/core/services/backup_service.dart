import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';
import 'package:toolbox_everything_mobile/core/models/note_item.dart';
import 'package:toolbox_everything_mobile/core/services/notes_service.dart';
import 'package:toolbox_everything_mobile/core/services/qr_history_service.dart';
import 'package:toolbox_everything_mobile/core/services/usage_stats_service.dart';

class BackupImportResult {
  final int notesCount;
  final int favoritesCount;
  final int qrHistoryCount;
  final int timerPresetsCount;
  final int recentColorsCount;

  const BackupImportResult({
    required this.notesCount,
    required this.favoritesCount,
    required this.qrHistoryCount,
    required this.timerPresetsCount,
    required this.recentColorsCount,
  });
}

class BackupService {
  const BackupService();

  static const int currentSchemaVersion = 1;
  static const int _maxRecentColors = 12;

  static const String _prefUseDynamic = 'pref_use_dynamic_color';
  static const String _prefSeedColor = 'pref_seed_color';
  static const String _prefThemeMode = 'pref_theme_mode';
  static const String _prefAmoled = 'pref_amoled_black';
  static const String _prefAdvanced = 'pref_advanced_appearance';

  static const String _prefLockBubble = 'lock_bubble_portrait';
  static const String _prefLowResource = 'low_resource_mode';
  static const String _prefHaptics = 'haptics_enabled';

  static const String _prefDownloaderPreferMp4 = 'downloader_prefer_mp4';
  static const String _prefDownloaderShowMkv = 'downloader_show_mkv';

  static const String _prefPomodoroWork = 'pomodoro_work_min';
  static const String _prefPomodoroShort = 'pomodoro_short_min';
  static const String _prefPomodoroLong = 'pomodoro_long_min';
  static const String _prefPomodoroAutoContinue = 'pomodoro_auto_continue';
  static const String _prefPomodoroCompleted = 'pomodoro_completed_count';

  static const String _keyRecentColors = 'recent_colors';
  static const String _keyTimerCustomPresets = 'timer_custom_presets';
  static const String _keyStopwatchLaps = 'stopwatch_laps_v2';

  final NotesService _notesService = const NotesService();
  final QrHistoryService _qrHistoryService = const QrHistoryService();

  Future<SharedPreferences> _preferences(SharedPreferences? prefs) async =>
      prefs ?? SharedPreferences.getInstance();

  Future<String> createBackupJson({SharedPreferences? preferences}) async {
    final prefs = await _preferences(preferences);
    final notes = await _notesService.loadNotes(preferences: prefs);
    final favorites = await UsageStatsService.loadFavorites(preferences: prefs);
    final usageStats = await UsageStatsService.getUsageStats(
      preferences: prefs,
    );
    final qrHistory = await _qrHistoryService.load(preferences: prefs);
    final timerPresets = prefs.getStringList(_keyTimerCustomPresets) ?? [];
    final recentColors = prefs.getStringList(_keyRecentColors) ?? [];

    dynamic stopwatchLaps = [];
    final rawLaps = prefs.getString(_keyStopwatchLaps);
    if (rawLaps != null && rawLaps.isNotEmpty) {
      try {
        stopwatchLaps = json.decode(rawLaps);
      } catch (_) {}
    }

    final payload = <String, dynamic>{
      'schemaVersion': currentSchemaVersion,
      'appVersion': AppConstants.version,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'notes': notes.map((n) => n.toJson()).toList(),
      'favorites': favorites,
      'usageStats': usageStats,
      'qrHistory': qrHistory.map((e) => e.toJson()).toList(),
      'timerPresets': timerPresets.map(int.tryParse).whereType<int>().toList(),
      'stopwatchLaps': stopwatchLaps,
      'recentColors': recentColors,
      'appearance': {
        _prefThemeMode: prefs.getString(_prefThemeMode),
        _prefUseDynamic: prefs.getBool(_prefUseDynamic),
        _prefSeedColor: prefs.getInt(_prefSeedColor),
        _prefAmoled: prefs.getBool(_prefAmoled),
        _prefAdvanced: prefs.getBool(_prefAdvanced),
      },
      'settings': {
        _prefLockBubble: prefs.getBool(_prefLockBubble),
        _prefLowResource: prefs.getBool(_prefLowResource),
        _prefHaptics: prefs.getBool(_prefHaptics),
      },
      'downloaderPrefs': {
        _prefDownloaderPreferMp4: prefs.getBool(_prefDownloaderPreferMp4),
        _prefDownloaderShowMkv: prefs.getBool(_prefDownloaderShowMkv),
      },
      'pomodoroPrefs': {
        _prefPomodoroWork: prefs.getInt(_prefPomodoroWork),
        _prefPomodoroShort: prefs.getInt(_prefPomodoroShort),
        _prefPomodoroLong: prefs.getInt(_prefPomodoroLong),
        _prefPomodoroAutoContinue: prefs.getBool(_prefPomodoroAutoContinue),
        _prefPomodoroCompleted: prefs.getInt(_prefPomodoroCompleted),
      },
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<BackupImportResult> restoreFromJson(
    String rawJson, {
    required bool merge,
    SharedPreferences? preferences,
  }) async {
    final dynamic decoded;
    try {
      decoded = json.decode(rawJson);
    } catch (e) {
      throw FormatException('Fichier JSON invalide : $e');
    }

    if (decoded is! Map) {
      throw const FormatException('Structure de sauvegarde invalide.');
    }
    final schemaVersion = decoded['schemaVersion'];
    if (schemaVersion is! int || schemaVersion < 1) {
      throw const FormatException(
        'Ce fichier ne correspond pas à une sauvegarde Toolbox Everything.',
      );
    }

    final prefs = await _preferences(preferences);

    // 1. Notes
    final importedNotes = _notesService.decodeNotesList(decoded['notes']);
    final List<NoteItem> finalNotes;
    if (merge) {
      final existingNotes = await _notesService.loadNotes(preferences: prefs);
      final byId = <String, NoteItem>{for (final n in existingNotes) n.id: n};
      for (final note in importedNotes) {
        final prev = byId[note.id];
        if (prev == null || note.updatedAt.isAfter(prev.updatedAt)) {
          byId[note.id] = note;
        }
      }
      finalNotes = _notesService.sortNotes(byId.values.toList());
    } else {
      finalNotes = importedNotes;
    }
    await _notesService.saveNotes(finalNotes, preferences: prefs);

    // 2. Favoris
    final importedFavs =
        (decoded['favorites'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toSet() ??
        <String>{};
    final Set<String> finalFavs = merge
        ? {
            ...await UsageStatsService.loadFavorites(preferences: prefs),
            ...importedFavs,
          }
        : importedFavs;
    await UsageStatsService.saveFavorites(finalFavs, preferences: prefs);

    // 3. Statistiques d'usage
    final importedStats = <String, int>{};
    final rawStats = decoded['usageStats'];
    if (rawStats is Map) {
      for (final entry in rawStats.entries) {
        final val = entry.value;
        if (val is num) {
          importedStats[entry.key.toString()] = val.toInt();
        }
      }
    }
    final Map<String, int> finalStats;
    if (merge) {
      final existingStats = await UsageStatsService.getUsageStats(
        preferences: prefs,
      );
      finalStats = Map<String, int>.from(existingStats);
      for (final entry in importedStats.entries) {
        finalStats[entry.key] = math.max(
          finalStats[entry.key] ?? 0,
          entry.value,
        );
      }
    } else {
      finalStats = importedStats;
    }
    await prefs.setString('tool_usage_stats_v2', json.encode(finalStats));
    await prefs.setBool('tool_preferences_v2_migrated', true);

    // 4. Historique QR
    final importedQr = _qrHistoryService.decodeHistoryList(
      decoded['qrHistory'],
    );
    final List<QrHistoryEntry> finalQr;
    if (merge) {
      final existingQr = await _qrHistoryService.load(preferences: prefs);
      final byKey = <String, QrHistoryEntry>{};
      for (final entry in [...existingQr, ...importedQr]) {
        final key = '${entry.isScanned ? '1' : '0'}:${entry.data}';
        final prev = byKey[key];
        if (prev == null || entry.createdAt.isAfter(prev.createdAt)) {
          byKey[key] = entry;
        }
      }
      final list = byKey.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      finalQr = list.take(QrHistoryService.maxEntries).toList();
    } else {
      finalQr = importedQr.take(QrHistoryService.maxEntries).toList();
    }
    await prefs.setString(
      QrHistoryService.historyKey,
      json.encode(finalQr.map((e) => e.toJson()).toList()),
    );

    // 5. Presets minuteur
    final importedPresets =
        (decoded['timerPresets'] as List?)
            ?.map((e) => e is num ? e.toInt() : int.tryParse(e.toString()))
            .whereType<int>()
            .where((e) => e > 0)
            .toSet() ??
        <int>{};
    final Set<int> finalPresets = merge
        ? {
            ...(prefs.getStringList(_keyTimerCustomPresets) ?? const [])
                .map(int.tryParse)
                .whereType<int>(),
            ...importedPresets,
          }
        : importedPresets;
    final sortedPresets = finalPresets.toList()..sort();
    await prefs.setStringList(
      _keyTimerCustomPresets,
      sortedPresets.map((e) => e.toString()).toList(),
    );

    // 6. Tours chronomètre
    final rawBackupLaps = decoded['stopwatchLaps'];
    if (rawBackupLaps is List) {
      if (!merge) {
        await prefs.setString(_keyStopwatchLaps, json.encode(rawBackupLaps));
      } else if (rawBackupLaps.isNotEmpty) {
        final localLaps = prefs.getString(_keyStopwatchLaps)?.trim();
        if (localLaps == null || localLaps.isEmpty || localLaps == '[]') {
          await prefs.setString(_keyStopwatchLaps, json.encode(rawBackupLaps));
        }
      }
    } else if (!merge) {
      await prefs.remove(_keyStopwatchLaps);
    }

    // 7. Couleurs récentes
    final importedColors =
        (decoded['recentColors'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        <String>[];
    final List<String> finalColors;
    if (merge) {
      final existingColors = prefs.getStringList(_keyRecentColors) ?? const [];
      final seen = <String>{};
      final merged = <String>[];
      for (final hex in [...importedColors, ...existingColors]) {
        if (seen.add(hex)) merged.add(hex);
      }
      finalColors = merged.take(_maxRecentColors).toList();
    } else {
      finalColors = importedColors.take(_maxRecentColors).toList();
    }
    await prefs.setStringList(_keyRecentColors, finalColors);

    // 8. Apparence, réglages et préférences téléchargeur
    await _applyMapPrefs(
      prefs,
      decoded['appearance'],
      overwriteMissing: !merge,
      keys: const [
        _prefThemeMode,
        _prefUseDynamic,
        _prefSeedColor,
        _prefAmoled,
        _prefAdvanced,
      ],
    );
    await _applyMapPrefs(
      prefs,
      decoded['settings'],
      overwriteMissing: !merge,
      keys: const [_prefLockBubble, _prefLowResource, _prefHaptics],
    );
    await _applyMapPrefs(
      prefs,
      decoded['downloaderPrefs'],
      overwriteMissing: !merge,
      keys: const [_prefDownloaderPreferMp4, _prefDownloaderShowMkv],
    );
    await _applyMapPrefs(
      prefs,
      decoded['pomodoroPrefs'],
      overwriteMissing: !merge,
      keys: const [
        _prefPomodoroWork,
        _prefPomodoroShort,
        _prefPomodoroLong,
        _prefPomodoroAutoContinue,
        _prefPomodoroCompleted,
      ],
    );

    return BackupImportResult(
      notesCount: finalNotes.length,
      favoritesCount: finalFavs.length,
      qrHistoryCount: finalQr.length,
      timerPresetsCount: sortedPresets.length,
      recentColorsCount: finalColors.length,
    );
  }

  Future<void> _applyMapPrefs(
    SharedPreferences prefs,
    dynamic section, {
    required bool overwriteMissing,
    required List<String> keys,
  }) async {
    final map = section is Map ? section : const {};
    for (final key in keys) {
      final val = map[key];
      if (val is bool) {
        await prefs.setBool(key, val);
      } else if (val is int) {
        await prefs.setInt(key, val);
      } else if (val is String) {
        await prefs.setString(key, val);
      } else if (overwriteMissing) {
        await prefs.remove(key);
      }
    }
  }
}
