import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';

typedef WidgetScreenBuilder = Widget Function(String heroTag);

class ToolItem {
  final String title;
  final IconData icon;
  final WidgetScreenBuilder screenBuilder;
  final String heroTag;
  final bool animates;
  final Color cardColor;
  bool isFavorite;

  ToolItem({
    required this.title,
    required this.icon,
    required this.screenBuilder,
    required this.heroTag,
    this.animates = true,
    this.isFavorite = false,
  }) : cardColor = AppConstants.expressiveColors.getColorByText(title);

  void toggleFavorite() {
    isFavorite = !isFavorite;
  }
}
