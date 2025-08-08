import 'package:flutter/material.dart';

enum ToolCategory {
  security,
  conversion,
  productivity,
  media,
  utilities,
  mobile,
}

class ToolItem {
  final String title;
  final IconData icon;
  final Widget Function() screenBuilder;
  final ToolCategory category;
  bool isFavorite;

  ToolItem({
    required this.title,
    required this.icon,
    required this.screenBuilder,
    required this.category,
    this.isFavorite = false,
  });

  void toggleFavorite() {
    isFavorite = !isFavorite;
  }

  String get categoryName {
    switch (category) {
      case ToolCategory.security:
        return 'Sécurité';
      case ToolCategory.conversion:
        return 'Conversion';
      case ToolCategory.productivity:
        return 'Productivité';
      case ToolCategory.media:
        return 'Média';
      case ToolCategory.utilities:
        return 'Utilitaires';
      case ToolCategory.mobile:
        return 'Mobile';
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case ToolCategory.security:
        return Icons.security;
      case ToolCategory.conversion:
        return Icons.transform;
      case ToolCategory.productivity:
        return Icons.work;
      case ToolCategory.media:
        return Icons.media_bluetooth_on;
      case ToolCategory.utilities:
        return Icons.build;
      case ToolCategory.mobile:
        return Icons.phone_android;
    }
  }
}
