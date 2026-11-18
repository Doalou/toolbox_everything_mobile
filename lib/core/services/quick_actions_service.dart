import 'dart:io';

import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/feature_flags/app_feature_flags.dart';
import 'package:toolbox_everything_mobile/core/models/tool_item.dart';
import 'package:toolbox_everything_mobile/core/services/usage_stats_service.dart';
import 'package:toolbox_everything_mobile/core/tool_catalog.dart';
import 'package:toolbox_everything_mobile/presentation/navigation/unified_navigation.dart';
import 'package:toolbox_everything_mobile/presentation/screens/downloader_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/qr_code_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/unit_converter_screen.dart';

class QuickActionsService {
  QuickActionsService._();
  static final QuickActionsService instance = QuickActionsService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const List<String> _fallbackToolIds = [
    'qr-code',
    'youtube-downloader',
    'unit-converter',
    'notes',
  ];

  final QuickActions _qa = const QuickActions();
  String? _pendingAction;

  Future<void> initialize() async {
    if (!AppFeatureFlags.quickActions) return;

    await _qa.initialize(_handleAction);
    await refreshShortcuts();
  }

  /// Sélectionne jusqu'à [maxCount] outils : favoris > les plus utilisés > défauts.
  Future<List<ToolItem>> selectDynamicTools({
    SharedPreferences? preferences,
    int maxCount = 4,
  }) async {
    final allTools = ToolCatalog.all();
    final byId = {for (final tool in allTools) tool.id: tool};
    final selected = <ToolItem>[];
    final seen = <String>{};

    void tryAdd(String id) {
      if (selected.length >= maxCount || seen.contains(id)) return;
      final tool = byId[id];
      if (tool == null) return;
      seen.add(id);
      selected.add(tool);
    }

    final favoriteIds = (await UsageStatsService.loadFavorites(
      preferences: preferences,
    )).toSet();
    for (final tool in allTools) {
      if (favoriteIds.contains(tool.id)) {
        tryAdd(tool.id);
      }
    }

    final mostUsed = await UsageStatsService.getMostUsedTools(
      limit: 8,
      preferences: preferences,
    );
    for (final id in mostUsed) {
      tryAdd(id);
    }

    for (final id in _fallbackToolIds) {
      tryAdd(id);
    }

    for (final tool in allTools) {
      tryAdd(tool.id);
    }

    return selected;
  }

  String? _shortcutIconForTool(String toolId) {
    if (!Platform.isAndroid) return null;
    return switch (toolId) {
      'qr-code' => 'ic_shortcut_qr',
      'youtube-downloader' => 'ic_shortcut_download',
      'unit-converter' ||
      'number-converter' ||
      'file-converter' => 'ic_shortcut_convert',
      _ => 'ic_notification',
    };
  }

  /// Met à jour les raccourcis système à partir des favoris et statistiques.
  Future<void> refreshShortcuts({SharedPreferences? preferences}) async {
    if (!AppFeatureFlags.quickActions) return;
    try {
      final tools = await selectDynamicTools(preferences: preferences);
      final items = tools
          .map(
            (tool) => ShortcutItem(
              type: 'tool:${tool.id}',
              localizedTitle: tool.title,
              icon: _shortcutIconForTool(tool.id),
            ),
          )
          .toList();
      await _qa.setShortcutItems(items);
    } catch (_) {
      // Silencieux hors Android/iOS ou en test unitaire.
    }
  }

  /// Vérifie et exécute une action en attente une fois l'interface prête.
  void processPendingAction() {
    if (_pendingAction != null) {
      _handleAction(_pendingAction!);
      _pendingAction = null;
    }
  }

  void _handleAction(String type) {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      _pendingAction = type;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentNav = navigatorKey.currentState;
      if (currentNav == null) {
        _pendingAction = type;
        return;
      }

      if (type.startsWith('tool:')) {
        final id = type.substring(5);
        final tool = ToolCatalog.all().firstWhereOrNull((t) => t.id == id);
        if (tool != null) {
          currentNav.push(
            unifiedNavigation(
              currentNav.context,
              tool.screenBuilder('quick_action_${tool.id}'),
            ),
          );
        }
        return;
      }

      switch (type) {
        case 'action_qr':
          currentNav.push(
            unifiedNavigation(
              currentNav.context,
              const QrCodeScreen(heroTag: 'quick_action_qr'),
            ),
          );
        case 'action_downloader':
          if (!AppFeatureFlags.youtubeDownloader) break;
          currentNav.push(
            unifiedNavigation(
              currentNav.context,
              const DownloaderScreen(heroTag: 'quick_action_downloader'),
            ),
          );
        case 'action_convert':
          currentNav.push(
            unifiedNavigation(
              currentNav.context,
              const UnitConverterScreen(heroTag: 'quick_action_converter'),
            ),
          );
      }
    });
  }
}
