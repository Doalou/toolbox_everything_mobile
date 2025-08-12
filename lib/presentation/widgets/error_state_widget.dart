import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';

/// Widget réutilisable pour afficher les états d'erreur
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const ErrorStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline,
    this.onRetry,
    this.retryButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool lowResourceMode = context.select<SettingsProvider, bool>(
      (s) => s.lowResourceMode,
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(
                  AppConstants.largeBorderRadius,
                ),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.3),
                ),
                boxShadow: lowResourceMode
                    ? null
                    : [
                        BoxShadow(
                          color: colorScheme.error.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: colorScheme.onErrorContainer,
                    size: AppConstants.extraLargeIconSize,
                    semanticLabel: 'Icône d\'erreur',
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: AppConstants.largePadding),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: Text(retryButtonText ?? 'Réessayer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.largePadding,
                          vertical: AppConstants.defaultPadding,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget réutilisable pour afficher les états de chargement
class LoadingStateWidget extends StatelessWidget {
  final String? message;

  const LoadingStateWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          if (message != null) ...[
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget réutilisable pour afficher les états vides
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionButtonText;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              size: AppConstants.extraLargeIconSize * 1.5,
            ),
            const SizedBox(height: AppConstants.largePadding),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              const SizedBox(height: AppConstants.largePadding),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionButtonText ?? 'Commencer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
