import 'package:flutter/material.dart';

typedef WidgetScreenBuilder = Widget Function(String heroTag);

class ToolItem {
  final String title;
  final IconData icon;
  final WidgetScreenBuilder screenBuilder;
  final String heroTag;
  final bool animates;

  ToolItem({
    required this.title,
    required this.icon,
    required this.screenBuilder,
    required this.heroTag,
    this.animates = true,
  });
}
