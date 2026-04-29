import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_motion.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/models/tool_item.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';
import 'package:toolbox_everything_mobile/core/services/usage_stats_service.dart';
import 'package:toolbox_everything_mobile/core/tool_catalog.dart';
import 'package:toolbox_everything_mobile/presentation/navigation/unified_navigation.dart';
import 'package:toolbox_everything_mobile/presentation/screens/about_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/settings_screen.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_section.dart';
import 'package:toolbox_everything_mobile/shared/widgets/tool_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final List<ToolItem> _allTools;
  late List<ToolItem> _filtered;
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _stagger;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _allTools = ToolCatalog.all();
    _filtered = _allTools;
    _searchController.addListener(_onQuery);
    _stagger = AnimationController(
      vsync: this,
      duration: ExpressiveMotion.long2,
    );
    _loadFavorites();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isLowResource) return;
      _stagger.forward();
    });
  }

  bool get _isLowResource => context.read<SettingsProvider>().lowResourceMode;

  @override
  void dispose() {
    _searchController.dispose();
    _stagger.dispose();
    super.dispose();
  }

  void _onQuery() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _allTools;
      } else {
        _filtered = _allTools.where((t) {
          final hay =
              '${t.title} ${t.subtitle ?? ''} '
                      '${t.category.label} ${t.tags.join(' ')}'
                  .toLowerCase();
          return hay.contains(q);
        }).toList();
      }
    });
    if (!_isLowResource) {
      _stagger
        ..reset()
        ..forward();
    }
  }

  Future<void> _loadFavorites() async {
    final favs = await UsageStatsService.loadFavorites();
    if (!mounted) return;
    setState(() {
      for (final t in _allTools) {
        t.isFavorite = favs.contains(t.title);
      }
    });
  }

  Future<void> _persistFavorites() async {
    await UsageStatsService.saveFavorites(
      _allTools.where((t) => t.isFavorite).map((t) => t.title).toList(),
    );
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        _filtered = _allTools;
      }
    });
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(unifiedNavigation(context, screen));
  }

  Map<ToolCategory, List<ToolItem>> _groupByCategory(List<ToolItem> tools) {
    final map = <ToolCategory, List<ToolItem>>{};
    for (final t in tools) {
      map.putIfAbsent(t.category, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final favorites = _allTools.where((t) => t.isFavorite).toList();
    final groups = _groupByCategory(_filtered);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            pinned: true,
            stretch: true,
            expandedHeight: 158,
            elevation: 0,
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                onPressed: _toggleSearch,
                icon: Icon(
                  _searching ? Icons.close_rounded : Icons.search_rounded,
                ),
                tooltip: _searching ? 'Fermer' : 'Rechercher',
              ),
              IconButton(
                onPressed: () => _openScreen(context, const SettingsScreen()),
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Paramètres',
              ),
              IconButton(
                onPressed: () => _openScreen(context, const AboutScreen()),
                icon: const Icon(Icons.info_outline_rounded),
                tooltip: 'À propos',
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              expandedTitleScale: 1.22,
              title: const _GradientHomeTitle(),
              background: const _HeroBackground(),
            ),
          ),
          if (_searching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Rechercher un outil…',
                  leading: const Icon(Icons.search_rounded),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => _searchController.clear(),
                      ),
                  ],
                  shape: const WidgetStatePropertyAll(StadiumBorder()),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ),

          // Bandeau favoris
          if (!_searching && favorites.isNotEmpty)
            SliverToBoxAdapter(
              child: _FavoritesStrip(
                favorites: favorites,
                onChanged: () {
                  _persistFavorites();
                  setState(() {});
                },
              ),
            ),

          if (_filtered.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyResults(),
            )
          else
            ...groups.entries.expand((entry) {
              final cat = entry.key;
              final tools = entry.value;
              return [
                SliverToBoxAdapter(
                  child: ExpressiveSectionHeader(
                    title: cat.label,
                    icon: cat.icon,
                    subtitle: '${tools.length} outil(s)',
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 152,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.06,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final tool = tools[index];
                      if (_isLowResource) {
                        return ExpressiveToolCard(
                          tool: tool,
                          onFavoriteToggle: _persistFavorites,
                        );
                      }
                      final anim = CurvedAnimation(
                        parent: _stagger,
                        curve: Interval(
                          (0.04 * index).clamp(0, 0.8),
                          (0.04 * index + 0.4).clamp(0.4, 1.0),
                          curve: ExpressiveMotion.emphasizedDecelerate,
                        ),
                      );
                      return AnimatedBuilder(
                        animation: anim,
                        builder: (context, child) {
                          return Opacity(
                            opacity: anim.value,
                            child: Transform.translate(
                              offset: Offset(0, 24 * (1 - anim.value)),
                              child: child,
                            ),
                          );
                        },
                        child: ExpressiveToolCard(
                          tool: tool,
                          onFavoriteToggle: _persistFavorites,
                        ),
                      );
                    }, childCount: tools.length),
                  ),
                ),
              ];
            }),

          const SliverToBoxAdapter(child: SizedBox(height: 56)),
        ],
      ),
    );
  }
}

