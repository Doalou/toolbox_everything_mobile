import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';
import 'package:toolbox_everything_mobile/core/providers/downloader_provider.dart';
import 'package:toolbox_everything_mobile/presentation/widgets/downloader_widgets.dart';

class DownloaderScreen extends StatelessWidget {
  final String heroTag;

  const DownloaderScreen({super.key, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Hero(
          tag: heroTag,
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              'Téléchargeur',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<DownloaderProvider>(
        builder: (context, provider, _) {
          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _DownloaderHeader(provider: provider),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              const SliverToBoxAdapter(child: UrlInputPanel()),
              if (provider.hasDownloadStatus)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: DownloadStatusPanel(),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              switch (provider.state) {
                DownloaderState.loading => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _LoadingState(),
                  ),
                DownloaderState.error => SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(
                      message:
                          provider.errorMessage ?? 'Une erreur est survenue.',
                    ),
                  ),
                DownloaderState.success => const SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 120),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          VideoInfoCard(),
                          SizedBox(height: 14),
                          DownloadOptions(),
                        ],
                      ),
                    ),
                  ),
                DownloaderState.initial => SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(color: scheme.primary),
                  ),
              },
            ],
          );
        },
      ),
    );
  }
}

class _DownloaderHeader extends StatelessWidget {
  final DownloaderProvider provider;

  const _DownloaderHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: ShapeDecoration(
          color: scheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: ExpressiveShapes.asymmetricHero(),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: ShapeDecoration(
                    color: scheme.surface,
                    shape: const StadiumBorder(),
                  ),
                  child: Icon(
                    Icons.video_library_rounded,
                    color: scheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YouTube audio & vidéo',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Collez un lien, inspectez les formats, puis choisissez une sortie claire.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: scheme.onPrimaryContainer.withValues(
                                alpha: 0.78,
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeaderChip(
                  icon: Icons.music_note_rounded,
                  label: 'Audio',
                  color: scheme.primary,
                ),
                _HeaderChip(
                  icon: Icons.movie_creation_rounded,
                  label: 'Vidéo',
                  color: scheme.tertiary,
                ),
                _HeaderChip(
                  icon: Icons.merge_type_rounded,
                  label: 'Fusion',
                  color: scheme.secondary,
                ),
                if (provider.video != null)
                  _HeaderChip(
                    icon: Icons.check_circle_rounded,
                    label: 'Lien analysé',
                    color: scheme.primary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: scheme.surface.withValues(alpha: 0.78),
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UrlInputPanel extends StatefulWidget {
  const UrlInputPanel({super.key});

  @override
  State<UrlInputPanel> createState() => _UrlInputPanelState();
}

class _UrlInputPanelState extends State<UrlInputPanel> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloaderProvider>();
    final scheme = Theme.of(context).colorScheme;
    final busy = provider.isFetching ||
        provider.downloadActivity == DownloadActivityState.downloading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: scheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ExpressiveShapes.large),
            side: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                enabled: !busy,
                minLines: 1,
                maxLines: 2,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'https://www.youtube.com/watch?v=...',
                  prefixIcon: const Icon(Icons.link_rounded),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Coller',
                    icon: const Icon(Icons.content_paste_rounded),
                    onPressed: busy ? null : _pasteAndFetch,
                  ),
                ),
                onSubmitted: busy ? null : (_) => _fetch(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: busy ? null : _fetch,
                      icon: provider.isFetching
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.travel_explore_rounded),
                      label: Text(
                        provider.isFetching ? 'Analyse...' : 'Analyser',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: 'Effacer',
                    onPressed: busy
                        ? null
                        : () {
                            _controller.clear();
                            context.read<DownloaderProvider>().clear();
                          },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pasteAndFetch() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _controller.text = text;
    _fetch();
  }

  void _fetch() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<DownloaderProvider>().fetchVideoInfo(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Analyse du lien...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Récupération des formats audio et vidéo disponibles.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: scheme.errorContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ExpressiveShapes.large),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: scheme.onErrorContainer,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  'Impossible d’analyser ce lien',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color color;

  const _EmptyState({required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_rounded, size: 54, color: color),
            const SizedBox(height: ExpressiveTokens.spacing),
            Text(
              'Prêt à analyser',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Collez une URL YouTube pour voir les formats disponibles avant de télécharger.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
