import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:toolbox_everything_mobile/presentation/screens/qr_code_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/downloader_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/unit_converter_screen.dart';

class QuickActionsService {
  QuickActionsService._();
  static final QuickActionsService instance = QuickActionsService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final QuickActions _qa = const QuickActions();
  String? _pendingAction;

  Future<void> initialize() async {
    await _qa.initialize((type) {
      // Tente de gérer l'action immédiatement. Si le navigateur n'est pas prêt,
      // l'action sera stockée dans _pendingAction.
      _handleAction(type);
    });

    await _qa.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_qr',
        localizedTitle: 'QR Code',
        icon: 'ic_shortcut_qr',
      ),
      const ShortcutItem(
        type: 'action_downloader',
        localizedTitle: 'Téléchargeur',
        icon: 'ic_shortcut_download',
      ),
      const ShortcutItem(
        type: 'action_convert',
        localizedTitle: 'Convertisseur',
        icon: 'ic_shortcut_convert',
      ),
    ]);
  }

  /// Vérifie et exécute une action en attente.
  /// Doit être appelé une fois que l'interface est prête.
  void processPendingAction() {
    if (_pendingAction != null) {
      _handleAction(_pendingAction!);
      _pendingAction = null; // L'action est consommée
    }
  }

  void _handleAction(String type) {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      // Le navigateur n'est pas encore prêt, on stocke l'action.
      _pendingAction = type;
      return;
    }

    // S'assurer que le frame est bien rendu avant de naviguer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentState == null) {
        _pendingAction = type; // Sécurité supplémentaire
        return;
      }
      switch (type) {
        case 'action_qr':
          nav.push(
            MaterialPageRoute(
              builder: (_) => const QrCodeScreen(heroTag: 'quick_action_qr'),
            ),
          );
          break;
        case 'action_downloader':
          nav.push(
            MaterialPageRoute(
              builder: (_) =>
                  const DownloaderScreen(heroTag: 'quick_action_downloader'),
            ),
          );
          break;
        case 'action_convert':
          nav.push(
            MaterialPageRoute(
              builder: (_) =>
                  const UnitConverterScreen(heroTag: 'quick_action_converter'),
            ),
          );
          break;
      }
    });
  }
}
