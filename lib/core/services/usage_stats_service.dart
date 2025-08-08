import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UsageStatsService {
  static const String _usageKey = 'tool_usage_stats';
  static const String _favoritesKey = 'favorite_tools';

  // Enregistrer l'utilisation d'un outil
  static Future<void> recordToolUsage(String toolName) async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_usageKey) ?? '{}';
    final stats = Map<String, dynamic>.from(json.decode(statsJson));

    if (stats.containsKey(toolName)) {
      stats[toolName] = (stats[toolName] as int) + 1;
    } else {
      stats[toolName] = 1;
    }

    await prefs.setString(_usageKey, json.encode(stats));
  }

  // Obtenir les statistiques d'utilisation
  static Future<Map<String, int>> getUsageStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_usageKey) ?? '{}';
    final stats = Map<String, dynamic>.from(json.decode(statsJson));

    return Map<String, int>.from(stats);
  }

  // Obtenir les outils les plus utilisés
  static Future<List<String>> getMostUsedTools({int limit = 5}) async {
    final stats = await getUsageStats();
    final sortedEntries = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(limit).map((e) => e.key).toList();
  }

  // Sauvegarder les favoris
  static Future<void> saveFavorites(List<String> favoriteTools) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, favoriteTools);
  }

  // Charger les favoris
  static Future<List<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  // Obtenir le nombre total d'utilisations
  static Future<int> getTotalUsage() async {
    final stats = await getUsageStats();
    return stats.values.fold<int>(0, (sum, count) => sum + count);
  }

  // Réinitialiser les statistiques
  static Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usageKey);
  }
}
