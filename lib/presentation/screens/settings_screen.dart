import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_motion.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';
import 'package:toolbox_everything_mobile/core/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            pinned: true,
            leading: const BackButton(),
            expandedHeight: 188,
            elevation: 0,
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(72, 0, 20, 16),
              title: const _CollapsingTitle(),
              background: const _SettingsHeader(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            sliver: SliverList.list(
              children: [
                _SettingsPanel(
                  title: 'Apparence',
                  icon: Icons.palette_outlined,
                  children: [
                    _ThemeModeSelector(themeProvider: themeProvider),
                    _SettingsDivider(),
                    _SwitchTile(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Couleurs système',
                      subtitle:
                          'Utilise la palette Material You fournie par Android.',
                      value: themeProvider.useDynamicColor,
                      onChanged: themeProvider.setUseDynamicColor,
                    ),
                    _SettingsDivider(),
                    _SwitchTile(
                      icon: Icons.nightlight_round,
                      title: 'Noir AMOLED',
                      subtitle: 'Applique un fond noir pur en mode sombre.',
                      value: themeProvider.useAmoledBlack,
                      onChanged: themeProvider.setUseAmoledBlack,
                    ),
                    _SettingsDivider(),
                    _ActionTile(
                      icon: Icons.restart_alt_rounded,
                      title: 'Réinitialiser l’apparence',
                      subtitle:
                          'Revient au thème auto et à l’accent par défaut.',
                      onTap: () {
                        themeProvider.resetAppearance();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Apparence réinitialisée'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AccentPanel(themeProvider: themeProvider),
                const SizedBox(height: 16),
                _SettingsPanel(
                  title: 'Comportement',
                  icon: Icons.tune_rounded,
                  children: [
                    _SwitchTile(
                      icon: Icons.screen_lock_rotation,
                      title: 'Niveau à bulle en portrait',
                      subtitle:
                          'Verrouille l’orientation pour stabiliser la lecture.',
                      value: settingsProvider.lockBubbleLevelPortrait,
                      onChanged: settingsProvider.setLockBubbleLevelPortrait,
                    ),
                    _SettingsDivider(),
                    _SwitchTile(
                      icon: Icons.battery_saver_rounded,
                      title: 'Économie de ressources',
                      subtitle:
                          'Réduit les animations et certains effets visuels.',
                      value: settingsProvider.lowResourceMode,
                      onChanged: settingsProvider.setLowResourceMode,
                    ),
                    _SettingsDivider(),
                    _SwitchTile(
                      icon: Icons.vibration_rounded,
                      title: 'Retours haptiques',
                      subtitle: 'Active les vibrations légères de l’interface.',
                      value: settingsProvider.hapticsEnabled,
                      onChanged: settingsProvider.setHapticsEnabled,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: ShapeDecoration(
                    color: scheme.primaryContainer,
                    shape: const StadiumBorder(),
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    color: scheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paramètres',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Apparence et comportement de l’application',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsPanel({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        Material(
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeProvider themeProvider;

  const _ThemeModeSelector({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contrast_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Mode d’affichage',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_rounded),
                  label: Text('Clair'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_rounded),
                  label: Text('Auto'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_rounded),
                  label: Text('Sombre'),
                ),
              ],
              selected: {themeProvider.themeMode},
              onSelectionChanged: (selection) {
                themeProvider.setThemeMode(selection.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentPanel extends StatelessWidget {
  final ThemeProvider themeProvider;

  const _AccentPanel({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sourceColor = themeProvider.seedColor;
    final appliedColor = themeProvider.useDynamicColor
        ? scheme.primary
        : ColorScheme.fromSeed(
            seedColor: sourceColor,
            brightness: scheme.brightness,
            dynamicSchemeVariant: DynamicSchemeVariant.expressive,
          ).primary;

    return _SettingsPanel(
      title: 'Accentuation',
      icon: Icons.format_paint_rounded,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _AccentPreview(
                    color: appliedColor,
                    sourceColor: sourceColor,
                    showSource: !themeProvider.useDynamicColor,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          themeProvider.useDynamicColor
                              ? 'Palette système active'
                              : 'Accent appliqué',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          themeProvider.useDynamicColor
                              ? 'Choisir une couleur désactivera les couleurs système.'
                              : 'La couleur choisie sert de source à la palette Material.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Couleur personnalisée',
                    onPressed: () => _showColorPicker(context, themeProvider),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final color in AppConstants.expressiveColors)
                    _AccentSwatch(
                      sourceColor: color,
                      appliedColor: ColorScheme.fromSeed(
                        seedColor: color,
                        brightness: scheme.brightness,
                        dynamicSchemeVariant: DynamicSchemeVariant.expressive,
                      ).primary,
                      selected: color.toARGB32() == sourceColor.toARGB32(),
                      onTap: () => themeProvider.setSeedColor(color),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showColorPicker(BuildContext context, ThemeProvider themeProvider) {
    var draftColor = themeProvider.seedColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final appliedDraftColor = ColorScheme.fromSeed(
              seedColor: draftColor,
              brightness: scheme.brightness,
              dynamicSchemeVariant: DynamicSchemeVariant.expressive,
            ).primary;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  top: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _AccentPreview(
                          color: appliedDraftColor,
                          sourceColor: draftColor,
                          size: 44,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Couleur d’accentuation',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fermer',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aperçu : la pastille principale montre l’accent appliqué, le petit point la couleur source.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ColorPicker(
                      pickerColor: draftColor,
                      onColorChanged: (color) {
                        setModalState(() => draftColor = color);
                      },
                      labelTypes: const [],
                      pickerAreaHeightPercent: 0.55,
                      displayThumbColor: true,
                      portraitOnly: true,
                      paletteType: PaletteType.hsl,
                      enableAlpha: false,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          themeProvider.setSeedColor(draftColor);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: Text(
                          themeProvider.useDynamicColor
                              ? 'Appliquer et désactiver les couleurs système'
                              : 'Appliquer',
                        ),
                      ),
                    ),
                    if (themeProvider.useDynamicColor) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Les couleurs dynamiques Android seront réactivables ici à tout moment.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AccentPreview extends StatelessWidget {
  final Color color;
  final Color? sourceColor;
  final bool showSource;
  final double size;

  const _AccentPreview({
    required this.color,
    this.sourceColor,
    this.showSource = true,
    this.size = 54,
  });

  @override
  Widget build(BuildContext context) {
    final source = sourceColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white),
        ),
        if (showSource && source != null)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: BoxDecoration(
                color: source,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  final Color sourceColor;
  final Color appliedColor;
  final bool selected;
  final VoidCallback onTap;

  const _AccentSwatch({
    required this.sourceColor,
    required this.appliedColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: selected ? 'Couleur active' : 'Choisir cette couleur',
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: AnimatedContainer(
          duration: ExpressiveMotion.short3,
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: appliedColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? scheme.onSurface : Colors.transparent,
              width: 2,
            ),
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
              : Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: sourceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 1.5),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: ShapeDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.72),
                shape: const StadiumBorder(),
              ),
              child: Icon(icon, color: scheme.onPrimaryContainer, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 72,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.45),
    );
  }
}

class _CollapsingTitle extends StatelessWidget {
  const _CollapsingTitle();

  @override
  Widget build(BuildContext context) {
    final settings = context
        .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    if (settings == null) return const SizedBox.shrink();

    final collapsed = settings.currentExtent - settings.minExtent <= 8;
    return collapsed ? const Text('Paramètres') : const SizedBox.shrink();
  }
}
