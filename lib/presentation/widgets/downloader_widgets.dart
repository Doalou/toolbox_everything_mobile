import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';
import 'package:toolbox_everything_mobile/core/providers/downloader_provider.dart';
import 'package:toolbox_everything_mobile/core/services/downloads_saver.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoInfoCard extends StatelessWidget {
  const VideoInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final video = context.watch<DownloaderProvider>().video!;
    final scheme = Theme.of(context).colorScheme;
    final duration = video.duration;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ExpressiveShapes.large),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                video.thumbnails.mediumResUrl,
                width: 116,
                height: 82,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: scheme.surfaceContainerHighest,
                  child: const SizedBox(
                    width: 116,
                    height: 82,
                    child: Icon(Icons.broken_image_rounded),
                  ),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: const SizedBox(
                      width: 116,
                      height: 82,
                      child: Center(
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    video.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MetaPill(
                        icon: Icons.schedule_rounded,
                        label: duration == null
                            ? 'Durée inconnue'
                            : _formatDuration(duration),
                      ),
                      const _MetaPill(
                        icon: Icons.verified_rounded,
                        label: 'Formats prêts',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '${duration.inMinutes}:$seconds';
  }
}

class DownloadOptions extends StatelessWidget {
  const DownloadOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloaderProvider>();
    final downloading =
        provider.downloadActivity == DownloadActivityState.downloading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuickActions(disabled: downloading),
        const SizedBox(height: 14),
        _OutputPreferences(disabled: downloading),
        const SizedBox(height: 14),
        if (provider.videoDownloadOptions.isNotEmpty)
          _StreamSection(
            title: 'Vidéo',
            subtitle: 'MP4 direct si disponible, fusion automatique sinon',
            icon: Icons.movie_creation_rounded,
            children: provider.videoDownloadOptions
                .map((stream) => _VideoStreamTile(stream: stream))
                .toList(),
          ),
        if (provider.audioStreams.isNotEmpty) ...[
          const SizedBox(height: 14),
          _StreamSection(
            title: 'Audio',
            subtitle: 'Piste seule ou export MP3',
            icon: Icons.graphic_eq_rounded,
            children: [
              ...provider.audioStreams
                  .map((stream) => _AudioStreamTile(stream: stream)),
              const Divider(height: 1),
              _Mp3ExportTile(streams: provider.audioStreams),
            ],
          ),
        ],
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final bool disabled;

  const _QuickActions({required this.disabled});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DownloaderProvider>();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            icon: Icons.flash_on_rounded,
            title: 'Actions rapides',
            subtitle: 'Choisissez une sortie sans parcourir tous les flux.',
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: [
              _PresetButton(
                icon: Icons.hd_rounded,
                label: 'MP4 720p',
                onPressed: disabled ? null : () => provider.downloadPreset('720p'),
              ),
              _PresetButton(
                icon: Icons.high_quality_rounded,
                label: 'MP4 1080p',
                onPressed:
                    disabled ? null : () => provider.downloadPreset('1080p'),
              ),
              _PresetButton(
                icon: Icons.audiotrack_rounded,
                label: 'Audio 128k',
                onPressed: disabled ? null : () => provider.downloadPreset('128k'),
              ),
              _PresetButton(
                icon: Icons.library_music_rounded,
                label: 'Audio 256k',
                onPressed: disabled ? null : () => provider.downloadPreset('256k'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: disabled ? null : provider.downloadBestQuality,
            icon: const Icon(Icons.workspace_premium_rounded),
            label: const Text('Meilleure qualité disponible'),
          ),
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _PresetButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _OutputPreferences extends StatelessWidget {
  final bool disabled;

  const _OutputPreferences({required this.disabled});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final provider = context.watch<DownloaderProvider>();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.tune_rounded,
            title: 'Préférences',
            subtitle: 'Gardez MP4 par défaut, affichez WEBM si nécessaire.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Préférer MP4'),
                avatar: const Icon(Icons.smart_display_rounded, size: 18),
                selected: provider.preferMp4Output,
                onSelected: disabled
                    ? null
                    : (value) => context
                        .read<DownloaderProvider>()
                        .setPreferMp4Output(value),
              ),
              FilterChip(
                label: const Text('Afficher WEBM/MKV'),
                avatar: const Icon(Icons.video_settings_rounded, size: 18),
                selected: provider.showMkvOutputs,
                onSelected: disabled
                    ? null
                    : (value) => context
                        .read<DownloaderProvider>()
                        .setShowMkvOutputs(value),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Les flux vidéo seuls sont fusionnés avec la meilleure piste audio compatible.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _StreamSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  const _StreamSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(icon: icon, title: title, subtitle: subtitle),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _VideoStreamTile extends StatelessWidget {
  final StreamInfo stream;

  const _VideoStreamTile({required this.stream});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloaderProvider>();
    final disabled =
        provider.downloadActivity == DownloadActivityState.downloading;
    final scheme = Theme.of(context).colorScheme;
    final video = stream as VideoStreamInfo;
    final mergeRequired = stream is VideoOnlyStreamInfo;

    return _DownloadTile(
      enabled: !disabled,
      icon: mergeRequired ? Icons.merge_type_rounded : Icons.movie_rounded,
      title: video.qualityLabel,
      subtitle:
          '${stream.container.name.toUpperCase()} • ${_codecLabel(stream)} • ${_sizeLabel(stream)}',
      trailing: mergeRequired
          ? Tooltip(
              message: 'Fusion audio/vidéo automatique',
              child: Icon(Icons.call_merge_rounded, color: scheme.tertiary),
            )
          : null,
      onTap: () => context.read<DownloaderProvider>().startDownload(stream),
    );
  }
}

class _AudioStreamTile extends StatelessWidget {
  final AudioOnlyStreamInfo stream;

  const _AudioStreamTile({required this.stream});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloaderProvider>();
    final disabled =
        provider.downloadActivity == DownloadActivityState.downloading;

    return _DownloadTile(
      enabled: !disabled,
      icon: Icons.audiotrack_rounded,
      title: '${stream.bitrate.kiloBitsPerSecond.round()} kbps',
      subtitle:
          '${stream.container.name.toUpperCase()} • ${_codecLabel(stream)} • ${_sizeLabel(stream)}',
      onTap: () => context.read<DownloaderProvider>().startDownload(stream),
    );
  }
}

class _Mp3ExportTile extends StatelessWidget {
  final List<AudioOnlyStreamInfo> streams;

  const _Mp3ExportTile({required this.streams});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloaderProvider>();
    final disabled =
        provider.downloadActivity == DownloadActivityState.downloading ||
        streams.isEmpty;

    return _DownloadTile(
      enabled: !disabled,
      icon: Icons.library_music_rounded,
      title: 'Exporter en MP3',
      subtitle: 'Convertit la meilleure piste audio via FFmpeg',
      onTap: () => context
          .read<DownloaderProvider>()
          .startAudioMp3Conversion(streams.first),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  final bool enabled;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _DownloadTile({
    required this.enabled,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: ShapeDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.65),
                    shape: const StadiumBorder(),
                  ),
                  child: Icon(icon, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
                const SizedBox(width: 8),
                Icon(Icons.download_rounded, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DownloadStatusPanel extends StatelessWidget {
  const DownloadStatusPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloaderProvider>();

    return switch (provider.downloadActivity) {
      DownloadActivityState.downloading => const DownloadProgressIndicator(),
      DownloadActivityState.completed => const CompletedDownloadCard(),
      DownloadActivityState.error => const DownloadErrorCard(),
      DownloadActivityState.idle => const SizedBox.shrink(),
    };
  }
}

class DownloadProgressIndicator extends StatelessWidget {
  const DownloadProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloaderProvider>();
    final scheme = Theme.of(context).colorScheme;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.downloading_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  provider.currentDownloadTitle ?? 'Téléchargement en cours',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text('${(provider.progress * 100).toStringAsFixed(0)}%'),
            ],
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${provider.downloadedMbText} / ${provider.totalMbText} • ${provider.speedText} • ${provider.etaText}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: context.read<DownloaderProvider>().cancelDownload,
                icon: const Icon(Icons.cancel_rounded),
                label: const Text('Annuler'),
                style: TextButton.styleFrom(foregroundColor: scheme.error),
              ),
            ],
          ),
        ],
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
    final scheme = Theme.of(context).colorScheme;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Téléchargement terminé',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            path,
            maxLines: 3,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    if (path.startsWith('content://')) {
                      await DownloadsSaver.openSaved(path);
                    } else {
                      await OpenFile.open(path);
                    }
                  },
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Ouvrir'),
                ),
                OutlinedButton.icon(
                  onPressed: context.read<DownloaderProvider>().clear,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Fermer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DownloadErrorCard extends StatelessWidget {
  const DownloadErrorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloaderProvider>();
    final scheme = Theme.of(context).colorScheme;

    return _Panel(
      color: scheme.errorContainer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              provider.errorMessage ?? 'Téléchargement interrompu.',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          IconButton(
            tooltip: 'Fermer',
            onPressed: provider.clear,
            icon: Icon(Icons.close_rounded, color: scheme.onErrorContainer),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final Color? color;

  const _Panel({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color ?? scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ExpressiveShapes.large),
          side: BorderSide(
            color: color == null
                ? scheme.outlineVariant
                : Colors.transparent,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ExpressiveTokens.spacing),
        child: child,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
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
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerHighest,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: scheme.primary),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

String _sizeLabel(StreamInfo stream) =>
    '${stream.size.totalMegaBytes.toStringAsFixed(2)} MB';

String _codecLabel(StreamInfo stream) {
  try {
    final dynamic any = stream as dynamic;
    final raw = any.videoCodec?.toString() ??
        any.audioCodec?.toString() ??
        any.codec?.toString() ??
        '';
    if (raw.isEmpty) return 'codec?';
    final lower = raw.toLowerCase();
    if (lower.contains('avc') || lower.contains('h264')) return 'H.264';
    if (lower.contains('vp9')) return 'VP9';
    if (lower.contains('av01') || lower.contains('av1')) return 'AV1';
    if (lower.contains('aac') || lower.contains('mp4a')) return 'AAC';
    if (lower.contains('opus')) return 'OPUS';
    return raw;
  } catch (_) {
    return 'codec?';
  }
}
