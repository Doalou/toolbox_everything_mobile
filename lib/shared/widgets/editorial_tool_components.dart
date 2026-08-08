import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';

/// Introduction compacte et cohérente placée au début de chaque outil.
class EditorialToolIntro extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? accent;
  final Widget? trailing;

  const EditorialToolIntro({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.accent,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedAccent = accent ?? scheme.primary;

    return ExpressiveCard(
      dense: true,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: resolvedAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: resolvedAccent.withValues(alpha: 0.24)),
            ),
            child: Icon(icon, color: resolvedAccent, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}