class _HeroBackground extends StatelessWidget {
  const _HeroBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.surface,
                  scheme.surfaceContainerLowest,
                  scheme.surfaceContainerLow,
                ],
              ),
            ),
          ),
          const Positioned.fill(
            child: CustomPaint(painter: _RipplePainter()),
          ),
        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  const _RipplePainter();

  static const _start = Color(0xFF5C6FF4);
  static const _end = Color(0xFFE870C2);
  static const _alphas = [0.50, 0.36, 0.25, 0.17, 0.11, 0.06];

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width - 30, size.height - 28);
    final shaderRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _end.withValues(alpha: 0.32),
          _end.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: origin, radius: 70));
    canvas.drawCircle(origin, 70, haloPaint);

    for (var i = 0; i < _alphas.length; i++) {
      final radius = 42.0 + i * 36.0;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == 0 ? 2.4 : 1.4
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _start.withValues(alpha: _alphas[i]),
            _end.withValues(alpha: _alphas[i]),
          ],
        ).createShader(shaderRect);
      canvas.drawCircle(origin, radius, paint);
    }

    final dotPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_start, _end],
      ).createShader(Rect.fromCircle(center: origin, radius: 12));
    canvas.drawCircle(origin, 8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) => false;
}

class _GradientHomeTitle extends StatelessWidget {
  const _GradientHomeTitle();

  static const _gradient = LinearGradient(
    colors: [Color(0xFF5c6ff4), Color(0xFFe870c2)],
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseStyle = TextStyle(
      fontWeight: FontWeight.w900,
      letterSpacing: 0,
      color: scheme.onSurface,
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                _gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            blendMode: BlendMode.srcIn,
            child: Text('Toolbox', style: baseStyle.copyWith(color: Colors.white)),
          ),
          Text(' Everything', style: baseStyle),
        ],
      ),
    );
  }
}

class _FavoritesStrip extends StatelessWidget {
  final List<ToolItem> favorites;
  final VoidCallback onChanged;

  const _FavoritesStrip({required this.favorites, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_rounded, color: scheme.error, size: 18),
              const SizedBox(width: 8),
              Text(
                'Favoris',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 12),
              itemCount: favorites.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final t = favorites[i];
                return _FavoritePill(tool: t, onChanged: onChanged);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritePill extends StatelessWidget {
  final ToolItem tool;
  final VoidCallback onChanged;
  const _FavoritePill({required this.tool, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: ExpressiveShapes.asymmetricHero(major: 18, minor: 10),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.50)),
    );

    return Material(
      color: scheme.surfaceContainerHigh,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).push(unifiedNavigation(context, tool.screenBuilder(tool.heroTag)));
        },
        child: SizedBox(
          width: 132,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 12,
                bottom: 12,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: tool.cardColor.withValues(alpha: 0.38),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(99),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: ShapeDecoration(
                        color: tool.cardColor.withValues(alpha: 0.11),
                        shape: const StadiumBorder(),
                      ),
                      child: Icon(tool.icon, color: tool.cardColor, size: 16),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        tool.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun outil trouvé',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez une autre recherche.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
