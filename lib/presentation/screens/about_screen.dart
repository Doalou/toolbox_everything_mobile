import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(BuildContext context, Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showOpenError(context, uri);
      }
    } catch (_) {
      if (context.mounted) _showOpenError(context, uri);
    }
  }

  void _showOpenError(BuildContext context, Uri uri) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Impossible d\'ouvrir : $uri'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            pinned: true,
            elevation: 0,
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            title: const Text('À propos'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList.list(
              children: [
                _AppIdentityCard(scheme: scheme),
                const SizedBox(height: 18),
                const _SectionLabel(label: 'Application'),
                const SizedBox(height: 8),
                _PurposeCard(scheme: scheme),
                const SizedBox(height: 14),
                _PrivacyCard(scheme: scheme),
                const SizedBox(height: 18),
                const _SectionLabel(label: 'Ressources'),
                const SizedBox(height: 8),
                _ResourceCard(
                  onPrivacy: () => _launchUrl(
                    context,
                    Uri.parse(AppConstants.privacyPolicyUrl),
                  ),
                  onSource: () => _launchUrl(
                    context,
                    Uri.parse(AppConstants.sourceCodeUrl),
                  ),
                ),
                const SizedBox(height: 14),
                _ContactCard(
                  onSuggest: () => _launchUrl(context, _suggestionUri()),
                  onBug: () => _launchUrl(context, _bugReportUri()),
                  onContact: () => _launchUrl(context, _contactUri()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Uri _suggestionUri() {
    const subject = 'Suggestion d’outil pour Toolbox Everything';
    const body =
        '''
Bonjour,

J’aimerais proposer un nouvel outil pour Toolbox Everything :

Nom de l’outil :
Description :
Cas d’usage :
Détails utiles ou exemple :

Version de l’application : ${AppConstants.version}

Merci !
''';
    return Uri(
      scheme: 'mailto',
      path: AppConstants.contactEmail,
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
  }

  Uri _contactUri() {
    return Uri(
      scheme: 'mailto',
      path: AppConstants.contactEmail,
      query: 'subject=${Uri.encodeComponent('Contact | Toolbox Everything')}',
    );
  }

  Uri _bugReportUri() {
    const subject = 'Bug dans Toolbox Everything';
    const body =
        '''
Bonjour,

J’aimerais signaler un bug dans Toolbox Everything :

Outil concerné :
Étapes pour reproduire :
Résultat attendu :
Résultat obtenu :
Modèle d’appareil / version Android :

Version de l’application : ${AppConstants.version}

Merci !
''';
    return Uri(
      scheme: 'mailto',
      path: AppConstants.contactEmail,
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
  }
}

class _AppIdentityCard extends StatelessWidget {
  final ColorScheme scheme;

  const _AppIdentityCard({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return ExpressiveCard.hero(
      color: scheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBubble(
                icon: Icons.verified_rounded,
                foreground: scheme.onPrimaryContainer,
                background: scheme.onPrimaryContainer.withValues(alpha: 0.12),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toolbox Everything ${AppConstants.version}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Une boîte à outils mobile pensée pour les petites tâches du quotidien : rapide à ouvrir, simple à comprendre, utile même hors ligne.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(
                          alpha: 0.82,
                        ),
                        height: 1.48,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PurposeCard extends StatelessWidget {
  final ColorScheme scheme;

  const _PurposeCard({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            icon: Icons.widgets_rounded,
            title: 'Une collection d’outils essentiels',
            color: scheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'L’application regroupe des convertisseurs, générateurs, encodeurs et utilitaires de diagnostic dans une interface unique. Les actions courantes restent directes : entrer une donnée, obtenir un résultat, copier ou exporter.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.52,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  final ColorScheme scheme;

  const _PrivacyCard({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return ExpressiveCard(
      color: scheme.secondaryContainer.withValues(alpha: 0.7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBubble(
            icon: Icons.security_rounded,
            foreground: scheme.onSecondaryContainer,
            background: scheme.onSecondaryContainer.withValues(alpha: 0.12),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Priorité aux données locales',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Les outils sont conçus pour limiter les dépendances externes. Quand une fonctionnalité ouvre un lien ou un service du système, l’action reste explicite.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSecondaryContainer.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final VoidCallback onPrivacy;
  final VoidCallback onSource;

  const _ResourceCard({required this.onPrivacy, required this.onSource});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ExpressiveCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _ResourceTile(
            icon: Icons.shield_outlined,
            title: 'Confidentialité',
            subtitle: 'Consulter la politique de confidentialité',
            onTap: onPrivacy,
          ),
          Divider(
            height: 1,
            indent: 72,
            endIndent: 18,
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
          _ResourceTile(
            icon: Icons.code_rounded,
            title: 'Code source',
            subtitle: 'Ouvrir le dépôt GitHub',
            onTap: onSource,
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final VoidCallback onSuggest;
  final VoidCallback onBug;
  final VoidCallback onContact;

  const _ContactCard({
    required this.onSuggest,
    required this.onBug,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ExpressiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            icon: Icons.forum_outlined,
            title: 'Contact et retours',
            color: scheme.tertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'Une idée d’outil, un bug ou une amélioration ? Les retours peuvent partir directement par e-mail.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onSuggest,
            icon: const Icon(Icons.lightbulb_outline_rounded),
            label: const Text('Suggérer un outil'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onBug,
                icon: const Icon(Icons.bug_report_outlined),
                label: const Text('Signaler un bug'),
              ),
              OutlinedButton.icon(
                onPressed: onContact,
                icon: const Icon(Icons.mail_outline_rounded),
                label: const Text('Contact'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ResourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      leading: _IconBubble(
        icon: icon,
        foreground: scheme.primary,
        background: scheme.primary.withValues(alpha: 0.12),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new_rounded),
      onTap: onTap,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CardHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _CardHeading({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBubble(
          icon: icon,
          foreground: color,
          background: color.withValues(alpha: 0.12),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color foreground;
  final Color background;

  const _IconBubble({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: ShapeDecoration(
        color: background,
        shape: const StadiumBorder(),
      ),
      child: Icon(icon, color: foreground, size: 21),
    );
  }
}
