import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UsageStatsService {
  static const String _legacyUsageKey = 'tool_usage_stats';
  static const String _legacyFavoritesKey = 'favorite_tools';
  static const String _usageKey = 'tool_usage_stats_v2';
  static const String _favoritesKey = 'favorite_tool_ids';
  static const String _migrationKey = 'tool_preferences_v2_migrated';

  static Future<SharedPreferences> _preferences(
    SharedPreferences? preferences,
  ) async => preferences ?? SharedPreferences.getInstance();

  static Map<String, int> _decodeStats(String? source) {
    if (source == null || source.isEmpty) return <String, int>{};
    try {
      final decoded = json.decode(source);
      if (decoded is! Map) return <String, int>{};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      );
    } catch (_) {
      return <String, int>{};
    }
  }

  static Future<void> migrateLegacyData(
    Map<String, String> legacyTitleToId, {
    SharedPreferences? preferences,
  }) async {
    final prefs = await _preferences(preferences);
    if (prefs.getBool(_migrationKey) ?? false) return;

    final migratedStats = _decodeStats(prefs.getString(_usageKey));
    final legacyStats = _decodeStats(prefs.getString(_legacyUsageKey));
    for (final entry in legacyStats.entries) {
      final id = legacyTitleToId[entry.key];
      if (id != null) migratedStats.putIfAbsent(id, () => entry.value);
    }

    final favorites = <String>{...?prefs.getStringList(_favoritesKey)};
    for (final title in prefs.getStringList(_legacyFavoritesKey) ?? const []) {
      final id = legacyTitleToId[title];
      if (id != null) favorites.add(id);
    }

    await prefs.setString(_usageKey, json.encode(migratedStats));
    await prefs.setStringList(_favoritesKey, favorites.toList()..sort());
    await prefs.setBool(_migrationKey, true);
  }

  static Future<void> recordToolUsage(
    String toolId, {
    SharedPreferences? preferences,
  }) async {
    final prefs = await _preferences(preferences);
    final stats = _decodeStats(prefs.getString(_usageKey));
    stats.update(toolId, (count) => count + 1, ifAbsent: () => 1);
    await prefs.setString(_usageKey, json.encode(stats));
  }

  static Future<Map<String, int>> getUsageStats({
    SharedPreferences? preferences,
  }) async {
    final prefs = await _preferences(preferences);
    return _decodeStats(prefs.getString(_usageKey));
  }

  // Obtenir les outils les plus utilisés
  static Future<List<String>> getMostUsedTools({
    int limit = 5,
    SharedPreferences? preferences,
  }) async {
    final stats = await getUsageStats(preferences: preferences);
    final sortedEntries = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(limit).map((e) => e.key).toList();
  }

  // Sauvegarder les favoris
  static Future<void> saveFavorites(
    Iterable<String> favoriteToolIds, {
    SharedPreferences? preferences,
  }) async {
    final prefs = await _preferences(preferences);
    await prefs.setStringList(
      _favoritesKey,
      favoriteToolIds.toSet().toList()..sort(),
    );
  }

  // Charger les favoris
  static Future<List<String>> loadFavorites({
    SharedPreferences? preferences,
  }) async {
    final prefs = await _preferences(preferences);
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  // Obtenir le nombre total d'utilisations
  static Future<int> getTotalUsage({SharedPreferences? preferences}) async {
    final stats = await getUsageStats(preferences: preferences);
    return stats.values.fold<int>(0, (sum, count) => sum + count);
  }

  // Réinitialiser les statistiques
  static Future<void> resetStats({SharedPreferences? preferences}) async {
    final prefs = await _preferences(preferences);
    await prefs.remove(_usageKey);
  }
}
