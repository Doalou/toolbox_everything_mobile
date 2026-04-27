import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';

typedef WidgetScreenBuilder = Widget Function(String heroTag);

/// Catégorie d'outil (regroupement dans le dashboard).
enum ToolCategory {
  sensors,
  converters,
  essentials,
  media,
  network,
  productivity,
}

extension ToolCategoryX on ToolCategory {
  String get label {
    switch (this) {
      case ToolCategory.sensors:
        return 'Capteurs';
      case ToolCategory.converters:
        return 'Convertisseurs';
      case ToolCategory.essentials:
        return 'Essentiels';
      case ToolCategory.media:
        return 'Média';
      case ToolCategory.network:
        return 'Réseau';
      case ToolCategory.productivity:
        return 'Productivité';
    }
  }

  IconData get icon {
    switch (this) {
      case ToolCategory.sensors:
        return Icons.sensors_rounded;
      case ToolCategory.converters:
        return Icons.swap_calls_rounded;
      case ToolCategory.essentials:
        return Icons.star_rounded;
      case ToolCategory.media:
        return Icons.movie_rounded;
      case ToolCategory.network:
        return Icons.wifi_rounded;
      case ToolCategory.productivity:
        return Icons.task_alt_rounded;
    }
  }
}

class ToolItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final WidgetScreenBuilder screenBuilder;
  final String heroTag;
  final bool animates;
  final Color cardColor;
  final ToolCategory category;

  /// Liste libre de tags affichés dans la carte (« Local », « Offline », « Bêta »…).
  final List<String> tags;

  bool isFavorite;

  ToolItem({
    required this.title,
    required this.icon,
    required this.screenBuilder,
    required this.heroTag,
    this.subtitle,
    this.category = ToolCategory.essentials,
    this.tags = const [],
    this.animates = true,
    this.isFavorite = false,
  }) : cardColor = AppConstants.expressiveColors.getColorByText(title);

  void toggleFavorite() {
    isFavorite = !isFavorite;
  }
}
