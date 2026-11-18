import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:toolbox_everything_mobile/core/feature_flags/app_feature_flags.dart';
import 'package:toolbox_everything_mobile/core/services/quick_actions_service.dart';
import 'package:toolbox_everything_mobile/core/services/youtube_service.dart';
import 'package:toolbox_everything_mobile/presentation/navigation/unified_navigation.dart';
import 'package:toolbox_everything_mobile/presentation/screens/downloader_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/essentials/json_formatter_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/essentials/jwt_decoder_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/file_converter_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/hash_calculator_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/notes_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/qr_code_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/text_encoder_screen.dart';
import 'package:toolbox_everything_mobile/presentation/screens/unit_converter_screen.dart';
import 'package:toolbox_everything_mobile/presentation/widgets/share_router_sheet.dart';

enum SharedPayloadType { text, file }

enum ShareTargetAction {
  downloader,
  qrCode,
  qrScanImage,
  notes,
  hash,
  jsonFormatter,
  jwtDecoder,
  textEncoder,
  fileConverter,
  unitConverter,
}

class SharedPayload {
  final SharedPayloadType type;
  final String? text;
  final String? filePath;
  final String? fileName;
  final String? mimeType;
  final String? target;

  const SharedPayload({
    required this.type,
    this.text,
    this.filePath,
    this.fileName,
    this.mimeType,
    this.target,
  });

  bool get isFile =>
      type == SharedPayloadType.file &&
      filePath != null &&
      filePath!.trim().isNotEmpty;

  factory SharedPayload.fromMap(Map<dynamic, dynamic> map) {
    final rawType = map['type']?.toString() ?? 'text';
    final path = map['filePath']?.toString();
    final isFilePayload =
        rawType == 'file' && path != null && path.trim().isNotEmpty;
    return SharedPayload(
      type: isFilePayload ? SharedPayloadType.file : SharedPayloadType.text,
      text: map['text']?.toString(),
      filePath: path,
      fileName: map['fileName']?.toString(),
      mimeType: map['mimeType']?.toString(),
      target: map['target']?.toString(),
    );
  }
}

class ShareRouteDecision {
  final bool directDownloader;
  final List<ShareTargetAction> actions;

  const ShareRouteDecision({
    required this.directDownloader,
    required this.actions,
  });
}

class ShareIntentService {
  ShareIntentService._();
  static final ShareIntentService instance = ShareIntentService._();

  static const MethodChannel _channel = MethodChannel(
    'com.toolbox.everything.mobile/share',
  );

  static final RegExp _youtubeDomainRegex = RegExp(
    r'(?:youtube\.com|youtu\.be|youtube-nocookie\.com)',
    caseSensitive: false,
  );

  SharedPayload? _pendingPayload;
  bool _initialized = false;

