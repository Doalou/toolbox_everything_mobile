import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/models/tool_item.dart';
import 'package:toolbox_everything_mobile/presentation/screens/password_generator_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/qr_code_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/unit_converter_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/compass_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/bubble_level_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/file_converter_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/downloader_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/about_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/settings_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/number_converter_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/notes_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/lorem_generator_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/hash_calculator_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/timer_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/connection_tester_screen.dart';
import 'package:toolbox_everything_mobile/presentation/widgets/tool_card.dart';
import 'package:toolbox_everything_mobile/presentation/navigation/unified_navigation.dart';
import 'package:toolbox_everything_mobile/core/services/usage_stats_service.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';
import 'package:toolbox_everything_mobile/core/constants/app_constants.dart';

final List<ToolItem> _tools = [
  ToolItem(
    title: 'Générateur de MDP',
    icon: Icons.password,
    screenBuilder: () => const PasswordGeneratorScreen(),
    category: ToolCategory.security,
  ),
  ToolItem(
    title: 'QR Code',
    icon: Icons.qr_code,
    screenBuilder: () => const QrCodeScreen(),
    category: ToolCategory.utilities,
    animates: false,
  ),
  ToolItem(
    title: 'Convertisseur d\'unités',
    icon: Icons.swap_horiz,
    screenBuilder: () => const UnitConverterScreen(),
    category: ToolCategory.conversion,
    animates: false,
  ),
  ToolItem(
    title: 'Convertisseur binaire',
    icon: Icons.transform,
    screenBuilder: () => const NumberConverterScreen(),
    category: ToolCategory.conversion,
    animates: false,
  ),
  ToolItem(
    title: 'Bloc-notes',
    icon: Icons.note_add,
    screenBuilder: () => const NotesScreen(),
    category: ToolCategory.productivity,
    animates: false,
  ),
  ToolItem(
    title: 'Lorem Ipsum',
    icon: Icons.text_snippet,
    screenBuilder: () => const LoremGeneratorScreen(),
    category: ToolCategory.productivity,
  ),
  ToolItem(
    title: 'Calculateur Hash',
    icon: Icons.fingerprint,
    screenBuilder: () => const HashCalculatorScreen(),
    category: ToolCategory.security,
    animates: false,
  ),
  ToolItem(
    title: 'Minuteur',
    icon: Icons.timer,
    screenBuilder: () => const TimerScreen(),
    category: ToolCategory.utilities,
  ),
  ToolItem(
    title: 'Boussole',
    icon: Icons.explore,
    screenBuilder: () => const CompassScreen(),
    category: ToolCategory.mobile,
  ),
  ToolItem(
    title: 'Niveau à bulle',
    icon: Icons.architecture,
    screenBuilder: () => const BubbleLevelScreen(),
    category: ToolCategory.mobile,
  ),
  ToolItem(
    title: 'Convertisseur de fichiers',
    icon: Icons.file_copy,
    screenBuilder: () => const FileConverterScreen(),
    category: ToolCategory.conversion,
    animates: false,
  ),
  ToolItem(
    title: 'Téléchargeur',
    icon: Icons.download,
    screenBuilder: () => const DownloaderScreen(),
    category: ToolCategory.media,
  ),
  ToolItem(
    title: 'Testeur de Connexion',
    icon: Icons.wifi,
    screenBuilder: () => const ConnectionTesterScreen(),
    category: ToolCategory.utilities,
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late List<ToolItem> filteredTools;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    filteredTools = _tools;
    _searchController.addListener(_filterTools);
    _loadFavorites();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _filterTools() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredTools = _tools;
      } else {
        filteredTools = _tools.where((tool) {
          return tool.title.toLowerCase().contains(query);
        }).toList();
      }
      _staggerController.reset();
      _staggerController.forward();
    });
  }

  Future<void> _loadFavorites() async {
    final favs = await UsageStatsService.loadFavorites();
    setState(() {
      for (final t in _tools) {
        t.isFavorite = favs.contains(t.title);
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        filteredTools = _tools;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool lowResourceMode = context.select<SettingsProvider, bool>(
      (s) => s.lowResourceMode,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid calculation based on available width
        int crossAxisCount = 2;
        if (constraints.maxWidth > 600) crossAxisCount = 3;
        if (constraints.maxWidth > 900) crossAxisCount = 4;

        return Scaffold(
          // si dynamique, on laisse le fond géré globalement (peut être noir AMOLED)
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              // Modern App Bar
              SliverAppBar(
                expandedHeight: lowResourceMode ? 120 : 160,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(context, lowResourceMode),
                ),
                actions: [_buildActionButtons(context)],
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: AnimatedSize(
                  duration: AppConstants.mediumAnimation,
                  curve: AppConstants.defaultAnimationCurve,
                  child: _isSearching
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Rechercher un outil...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              // Tools Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.apps_rounded,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isSearching
                              ? 'Résultats (${filteredTools.length})'
                              : 'Vos outils',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleSearch,
                        icon: Icon(
                          _isSearching ? Icons.close : Icons.search,
                          color: colorScheme.primary,
                        ),
                        tooltip: _isSearching
                            ? 'Fermer la recherche'
                            : 'Rechercher',
                      ),
                    ],
                  ),
                ),
              ),

              // Tools Grid - Uniform and Responsive
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final tool = filteredTools[index];
                    if (!tool.animates) {
                      return SizedBox.expand(
                        child: ToolCard(tool: tool),
                      );
                    }
                    
                    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _staggerController,
                        curve: Interval(
                          (0.05 * index).clamp(0.0, 1.0),
                          (0.05 * index + 0.3).clamp(0.0, 1.0),
                          curve: AppConstants.defaultAnimationCurve,
                        ),
                      ),
                    );

                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: animation.value,
                          child: Transform.translate(
                            offset: Offset(0, 40 * (1 - animation.value)),
                            child: child,
                          ),
                        );
                      },
                      child: SizedBox.expand(
                        child: ToolCard(
                          tool: filteredTools[index],
                        ),
                      ),
                    );
                  }, childCount: filteredTools.length),
                ),
              ),

              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool lowResourceMode) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: lowResourceMode
                        ? Duration.zero
                        : AppConstants.longAnimation,
                    curve: AppConstants.defaultAnimationCurve,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: null,
                    ),
                    child: Icon(
                      Icons.build_circle,
                      color: colorScheme.onPrimaryContainer,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Toolbox Everything',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vos outils numériques essentiels',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            context,
            Icons.settings_outlined,
            () {
              final lowResourceMode = context.read<SettingsProvider>().lowResourceMode;
              _navigateToScreen(context, const SettingsScreen(), lowResourceMode);
            },
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            context,
            Icons.info_outline,
            () {
              final lowResourceMode = context.read<SettingsProvider>().lowResourceMode;
              _navigateToScreen(context, const AboutScreen(), lowResourceMode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: colorScheme.primary, size: 24),
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen, bool lowResourceMode) {
    pushUnified(context, screen, lowResourceMode: lowResourceMode);
  }

}
