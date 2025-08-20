import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/providers/downloader_provider.dart';
import 'package:toolbox_everything_mobile/presentation/widgets/downloader_widgets.dart';

class DownloaderScreen extends StatelessWidget {
  const DownloaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Téléchargeur YouTube'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Bandeau d'intro (Material You harmonisé)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.video_file_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Téléchargeur YouTube',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Collez un lien YouTube pour récupérer la vidéo ou l’audio. Conversion MP3 et fusion vidéo/audio disponibles.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withValues(alpha: 0.8),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const UrlInputField(),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer<DownloaderProvider>(
              builder: (context, provider, child) {
                // Bandeau persistant d'état de téléchargement (au-dessus du contenu)
                final Widget downloadBanner =
                    provider.downloadActivity ==
                            DownloadActivityState.downloading
                        ? const Padding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: DownloadProgressIndicator(),
                          )
                        : (provider.downloadActivity ==
                                DownloadActivityState.completed
                            ? const Padding(
                                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                                child: CompletedDownloadCard(),
                              )
                            : const SizedBox.shrink());

                Widget bodyContent;
                switch (provider.state) {
                  case DownloaderState.loading:
                    bodyContent = const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    );
                    break;
                  case DownloaderState.error:
                    bodyContent = Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            provider.errorMessage ?? 'Une erreur est survenue.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                    break;
                  case DownloaderState.success:
                    bodyContent = Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: const [
                            VideoInfoCard(),
                            SizedBox(height: 16),
                            DownloadOptions(),
                          ],
                        ),
                      ),
                    );
                    break;
                  default:
                    bodyContent = const Expanded(
                      child: Center(
                        child: Text(
                          'Veuillez entrer une URL YouTube pour commencer.',
                        ),
                      ),
                    );
                    break;
                }
                return Column(
                  children: [
                    if (provider.hasDownloadStatus) downloadBanner,
                    bodyContent,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class UrlInputField extends StatefulWidget {
  const UrlInputField({super.key});

  @override
  State<UrlInputField> createState() => _UrlInputFieldState();
}

class _UrlInputFieldState extends State<UrlInputField> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloaderProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Collez l\'URL YouTube ici',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.link),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () async {
                    final data =
                        await Clipboard.getData(Clipboard.kTextPlain);
                    if (!mounted) return;
                    final text = data?.text;
                    if (text != null && text.isNotEmpty) {
                      _controller.text = text;
                      context
                          .read<DownloaderProvider>()
                          .fetchVideoInfo(text);
                    }
                  },
                ),
              ),
              onSubmitted: provider.isFetching
                  ? null
                  : (text) {
                      FocusScope.of(context).unfocus();
                      context
                          .read<DownloaderProvider>()
                          .fetchVideoInfo(text);
                    },
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.search),
            onPressed: provider.isFetching
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    context
                        .read<DownloaderProvider>()
                        .fetchVideoInfo(_controller.text);
                  },
            style: IconButton.styleFrom(
              minimumSize: const Size.square(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
