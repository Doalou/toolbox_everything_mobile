import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';

enum BadgeTone { neutral, info, success, warning, danger, accent }

/// Badge compact à coins ronds, style M3 Expressive (pill).
class StatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final BadgeTone tone;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = BadgeTone.neutral,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  /// Pré-réglages courants.
  factory StatusBadge.local() => const StatusBadge(
    label: 'Local',
    icon: Icons.smartphone,
    tone: BadgeTone.success,
  );

  factory StatusBadge.offline() => const StatusBadge(
    label: 'Offline',
    icon: Icons.cloud_off,
    tone: BadgeTone.info,
  );

  factory StatusBadge.beta() => const StatusBadge(
    label: 'Bêta',
    icon: Icons.science,
    tone: BadgeTone.warning,
  );

  factory StatusBadge.upcoming() => const StatusBadge(
    label: 'À venir',
    icon: Icons.schedule,
    tone: BadgeTone.neutral,
  );

  factory StatusBadge.permission() => const StatusBadge(
    label: 'Permission requise',
    icon: Icons.lock_outline,
    tone: BadgeTone.warning,
  );

  factory StatusBadge.android() => const StatusBadge(
    label: 'Android',
    icon: Icons.android,
    tone: BadgeTone.info,
  );

  factory StatusBadge.ios() =>
      const StatusBadge(label: 'iOS', icon: Icons.apple, tone: BadgeTone.info);

  ({Color bg, Color fg}) _palette(ColorScheme c) {
    switch (tone) {
      case BadgeTone.neutral:
        return (bg: c.surfaceContainerHigh, fg: c.onSurface);
      case BadgeTone.info:
        return (bg: c.secondaryContainer, fg: c.onSecondaryContainer);
      case BadgeTone.success:
        return (bg: c.tertiaryContainer, fg: c.onTertiaryContainer);
      case BadgeTone.warning:
        return (
          bg: c.errorContainer.withValues(alpha: 0.7),
          fg: c.onErrorContainer,
        );
      case BadgeTone.danger:
        return (bg: c.errorContainer, fg: c.onErrorContainer);
      case BadgeTone.accent:
        return (bg: c.primaryContainer, fg: c.onPrimaryContainer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = _palette(scheme);
    return Container(
      padding: padding,
      decoration: ShapeDecoration(color: p.bg, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: p.fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: p.fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau de statut large (pour les cartes ou en-têtes de section).
class StatusBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final BadgeTone tone;

  const StatusBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.tone = BadgeTone.info,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color bg, fg;
    switch (tone) {
      case BadgeTone.success:
        bg = scheme.tertiaryContainer;
        fg = scheme.onTertiaryContainer;
        break;
      case BadgeTone.warning:
      case BadgeTone.danger:
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
        break;
      case BadgeTone.accent:
        bg = scheme.primaryContainer;
        fg = scheme.onPrimaryContainer;
        break;
      case BadgeTone.info:
      case BadgeTone.neutral:
        bg = scheme.secondaryContainer;
        fg = scheme.onSecondaryContainer;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(ExpressiveTokens.spacing),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ExpressiveTokens.spacing),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: ExpressiveTokens.spacingMd),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
