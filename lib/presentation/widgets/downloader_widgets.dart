import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/providers/downloader_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:toolbox_everything_mobile/core/services/downloads_saver.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoInfoCard extends StatelessWidget {
  const VideoInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final video = context.watch<DownloaderProvider>().video!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
         side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              video.thumbnails.highResUrl,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: colorScheme.surfaceContainer,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 180,
                  color: colorScheme.surfaceContainer,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                );
              },
            ),
          ),
          ListTile(
            title: Text(
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(video.author),
            trailing: Text(
              '${video.duration?.inMinutes}:${(video.duration?.inSeconds ?? 0).remainder(60).toString().padLeft(2, '0')}',
            ),
          ),
        ],
      ),
    );
  }
}

class DownloadOptions extends StatelessWidget {
  const DownloadOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloaderProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Presets
        Text('Presets Rapides', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => provider.downloadPreset('720p'),
              icon: const Icon(Icons.hd),
              label: const Text('MP4 720p'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
            ),
            OutlinedButton.icon(
              onPressed: () => provider.downloadPreset('1080p'),
              icon: const Icon(Icons.hd),
              label: const Text('MP4 1080p'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
            ),
            OutlinedButton.icon(
              onPressed: () => provider.downloadPreset('128k'),
              icon: const Icon(Icons.audiotrack),
              label: const Text('M4A 128kbps'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
            ),
            OutlinedButton.icon(
              onPressed: () => provider.downloadPreset('256k'),
              icon: const Icon(Icons.audiotrack),
              label: const Text('M4A 256kbps'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => provider.downloadBestQuality(),
          icon: const Icon(Icons.workspace_premium),
          label: const Text('Télécharger la meilleure qualité'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        // Options détaillées
        if (provider.videoDownloadOptions.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tune),
                title: const Text('Afficher WEBM'),
                subtitle: Text(
                  'Les vidéos seules peuvent nécessiter une fusion audio/vidéo (FFmpeg).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Switch.adaptive(
                  value: context.select((DownloaderProvider p) => p.showMkvOutputs),
                  onChanged: (v) => context.read<DownloaderProvider>().setShowMkvOutputs(v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Préférer MP4'),
                            selected: context.select((DownloaderProvider p) => p.preferMp4Output),
                            onSelected: (v) => context.read<DownloaderProvider>().setPreferMp4Output(v),
                          ),
                          const FilterChip(
                            label: Text('Fusion FFmpeg activée'),
                            selected: true,
                            onSelected: null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildStreamCard(
                context,
                title: 'Télécharger la vidéo',
                streams: provider.videoDownloadOptions,
                icon: Icons.video_library_rounded,
              ),
            ],
          ),
        if (provider.audioStreams.isNotEmpty)
          _buildAudioCard(
            context,
            title: 'Télécharger l\'audio seul',
            streams: provider.audioStreams,
            icon: Icons.audiotrack_rounded,
          ),
      ],
    );
  }

  String _shortAudioCodec(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('aac') || lower.contains('m4a')) return 'AAC';
    if (lower.contains('opus')) return 'OPUS';
    if (lower.contains('mp3') || lower.contains('lame')) return 'MP3';
    return raw.isEmpty ? 'codec?' : raw;
  }
  Widget _buildStreamCard(
    BuildContext context, {
    required String title,
    required List<StreamInfo> streams,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
         side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: streams.map((stream) {
          String quality = '';
          Widget? trailingIcon;
          String? codecLabel;
          if (stream is VideoStreamInfo) {
            quality = stream.qualityLabel;
            // youtube_explode_dart exposes codec tags via codec.mimeType or the typed class; fallback to container
            try {
              // Some versions expose codec info on the stream object
              // ignore: unnecessary_cast
              final dynamic anyStream = stream as dynamic;
              codecLabel = (anyStream.videoCodec?.toString() ?? anyStream.codec?.toString());
            } catch (_) {
              codecLabel = null;
            }
            if (stream is VideoOnlyStreamInfo) {
              trailingIcon = Tooltip(
                message: 'Fusion requise avec une piste audio',
                child: Icon(Icons.merge_type, size: 20, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
              );
            }
          } else if (stream is AudioOnlyStreamInfo) {
            quality = '${(stream.bitrate.kiloBitsPerSecond).round()}kbps';
            try {
              final dynamic anyStream = stream as dynamic;
              codecLabel = (anyStream.audioCodec?.toString() ?? anyStream.codec?.toString());
            } catch (_) {
              codecLabel = null;
            }
          }

          return InkWell(
            onTap: () async {
              final provider = context.read<DownloaderProvider>();
          // Sur Web, le provider lèvera une erreur via le stub
              if (stream is VideoOnlyStreamInfo) {
                // Si vidéo seule, proposer un sélecteur de piste audio
                final audio = await _pickAudioStream(context, provider.audioStreams);
                if (audio != null) {
                  // ignore: use_build_context_synchronously
                  await provider.startMergedDownload(video: stream, audio: audio);
                }
              } else {
                await provider.startDownload(stream);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(quality, style: const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          '${stream.container.name.toUpperCase()} • ${(codecLabel ?? 'codec?')} • ${(stream.size.totalMegaBytes).toStringAsFixed(2)} MB',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    trailingIcon,
                  ],
                  const SizedBox(width: 16),
                  const Icon(Icons.download),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAudioCard(
    BuildContext context, {
    required String title,
    required List<AudioOnlyStreamInfo> streams,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // Ajoute une option MP3 virtuelle: on convertira l'audio choisi en MP3 via FFmpeg
    return Card(
      elevation: 0,
       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
         side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          ...streams.map((a) {
            final codecLabel = () {
              try {
                final dynamic any = a as dynamic;
                final raw = (any.audioCodec?.toString() ?? any.codec?.toString() ?? '');
                return _shortAudioCodec(raw);
              } catch (_) {
                return 'codec?';
              }
            }();
            return InkWell(
              onTap: () async {
                await context.read<DownloaderProvider>().startDownload(a);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${a.bitrate.kiloBitsPerSecond.round()} kbps', style: const TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                            '${a.container.name.toUpperCase()} • $codecLabel • ${(a.size.totalMegaBytes).toStringAsFixed(2)} MB',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.download),
                  ],
                ),
              ),
            );
          }),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.library_music),
            title: const Text('Exporter en MP3'),
            subtitle: const Text('Convertit la meilleure piste audio en MP3 via FFmpeg'),
            onTap: () async {
              final provider = context.read<DownloaderProvider>();
              if (streams.isEmpty) return;
              final best = streams.first;
              await provider.startAudioMp3Conversion(best);
            },
          ),
        ],
      ),
    );
  }

  Future<AudioOnlyStreamInfo?> _pickAudioStream(
    BuildContext context,
    List<AudioOnlyStreamInfo> audios,
  ) async {
    if (audios.isEmpty) return null;
    return showModalBottomSheet<AudioOnlyStreamInfo>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Choisir la piste audio',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: audios.length,
                  separatorBuilder: (_, __) => Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                  itemBuilder: (_, index) {
                    final a = audios[index];
                    final label = '${a.container.name.toUpperCase()} • ${a.bitrate.kiloBitsPerSecond.round()} kbps • ${(a.size.totalMegaBytes).toStringAsFixed(2)} MB';
                    return ListTile(
                      leading: const Icon(Icons.audiotrack),
                      title: Text(label),
                      onTap: () => Navigator.of(ctx).pop(a),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class DownloadProgressIndicator extends StatelessWidget {
  const DownloadProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloaderProvider>();
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(12),
         side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
       ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.currentDownloadTitle == null
                  ? 'Téléchargement en cours...'
                  : 'Téléchargement: ${provider.currentDownloadTitle}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: provider.progress),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  borderRadius: BorderRadius.circular(8),
                  minHeight: 8,
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${provider.downloadedMbText} / ${provider.totalMbText} • ${provider.speedText} • ${provider.etaText}',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('${(provider.progress * 100).toStringAsFixed(0)}%'),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => context.read<DownloaderProvider>().cancelDownload(),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Annuler'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CompletedDownloadCard extends StatelessWidget {
  const CompletedDownloadCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloaderProvider>();
    final path = provider.lastOutputPath;
    if (path == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(16),
         side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
       ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Téléchargement terminé',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.12),
                    ),
                  ),
                  child: SelectableText(
                    path,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          if (path.startsWith('content://')) {
                            await DownloadsSaver.openSaved(path);
                          } else {
                            await OpenFile.open(path);
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Ouvrir'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.read<DownloaderProvider>().clear(),
                        icon: const Icon(Icons.close),
                        label: const Text('Fermer'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
