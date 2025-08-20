import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir l\'URL : $url'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('À propos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: AppConstants.semanticBackButton,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        children: [
          // En-tête
          _buildHeader(context, colorScheme, textTheme),
          const SizedBox(height: AppConstants.largePadding * 1.5),

          // Description
          _buildDescriptionCard(context, colorScheme, textTheme),
          const SizedBox(height: AppConstants.largePadding),

          // Liens utiles
          _buildLinksCard(context, colorScheme, textTheme),
          const SizedBox(height: AppConstants.largePadding),

          // Actions
          _buildActions(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.6),
              ],
              center: Alignment.bottomRight,
              radius: 1.5,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.build_circle,
            size: AppConstants.extraLargeIconSize,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppConstants.largePadding),
        Text(
          AppConstants.appName,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Chip(
          label: Text(
            'Version ${AppConstants.version}',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: colorScheme.secondaryContainer,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre boîte à outils numérique',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Une collection d\'outils pratiques pour développeurs, étudiants et passionnés de technologie. Entièrement offline, gratuit et sécurisé.',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinksCard(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
      ),
      child: Column(
        children: [
          _buildLinkTile(
            context,
            icon: Icons.shield_outlined,
            title: 'Politique de confidentialité',
            onTap: () => _launchUrl(context, AppConstants.privacyPolicyUrl),
          ),
          _buildDivider(colorScheme),
          _buildLinkTile(
            context,
            icon: Icons.code_rounded,
            title: 'Code source (GitHub)',
            onTap: () => _launchUrl(context, AppConstants.sourceCodeUrl),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
      color: colorScheme.outline.withOpacity(0.1),
    );
  }

  Widget _buildActions(BuildContext context, ColorScheme colorScheme) {
    final buttonStyle = ButtonStyle(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(
            vertical: AppConstants.defaultPadding,
            horizontal: AppConstants.largePadding),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
        ),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      elevation: WidgetStateProperty.all(0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            const String subject = 'Suggestion pour Toolbox Everything';
            const String body =
                'Bonjour, j\'ai une idée d\'outil à suggérer : ...';

            final Uri emailLaunchUri = Uri(
              scheme: 'mailto',
              path: AppConstants.contactEmail,
              query:
                  'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
            );
            _launchUrl(context, emailLaunchUri.toString());
          },
          icon: const Icon(Icons.lightbulb_outline),
          label: const Text('Suggérer un outil'),
          style: buttonStyle.copyWith(
            backgroundColor: WidgetStateProperty.all(colorScheme.primary),
            foregroundColor: WidgetStateProperty.all(colorScheme.onPrimary),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            final Uri emailLaunchUri = Uri(
              scheme: 'mailto',
              path: AppConstants.contactEmail,
              query:
                  'subject=${Uri.encodeComponent('Contact | Toolbox Everything')}',
            );
            _launchUrl(context, emailLaunchUri.toString());
          },
          icon: const Icon(Icons.mail_outline),
          label: const Text('Contacter le support'),
          style: buttonStyle.copyWith(
            side: WidgetStateProperty.all(
              BorderSide(color: colorScheme.primary, width: 1.5),
            ),
            foregroundColor: WidgetStateProperty.all(colorScheme.primary),
          ),
        ),
      ],
    );
  }
} 