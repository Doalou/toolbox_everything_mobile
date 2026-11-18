// Pont transitoire minimal pour les paquets tiers non encore migrés vers
// package:material_ui (ex: flutter_colorpicker dont TextField et
// DropdownButton exigent un ancêtre legacy Material).
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/widgets.dart';

/// Fournit un ancêtre `Material` transparent de l'ancien SDK Flutter aux widgets
/// tiers qui importent encore `package:flutter/material.dart`.
class LegacyMaterialScope extends StatelessWidget {
  final Widget child;

  const LegacyMaterialScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return legacy.Material(
      type: legacy.MaterialType.transparency,
      child: child,
    );
  }
}
