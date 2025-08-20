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

  Future<void> initialize() async {
    await _qa.initialize((type) {
      final nav = navigatorKey.currentState;
      if (nav == null) return;
      switch (type) {
        case 'action_qr':
          nav.push(MaterialPageRoute(builder: (_) => const QrCodeScreen()));
          break;
        case 'action_downloader':
          nav.push(MaterialPageRoute(builder: (_) => const DownloaderScreen()));
          break;
        case 'action_convert':
          nav.push(
            MaterialPageRoute(builder: (_) => const UnitConverterScreen()),
          );
          break;
      }
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
}