  bool get _supportsPlatformShare =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize() async {
    if (_initialized || !_supportsPlatformShare) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewShare' && call.arguments is Map) {
        final payload = SharedPayload.fromMap(
          call.arguments as Map<dynamic, dynamic>,
        );
        handlePayload(payload);
      }
    });

    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'consumeInitialShare',
      );
      if (raw != null) {
        handlePayload(SharedPayload.fromMap(raw));
      }
    } catch (_) {}
  }

  void processPendingShare() {
    if (_pendingPayload != null) {
      final payload = _pendingPayload!;
      _pendingPayload = null;
      handlePayload(payload);
    }
  }

  bool isYoutubeUrl(String text) {
    final trimmed = text.trim();
    if (!_youtubeDomainRegex.hasMatch(trimmed)) return false;
    return YoutubeService.parseVideoId(trimmed) != null;
  }

  bool looksLikeJson(String text) {
    final trimmed = text.trim();
    if (!(trimmed.startsWith('{') || trimmed.startsWith('['))) return false;
    try {
      final decoded = json.decode(trimmed);
      return decoded is Map || decoded is List;
    } catch (_) {
      return false;
    }
  }

  bool looksLikeJwt(String text) {
    final trimmed = text.trim();
    return RegExp(r'^[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]*$')
        .hasMatch(trimmed);
  }

  bool isImagePayload(SharedPayload payload) {
    if (payload.mimeType?.toLowerCase().startsWith('image/') == true) {
      return true;
    }
    final name = (payload.fileName ?? payload.filePath ?? '').toLowerCase();
    return name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.webp') ||
        name.endsWith('.gif') ||
        name.endsWith('.bmp');
  }

  bool isTextConvertibleFile(SharedPayload payload) {
    final name = (payload.fileName ?? payload.filePath ?? '').toLowerCase();
    return name.endsWith('.json') ||
        name.endsWith('.yaml') ||
        name.endsWith('.yml') ||
        name.endsWith('.csv') ||
        name.endsWith('.md') ||
        name.endsWith('.html') ||
        name.endsWith('.htm') ||
        name.endsWith('.txt');
  }

  ShareRouteDecision decideRoute(SharedPayload payload) {
    final text = payload.text?.trim() ?? '';
    final isDownloadTarget = payload.target?.toLowerCase() == 'download';

    if (AppFeatureFlags.youtubeDownloader &&
        text.isNotEmpty &&
        (isDownloadTarget || isYoutubeUrl(text))) {
      return const ShareRouteDecision(
        directDownloader: true,
        actions: [ShareTargetAction.downloader],
      );
    }

    final actions = <ShareTargetAction>[];
    if (payload.isFile) {
      if (isImagePayload(payload)) {
        actions.add(ShareTargetAction.qrScanImage);
      }
      actions.add(ShareTargetAction.hash);
      if (isTextConvertibleFile(payload)) {
        actions.add(ShareTargetAction.fileConverter);
      }
      return ShareRouteDecision(directDownloader: false, actions: actions);
    }

    if (text.isNotEmpty) {
      if (AppFeatureFlags.jsonFormatter && looksLikeJson(text)) {
        actions.add(ShareTargetAction.jsonFormatter);
      }
      if (AppFeatureFlags.jwtDecoder && looksLikeJwt(text)) {
        actions.add(ShareTargetAction.jwtDecoder);
      }
      if (double.tryParse(text.replaceAll(',', '.')) != null) {
        actions.add(ShareTargetAction.unitConverter);
      }
      actions.addAll([
        ShareTargetAction.qrCode,
        ShareTargetAction.notes,
        ShareTargetAction.hash,
        ShareTargetAction.textEncoder,
        if (AppFeatureFlags.jsonFormatter &&
            !actions.contains(ShareTargetAction.jsonFormatter))
          ShareTargetAction.jsonFormatter,
      ]);
    }

    return ShareRouteDecision(directDownloader: false, actions: actions);
  }

  void handlePayload(SharedPayload payload) {
    final decision = decideRoute(payload);
    if (!decision.directDownloader && decision.actions.isEmpty) return;

    final nav = QuickActionsService.navigatorKey.currentState;
    if (nav == null) {
      _pendingPayload = payload;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentNav = QuickActionsService.navigatorKey.currentState;
      if (currentNav == null) {
        _pendingPayload = payload;
        return;
      }

      if (decision.directDownloader) {
        _openAction(currentNav, ShareTargetAction.downloader, payload);
        return;
      }

      showModalBottomSheet<void>(
        context: currentNav.context,
        isScrollControlled: true,
        builder: (_) => ShareRouterSheet(
          payload: payload,
          decision: decision,
          onSelect: (action) => _openAction(currentNav, action, payload),
        ),
      );
    });
  }

  void _openAction(
    NavigatorState nav,
    ShareTargetAction action,
    SharedPayload payload,
  ) {
    final text = payload.text?.trim();
    final screen = switch (action) {
      ShareTargetAction.downloader => DownloaderScreen(
        heroTag: 'share_downloader',
        initialUrl: text,
      ),
      ShareTargetAction.qrCode => QrCodeScreen(
        heroTag: 'share_qr',
        initialData: text,
      ),
      ShareTargetAction.qrScanImage => QrCodeScreen(
        heroTag: 'share_qr_img',
        initialScanImagePath: payload.filePath,
      ),
      ShareTargetAction.notes => NotesScreen(
        heroTag: 'share_notes',
        initialSharedText: payload.text,
      ),
      ShareTargetAction.hash =>
        payload.isFile
            ? HashCalculatorScreen(
                heroTag: 'share_hash',
                initialFilePath: payload.filePath,
              )
            : HashCalculatorScreen(
                heroTag: 'share_hash',
                initialText: payload.text,
              ),
      ShareTargetAction.jsonFormatter => JsonFormatterScreen(
        heroTag: 'share_json',
        initialText: payload.text,
      ),
      ShareTargetAction.jwtDecoder => JwtDecoderScreen(
        heroTag: 'share_jwt',
        initialText: payload.text,
      ),
      ShareTargetAction.textEncoder => TextEncoderScreen(
        heroTag: 'share_encoder',
        initialText: payload.text,
      ),
      ShareTargetAction.fileConverter => FileConverterScreen(
        heroTag: 'share_file_conv',
        initialFilePath: payload.filePath,
      ),
      ShareTargetAction.unitConverter => UnitConverterScreen(
        heroTag: 'share_unit_conv',
        initialValue: text,
      ),
    };

    nav.push(unifiedNavigation(nav.context, screen));
  }
}
