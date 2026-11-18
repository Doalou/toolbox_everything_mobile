import 'package:material_ui/material_ui.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/services/share_intent_service.dart';

class ShareRouterSheet extends StatelessWidget {
  final SharedPayload payload;
  final ShareRouteDecision decision;
  final void Function(ShareTargetAction action) onSelect;

  const ShareRouterSheet({
    super.key,
    required this.payload,
    required this.decision,
    required this.onSelect,
  });

  ({IconData icon, String title, String subtitle}) _metaFor(
    ShareTargetAction action,
  ) => switch (action) {
    ShareTargetAction.downloader => (
      icon: Icons.download_rounded,
      title: 'Téléchargeur YouTube',
      subtitle: 'Analyser et télécharger audio ou vidéo',
    ),
    ShareTargetAction.qrCode => (
      icon: Icons.qr_code_2_rounded,
      title: 'Générer un QR Code',
      subtitle: 'Transformer ce contenu en QR Code partageable',
    ),
    ShareTargetAction.qrScanImage => (
      icon: Icons.qr_code_scanner_rounded,
      title: 'Scanner un QR dans l’image',
      subtitle: 'Lire le code-barres contenu dans ce fichier',
    ),
    ShareTargetAction.notes => (
      icon: Icons.note_alt_rounded,
      title: 'Créer une note',
      subtitle: 'Enregistrer dans le Bloc-notes local',
    ),
    ShareTargetAction.hash => (
      icon: Icons.fingerprint_rounded,
      title: 'Calculer l’empreinte (Hash)',
      subtitle: 'MD5, SHA-1, SHA-256 et SHA-512',
    ),
    ShareTargetAction.jsonFormatter => (
      icon: Icons.data_object_rounded,
      title: 'Formateur JSON',
      subtitle: 'Indenter, valider et minifier',
    ),
    ShareTargetAction.jwtDecoder => (
      icon: Icons.vpn_key_rounded,
      title: 'JWT Decoder',
      subtitle: 'Inspecter header, payload et expiration',
    ),
    ShareTargetAction.textEncoder => (
      icon: Icons.code_rounded,
      title: 'Encodeur / Décodeur',
      subtitle: 'Base64, URL, HTML et Hexadécimal',
    ),
    ShareTargetAction.fileConverter => (
      icon: Icons.transform_rounded,
      title: 'Convertisseur de fichiers',
      subtitle: 'JSON, YAML, CSV, Markdown, HTML et PDF',
    ),
    ShareTargetAction.unitConverter => (
      icon: Icons.swap_horiz_rounded,
      title: 'Convertisseur d’unités',
      subtitle: 'Pré-remplir avec cette valeur numérique',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final previewText = payload.isFile
        ? (payload.fileName ?? payload.filePath ?? 'Fichier partagé')
        : (payload.text?.trim() ?? '');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: ExpressiveShapes.asymmetricHero(
                      major: 14,
                      minor: 8,
                    ),
                  ),
                  child: Icon(
                    payload.isFile
                        ? Icons.insert_drive_file_rounded
                        : Icons.ios_share_rounded,
                    color: scheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ouvrir dans Toolbox Everything',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(ExpressiveShapes.medium),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Text(
                previewText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontFamily: payload.isFile ? null : 'monospace'),
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: decision.actions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final action = decision.actions[index];
                  final meta = _metaFor(action);
                  final recommended = index == 0;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ExpressiveShapes.large,
                      ),
                      side: BorderSide(
                        color: recommended
                            ? scheme.primary.withValues(alpha: 0.35)
                            : scheme.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                    tileColor: recommended
                        ? scheme.primaryContainer.withValues(alpha: 0.55)
                        : scheme.surfaceContainer,
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: recommended
                            ? scheme.primary
                            : scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(
                          ExpressiveShapes.medium,
                        ),
                      ),
                      child: Icon(
                        meta.icon,
                        color: recommended
                            ? scheme.onPrimary
                            : scheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    title: Text(meta.title),
                    subtitle: Text(meta.subtitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.pop(context);
                      onSelect(action);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
