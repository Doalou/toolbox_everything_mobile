import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/design/editorial_tokens.dart';
import 'package:toolbox_everything_mobile/core/models/tool_item.dart';
import 'package:toolbox_everything_mobile/core/services/usage_stats_service.dart';
import 'package:toolbox_everything_mobile/core/tool_catalog.dart';
import 'package:toolbox_everything_mobile/presentation/navigation/unified_navigation.dart';
import 'package:toolbox_everything_mobile/presentation/screens/about_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/settings_screen.dart';
import 'package:toolbox_everything_mobile/shared/widgets/tool_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final List<ToolItem> _allTools;
  late List<ToolItem> _filteredTools;
  final _searchController = TextEditingController();
  Set<String> _favoriteIds = <String>{};
  ToolCategory? _activeCategory;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _allTools = ToolCatalog.all();
    _filteredTools = _allTools;
    _searchController.addListener(_applyFilters);
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    await UsageStatsService.migrateLegacyData(ToolCatalog.legacyTitleToId);
    final favorites = await UsageStatsService.loadFavorites();
    if (!mounted) return;
    setState(() => _favoriteIds = favorites.toSet());
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
    _activeCategory = category;
    _applyFilters();
  }

  void _setFavorite(ToolItem tool, bool selected) {
    setState(() {
      selected ? _favoriteIds.add(tool.id) : _favoriteIds.remove(tool.id);
    });
    UsageStatsService.saveFavorites(_favoriteIds);
  }

  void _open(Widget screen) {
    Navigator.of(context).push(unifiedNavigation(context, screen));
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _allTools
        .where((tool) => _favoriteIds.contains(tool.id))
        .toList();
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
            toolbarHeight: 68,
            titleSpacing: 16,
            title: const _Wordmark(),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() => _searching = !_searching);
                  if (!_searching) _searchController.clear();
                },
                tooltip: _searching ? 'Fermer la recherche' : 'Rechercher',
                icon: Icon(
                  _searching ? Icons.close_rounded : Icons.search_rounded,
                ),
              ),
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
              const SizedBox(width: 4),
            ],
          ),
          if (_searching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Rechercher un outil…',
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
          const SliverToBoxAdapter(child: _HomeCover()),
          SliverToBoxAdapter(
            child: _SectionFrame(
              title: 'Catégories',
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
                meta: '${favorites.length} accès rapide(s)',
                child: _FavoritesRow(favorites: favorites, onOpen: _openTool),
              ),
            ),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 420,
                          mainAxisExtent: 142,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final tool = entry.value[index];
                      return ExpressiveToolCard(
                        tool: tool,
                        index: _allTools.indexOf(tool) + 1,
                        isFavorite: _favoriteIds.contains(tool.id),
                        onFavoriteChanged: (selected) =>
                            _setFavorite(tool, selected),
                      );
                    }, childCount: entry.value.length),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _openTool(ToolItem tool) {
    UsageStatsService.recordToolUsage(tool.id);
    _open(tool.screenBuilder(tool.heroTag));
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'lib/assets/images/Toolbox Everything Logo Transparent.png',
          width: 36,
          height: 36,
        ),
        const SizedBox(width: 9),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: Theme.of(context).textTheme.titleLarge,
              children: const [
                TextSpan(text: 'Toolbox'),
                TextSpan(
                  text: ' Everything',
                  style: TextStyle(
                    color: EditorialPalette.brandPinkLight,
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
  const _HomeCover();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.displayMedium,
              children: [
                const TextSpan(text: 'Tous vos outils,\n'),
                TextSpan(
                  text: 'au même endroit.',
                  style: TextStyle(
                    color: scheme.brightness == Brightness.dark
                        ? EditorialPalette.brandVioletDark
                        : EditorialPalette.brandVioletLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Text(
              'Générer, convertir, inspecter ou mesurer, directement sur votre appareil.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionFrame extends StatelessWidget {
  final String title;
  final String? meta;
  final Widget child;

  const _SectionFrame({required this.title, this.meta, required this.child});

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: outline)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (meta != null)
                  Text(meta!, style: Theme.of(context).textTheme.labelSmall),
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
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 132 + ((textScale - 1).clamp(0, 1) * 64),
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
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

class _WorkshopCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _categoryColor(category, scheme.brightness);
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.16)
          : accent.withValues(alpha: 0.07),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    index.toString().padLeft(2, '0'),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: accent),
                  ),
                  const Spacer(),
                  Text(
                    '$count outils',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                category.label,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _categoryCaption(category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoritesRow extends StatelessWidget {
  final List<ToolItem> favorites;
  final ValueChanged<ToolItem> onOpen;

  const _FavoritesRow({required this.favorites, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: favorites.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tool = favorites[index];
          return ActionChip(
            onPressed: () => onOpen(tool),
            avatar: Icon(tool.icon, size: 18, color: tool.cardColor),
            label: Text(tool.title),
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
    final outline = Theme.of(context).colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: outline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                activeCategory == null
                    ? 'Tous les outils'
                    : activeCategory!.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (activeCategory != null)
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Tout voir'),
              )
            else
              Text(
                '$count outils',
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
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
    final color = _categoryColor(category, Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 9),
      child: Row(
        children: [
          Icon(category.icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(category.label, style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          Text('$count', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 48),
            const SizedBox(height: 12),
            Text(
              'Aucun outil trouvé',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Essayez une autre recherche.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

Color _categoryColor(ToolCategory category, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (category) {
    ToolCategory.essentials || ToolCategory.productivity =>
      dark ? EditorialPalette.brandPinkDark : EditorialPalette.brandPinkLight,
    ToolCategory.media || ToolCategory.network =>
      dark
          ? EditorialPalette.brandVioletDark
          : EditorialPalette.brandVioletLight,
    _ =>
      dark ? EditorialPalette.brandBlueDark : EditorialPalette.brandBlueLight,
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
