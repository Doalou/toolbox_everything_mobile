import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/design/editorial_tokens.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_motion.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/models/tool_item.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';
import 'package:toolbox_everything_mobile/core/services/haptics_service.dart';
import 'package:toolbox_everything_mobile/core/services/usage_stats_service.dart';
import 'package:toolbox_everything_mobile/core/tool_catalog.dart';
import 'package:toolbox_everything_mobile/presentation/navigation/unified_navigation.dart';
import 'package:toolbox_everything_mobile/presentation/screens/about_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/settings_screen.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';
import 'package:toolbox_everything_mobile/shared/widgets/tool_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final List<ToolItem> _allTools;
  late final Map<String, int> _toolIndices;
  late List<ToolItem> _filteredTools;
  final _searchController = TextEditingController();
  Set<String> _favoriteIds = <String>{};
  List<String> _mostUsedIds = <String>[];
  ToolCategory? _activeCategory;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _allTools = ToolCatalog.all();
    _toolIndices = {
      for (var i = 0; i < _allTools.length; i++) _allTools[i].id: i + 1,
    };
    _filteredTools = _allTools;
    _searchController.addListener(_applyFilters);
    _loadUserPreferences();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPreferences() async {
    await UsageStatsService.migrateLegacyData(ToolCatalog.legacyTitleToId);
    final favorites = await UsageStatsService.loadFavorites();
    final mostUsed = await UsageStatsService.getMostUsedTools(limit: 6);
    if (!mounted) return;
    setState(() {
      _favoriteIds = favorites.toSet();
      _mostUsedIds = mostUsed;
    });
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredTools = _allTools.where((tool) {
        final categoryMatches =
            _activeCategory == null || tool.category == _activeCategory;
        final searchable =
            '${tool.title} ${tool.subtitle ?? ''} ${tool.category.label} '
                    '${tool.tags.join(' ')} ${tool.id}'
                .toLowerCase();
        return categoryMatches && (query.isEmpty || searchable.contains(query));
      }).toList();
    });
  }

  void _selectCategory(ToolCategory? category) {
    HapticsService.perform(context, HapticType.selection);
    _activeCategory = category;
    _applyFilters();
  }

  void _setFavorite(ToolItem tool, bool selected) {
    setState(() {
      selected ? _favoriteIds.add(tool.id) : _favoriteIds.remove(tool.id);
    });
    UsageStatsService.saveFavorites(_favoriteIds);
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(unifiedNavigation(context, screen));
    if (mounted) {
      await _loadUserPreferences();
    }
  }

  Future<void> _openTool(ToolItem tool) async {
    HapticsService.perform(context, HapticType.selection);
    await UsageStatsService.recordToolUsage(tool.id);
    if (!mounted) return;
    await _open(tool.screenBuilder(tool.heroTag));
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _allTools
        .where((tool) => _favoriteIds.contains(tool.id))
        .toList();
    final mostUsedTools = <ToolItem>[
      for (final id in _mostUsedIds)
        for (final tool in _allTools)
          if (tool.id == id && !_favoriteIds.contains(tool.id)) tool,
    ];

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final grouped = <ToolCategory, List<ToolItem>>{};
    for (final tool in _filteredTools) {
      grouped.putIfAbsent(tool.category, () => []).add(tool);
    }

    return Scaffold(
      body: CustomScrollView(
        key: const PageStorageKey('home-scroll'),
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 60,
            titleSpacing: 16,
            title: const _Wordmark(),
            actions: [
              IconButton.filledTonal(
                onPressed: () {
                  HapticsService.perform(context, HapticType.light);
                  setState(() => _searching = !_searching);
                  if (!_searching) _searchController.clear();
                },
                tooltip: _searching ? 'Fermer la recherche' : 'Rechercher',
                icon: Icon(
                  _searching ? Icons.close_rounded : Icons.search_rounded,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => _open(const SettingsScreen()),
                tooltip: 'Paramètres',
                icon: const Icon(Icons.tune_rounded),
              ),
              IconButton(
                onPressed: () => _open(const AboutScreen()),
                tooltip: 'À propos',
                icon: const Icon(Icons.info_outline_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          if (_searching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Rechercher un outil, format ou tag…',
                  leading: const Icon(Icons.search_rounded),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.clear_rounded),
                      ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: _HomeCover(
              totalTools: _allTools.length,
              favoritesCount: favorites.length,
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionFrame(
              title: 'Catégories',
              icon: Icons.grid_view_rounded,
              meta: _activeCategory != null ? 'Filtre actif' : null,
              child: _WorkshopGrid(
                tools: _allTools,
                selected: _activeCategory,
                onSelected: _selectCategory,
              ),
            ),
          ),
          if (favorites.isNotEmpty && _activeCategory == null && !_searching)
            SliverToBoxAdapter(
              child: _SectionFrame(
                title: 'Favoris',
                icon: Icons.favorite_rounded,
                meta: '${favorites.length} épinglé(s)',
                child: _QuickAccessRow(tools: favorites, onOpen: _openTool),
              ),
            ),
          if (mostUsedTools.isNotEmpty &&
              _activeCategory == null &&
              !_searching)
            SliverToBoxAdapter(
              child: _SectionFrame(
                title: 'Souvent utilisés',
                icon: Icons.bolt_rounded,
                meta: 'Accès rapide',
                child: _QuickAccessRow(tools: mostUsedTools, onOpen: _openTool),
              ),
            ),
          if (_activeCategory != null)
            SliverToBoxAdapter(
              child: _DirectoryHeading(
                count: _filteredTools.length,
                activeCategory: _activeCategory,
                onClear: () => _selectCategory(null),
              ),
            ),
          if (_filteredTools.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyResults(),
            )
          else
            ...grouped.entries.expand(
              (entry) => [
                SliverToBoxAdapter(
                  child: _CategoryHeading(
                    category: entry.key,
                    count: entry.value.length,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420,
                      mainAxisExtent: 78 + ((textScale - 1).clamp(0, 1) * 36),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final tool = entry.value[index];
                      return ExpressiveToolCard(
                        tool: tool,
                        index: _toolIndices[tool.id] ?? (index + 1),
                        isFavorite: _favoriteIds.contains(tool.id),
                        onFavoriteChanged: (selected) =>
                            _setFavorite(tool, selected),
                      );
                    }, childCount: entry.value.length),
                  ),
                ),
              ],
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          padding: const EdgeInsets.all(4.5),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(ExpressiveShapes.small),
          ),
          child: Image.asset(
            'lib/assets/images/Toolbox Everything Logo Transparent.png',
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontFamily: 'Fraunces'),
              children: [
                const TextSpan(text: 'Toolbox'),
                TextSpan(
                  text: ' Everything',
                  style: TextStyle(
                    color: scheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeCover extends StatelessWidget {
  final int totalTools;
  final int favoritesCount;

  const _HomeCover({required this.totalTools, required this.favoritesCount});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final accent = scheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: ExpressiveCard.hero(
        color: Color.alphaBlend(
          accent.withValues(alpha: isDark ? 0.14 : 0.10),
          scheme.surfaceContainerLow,
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(color: scheme.onSurface),
                children: [
                  const TextSpan(text: 'Tous vos outils,\n'),
                  TextSpan(
                    text: 'au même endroit.',
                    style: TextStyle(
                      color: isDark
                          ? EditorialPalette.brandPinkDark
                          : scheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Text(
                'Générer, convertir, inspecter ou mesurer, directement sur votre appareil.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionFrame extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? meta;
  final Widget child;

  const _SectionFrame({
    required this.title,
    this.icon,
    this.meta,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: ShapeDecoration(
                      color: scheme.secondaryContainer,
                      shape: const StadiumBorder(),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (meta != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: ShapeDecoration(
                      color: scheme.surfaceContainerHigh,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      meta!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontFamily: null,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _WorkshopGrid extends StatelessWidget {
  final List<ToolItem> tools;
  final ToolCategory? selected;
  final ValueChanged<ToolCategory?> onSelected;

  const _WorkshopGrid({
    required this.tools,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final columns = constraints.maxWidth >= 850
            ? 3
            : constraints.maxWidth >= 520
            ? 2
            : 2;
        final singleColumn = constraints.maxWidth < 340;
        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: singleColumn ? 1 : columns,
            mainAxisExtent: 98 + ((textScale - 1).clamp(0, 1) * 44),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: ToolCategory.values.length,
          itemBuilder: (context, index) {
            final category = ToolCategory.values[index];
            final count = tools
                .where((tool) => tool.category == category)
                .length;
            return _WorkshopCard(
              index: index + 1,
              category: category,
              count: count,
              selected: selected == category,
              onTap: () => onSelected(selected == category ? null : category),
            );
          },
        );
      },
    );
  }
}

class _WorkshopCard extends StatefulWidget {
  final int index;
  final ToolCategory category;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _WorkshopCard({
    required this.index,
    required this.category,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_WorkshopCard> createState() => _WorkshopCardState();
}

class _WorkshopCardState extends State<_WorkshopCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final lowResource = context.select<SettingsProvider, bool>(
      (s) => s.lowResourceMode,
    );
    final seed = _categoryColor(widget.category, scheme.brightness);

    final bgColor = widget.selected
        ? Color.alphaBlend(
            seed.withValues(alpha: isDark ? 0.24 : 0.18),
            scheme.surfaceContainerLow,
          )
        : Color.alphaBlend(
            seed.withValues(alpha: isDark ? 0.10 : 0.07),
            scheme.surfaceContainerLow,
          );
    final fgColor = scheme.onSurface;

    final card = Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: ExpressiveShapes.asymmetricHero(major: 22, minor: 12),
        side: BorderSide(
          color: widget.selected
              ? seed
              : seed.withValues(alpha: isDark ? 0.24 : 0.18),
          width: widget.selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: lowResource
            ? null
            : (v) {
                if (mounted) setState(() => _pressed = v);
              },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: ShapeDecoration(
                      color: widget.selected
                          ? seed
                          : seed.withValues(alpha: isDark ? 0.20 : 0.14),
                      shape: const StadiumBorder(),
                    ),
                    child: Icon(
                      widget.category.icon,
                      size: 16,
                      color: widget.selected ? Colors.white : seed,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 2.5,
                    ),
                    decoration: ShapeDecoration(
                      color: seed.withValues(alpha: isDark ? 0.18 : 0.12),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      '${widget.count}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: seed,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                widget.category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 14.5,
                  color: fgColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                _categoryCaption(widget.category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (lowResource) return card;
    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: ExpressiveMotion.short4,
      curve: ExpressiveMotion.springStandard,
      child: card,
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  final List<ToolItem> tools;
  final ValueChanged<ToolItem> onOpen;

  const _QuickAccessRow({required this.tools, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tools.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tool = tools[index];
          final hsl = HSLColor.fromColor(tool.cardColor);
          final accent = isDark
              ? hsl.withLightness(hsl.lightness.clamp(0.62, 0.78)).toColor()
              : hsl.withLightness(hsl.lightness.clamp(0.32, 0.48)).toColor();
          return ActionChip(
            onPressed: () => onOpen(tool),
            backgroundColor: Color.alphaBlend(
              accent.withValues(alpha: isDark ? 0.16 : 0.12),
              scheme.surfaceContainerLow,
            ),
            side: BorderSide(
              color: accent.withValues(alpha: isDark ? 0.28 : 0.22),
            ),
            avatar: Icon(tool.icon, size: 17, color: accent),
            label: Text(
              tool.title,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DirectoryHeading extends StatelessWidget {
  final int count;
  final ToolCategory? activeCategory;
  final VoidCallback onClear;

  const _DirectoryHeading({
    required this.count,
    required this.activeCategory,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: ShapeDecoration(
              color: scheme.primaryContainer,
              shape: const StadiumBorder(),
            ),
            child: Icon(
              Icons.apps_rounded,
              size: 16,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              activeCategory == null
                  ? 'Tous les outils'
                  : activeCategory!.label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (activeCategory != null)
            FilledButton.tonalIcon(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Tout voir'),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: ShapeDecoration(
                color: scheme.surfaceContainerHigh,
                shape: const StadiumBorder(),
              ),
              child: Text(
                '$count outils',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFamily: null,
                  letterSpacing: 0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryHeading extends StatelessWidget {
  final ToolCategory category;
  final int count;

  const _CategoryHeading({required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _categoryColor(category, scheme.brightness);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: ShapeDecoration(
              color: color.withValues(alpha: 0.16),
              shape: const StadiumBorder(),
            ),
            child: Icon(category.icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            category.label,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontFamily: 'Fraunces'),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: ShapeDecoration(
              color: color.withValues(alpha: 0.14),
              shape: const StadiumBorder(),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ExpressiveCard(
          color: scheme.surfaceContainerLow,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: ShapeDecoration(
                  color: scheme.secondaryContainer,
                  shape: const StadiumBorder(),
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 28,
                  color: scheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Aucun outil trouvé',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Essayez une autre recherche ou changez de catégorie.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _categoryColor(ToolCategory category, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (category) {
    ToolCategory.essentials =>
      dark ? const Color(0xFFFF7EB6) : const Color(0xFFE0398B),
    ToolCategory.converters =>
      dark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
    ToolCategory.sensors =>
      dark ? const Color(0xFF4ADE80) : const Color(0xFF0F9D70),
    ToolCategory.media =>
      dark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED),
    ToolCategory.network =>
      dark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
    ToolCategory.productivity =>
      dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
  };
}

String _categoryCaption(ToolCategory category) => switch (category) {
  ToolCategory.essentials => 'Générer, encoder, inspecter',
  ToolCategory.converters => 'Changer de format ou d’unité',
  ToolCategory.sensors => 'Lire les capteurs de l’appareil',
  ToolCategory.media => 'Fichiers, audio et vidéo',
  ToolCategory.network => 'Connectivité et diagnostic',
  ToolCategory.productivity => 'Notes et gestion du temps',
};
