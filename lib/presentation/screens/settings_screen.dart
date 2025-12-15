import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/providers/theme_provider.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Respecte le fond global (peut être transparent/amoled/noir)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // Nouvel AppBar moderne et extensible
          SliverAppBar.large(
            pinned: true,
            leading: const BackButton(),
            leadingWidth: 68,
            centerTitle: false,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              // Masquer le titre quand on est en haut pour éviter le doublon avec le header
              title: const _CollapsingTitle(),
              titlePadding: const EdgeInsets.only(left: 92, bottom: 16),
              background: Container(
                color: colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.settings,
                              color: colorScheme.onPrimaryContainer,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Paramètres',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gérez l\'apparence et le comportement',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Contenu des paramètres
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Section Apparence
                _buildSectionHeader(
                  context,
                  'Apparence',
                  Icons.palette_outlined,
                ),

                const SizedBox(height: 8),

                // Sélecteur de thème
                _buildThemeSelector(context, themeProvider),

                const SizedBox(height: 16),

                // Carte couleur principale
                _buildColorCard(context, themeProvider),

                const SizedBox(height: 24),

                // Section Comportement
                _buildSectionHeader(
                  context,
                  'Comportement',
                  Icons.tune_outlined,
                ),

                const SizedBox(height: 12),

                Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: const Icon(Icons.screen_lock_rotation),
                    title: const Text(
                      'Verrouiller le niveau à bulle en portrait',
                    ),
                    subtitle: const Text(
                      'Empêche la rotation pour une lecture plus stable',
                    ),
                    trailing: Switch(
                      value: settingsProvider.lockBubbleLevelPortrait,
                      onChanged: (v) =>
                          settingsProvider.setLockBubbleLevelPortrait(v),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Mode économie de ressources
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: const Icon(Icons.battery_saver),
                    title: const Text('Mode économie de ressources'),
                    subtitle: const Text(
                      'Réduit les animations, les ombres et l’usage mémoire pour de meilleures performances',
                    ),
                    trailing: Switch(
                      value: settingsProvider.lowResourceMode,
                      onChanged: (v) => settingsProvider.setLowResourceMode(v),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Haptics réglables
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: const Icon(Icons.vibration),
                    title: const Text('Vibrations et haptics'),
                    subtitle: const Text(
                      'Active ou désactive les retours haptiques de l’interface',
                    ),
                    trailing: Switch(
                      value: settingsProvider.hapticsEnabled,
                      onChanged: (v) => settingsProvider.setHapticsEnabled(v),
                    ),
                  ),
                ),

                // Section À propos retirée sur demande
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Matérial You (couleurs dynamiques système)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Couleurs dynamiques système (Material You)'),
              trailing: Switch(
                value: themeProvider.useDynamicColor,
                onChanged: (v) => themeProvider.setUseDynamicColor(v),
              ),
            ),
            const SizedBox(height: 12),
            // Thème noir AMOLED (uniquement pertinent en mode sombre)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.nightlight_round),
              title: const Text('Thème noir AMOLED'),
              subtitle: const Text(
                'Noir pur pour écrans OLED, économise la batterie',
              ),
              trailing: Switch(
                value: themeProvider.useAmoledBlack,
                onChanged: (v) => themeProvider.setUseAmoledBlack(v),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mode d\'affichage',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            AbsorbPointer(
              absorbing: themeProvider.useDynamicColor,
              child: Opacity(
                opacity: themeProvider.useDynamicColor ? 0.5 : 1.0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool compact = constraints.maxWidth < 360;
                    final EdgeInsetsGeometry segPadding = EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 12,
                      vertical: compact ? 6 : 8,
                    );
                    return MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: TextScaler.linear(1.0)),
                      child: SegmentedButton<ThemeMode>(
                        segments: [
                          const ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Clair',
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                          ),
                          const ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Système',
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                          ),
                          const ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Sombre',
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                          ),
                        ],
                        selected: {themeProvider.themeMode},
                        onSelectionChanged: themeProvider.useDynamicColor
                            ? null
                            : (newSelection) {
                                themeProvider.setThemeMode(newSelection.first);
                              },
                        style: ButtonStyle(
                          visualDensity: const VisualDensity(
                            horizontal: 0,
                            vertical: -2,
                          ),
                          padding: WidgetStateProperty.all(segPadding),
                          textStyle: WidgetStateProperty.all(
                            Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildColorCard(BuildContext context, ThemeProvider themeProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.surface, colorScheme.surfaceContainerLow],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showColorPicker(context, themeProvider),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Prévisualisation couleur avec animation
                    Hero(
                      tag: 'color_preview',
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: themeProvider.seedColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: themeProvider.seedColor.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.palette,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Texte descriptif
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Couleur principale',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Personnalisez l\'apparence de votre application',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Icône action
                    Icon(
                      Icons.arrow_forward_ios,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Palette de couleurs expressives
                Text(
                  'Couleurs suggérées',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 12),

                // Grille de couleurs
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AppConstants.expressiveColors.map((color) {
                    final isSelected = color == themeProvider.seedColor;

                    return GestureDetector(
                      onTap: () {
                        themeProvider.setSeedColor(color);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.onSurface
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Carte À propos retirée

  void _showColorPicker(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Poignée de drag
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      'Choisissez une couleur',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Color Picker
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 40,
                      ),
                      child: ColorPicker(
                        pickerColor: themeProvider.seedColor,
                        onColorChanged: (color) {
                          themeProvider.setSeedColor(color);
                        },
                        labelTypes: const [],
                        pickerAreaHeightPercent: 0.6,
                        displayThumbColor: true,
                        portraitOnly: true,
                        paletteType: PaletteType.hsl,
                        enableAlpha: false,
                      ),
                    ),
                  ),
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Terminé'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CollapsingTitle extends StatelessWidget {
  const _CollapsingTitle();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final settings = context
            .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
        if (settings == null) {
          return const SizedBox.shrink();
        }
        final double delta = settings.currentExtent - settings.minExtent;
        final bool collapsed = delta <= 8;
        return collapsed ? const Text('Paramètres') : const SizedBox.shrink();
      },
    );
  }
}
