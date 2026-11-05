import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/services/haptics_service.dart';

enum FeedbackTone { normal, success, warning, error }

/// Service unifié de retour utilisateur (SnackBar flottant Material 3 Expressive
/// + retour haptique respectant les préférences de l'application).
class AppFeedback {
  AppFeedback._();

  static void show(
    BuildContext context,
    String message, {
    FeedbackTone tone = FeedbackTone.normal,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;

    switch (tone) {
      case FeedbackTone.success:
      case FeedbackTone.normal:
        HapticsService.perform(context, HapticType.light);
      case FeedbackTone.warning:
        HapticsService.perform(context, HapticType.medium);
      case FeedbackTone.error:
        HapticsService.perform(context, HapticType.heavy);
    }

    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg, IconData defaultIcon) = switch (tone) {
      FeedbackTone.success => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.check_circle_rounded,
      ),
      FeedbackTone.warning => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.warning_amber_rounded,
      ),
      FeedbackTone.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline_rounded,
      ),
      FeedbackTone.normal => (
        scheme.inverseSurface,
        scheme.onInverseSurface,
        Icons.info_outline_rounded,
      ),
    };

    final resolvedIcon = icon ?? defaultIcon;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(resolvedIcon, color: fg, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  static void copied(
    BuildContext context, [
    String label = 'Copié dans le presse-papiers',
  ]) {
    show(
      context,
      label,
      tone: FeedbackTone.success,
      icon: Icons.content_copy_rounded,
      duration: const Duration(milliseconds: 1600),
    );
  }
}
