import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';

enum HapticType { light, medium, heavy, selection }

class HapticsService {
  static Future<void> perform(BuildContext context, HapticType type) async {
    final enabled = context.read<SettingsProvider>().hapticsEnabled;
    if (!enabled) return;
    switch (type) {
      case HapticType.light:
        await HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        await HapticFeedback.mediumImpact();
        break;
      case HapticType.heavy:
        await HapticFeedback.heavyImpact();
        break;
      case HapticType.selection:
        await HapticFeedback.selectionClick();
        break;
    }
  }
}
