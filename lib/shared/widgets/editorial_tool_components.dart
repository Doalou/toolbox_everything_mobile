import 'package:material_ui/material_ui.dart';
import 'package:toolbox_everything_mobile/core/design/editorial_tokens.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';

/// En-tête hero Material 3 Expressive placé en haut des écrans d'outils.
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
    final accentScheme = EditorialPalette.expressiveSeedScheme(
      resolvedAccent,
      scheme.brightness,
    );

    return ExpressiveCard.hero(
      color: accentScheme.primaryContainer.withValues(
        alpha: scheme.brightness == Brightness.dark ? 0.52 : 0.72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentScheme.primary.withValues(alpha: 0.18),
              borderRadius: ExpressiveShapes.asymmetricHero(
                major: 15,
                minor: 8,
              ),
            ),
            child: Icon(icon, color: accentScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: accentScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: accentScheme.onPrimaryContainer.withValues(
                      alpha: 0.82,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}
