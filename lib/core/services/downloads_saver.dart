import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadsSaver {
  static const MethodChannel _channel = MethodChannel(
    'com.toolbox.everything.mobile/downloads',
  );

  static Future<String> saveFileToDownloads(
    String sourcePath, {
    required String displayName,
    String? mimeType,
    bool deleteOriginal = true,
  }) async {
    // Sur iOS, le fichier reste dans Documents et peut être partagé/ouvert par
    // les mécanismes natifs de l'application.
    if (!Platform.isAndroid) {
      return sourcePath;
    }
    try {
      final requiresLegacyPermission =
          await _channel.invokeMethod<bool>(
            'requiresLegacyStoragePermission',
          ) ??
          false;
      if (requiresLegacyPermission) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw const DownloadsSaveException(
            'La permission de stockage est nécessaire sur cette version Android.',
          );
        }
      }
      final String? saved = await _channel
          .invokeMethod<String>('saveToDownloads', {
            'sourcePath': sourcePath,
            'displayName': displayName,
            'mimeType': mimeType ?? _guessMimeType(displayName),
          });
      if (deleteOriginal) {
        try {
          final file = File(sourcePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
      if (saved == null || saved.isEmpty) {
        throw const DownloadsSaveException(
          'Android n\'a pas confirmé l\'enregistrement du fichier.',
        );
      }
      return saved;
    } on DownloadsSaveException {
      rethrow;
    } catch (error) {
      throw DownloadsSaveException(
        'Impossible d\'enregistrer le fichier dans Téléchargements.',
        cause: error,
      );
    }
  }

  static Future<void> openSaved(
    String savedPathOrUri, {
    String? mimeType,
  }) async {
    // Android: si c'est une URI content://, demander au canal d'ouvrir
    if (Platform.isAndroid && savedPathOrUri.startsWith('content://')) {
      try {
        await _channel.invokeMethod('openContentUri', {
          'uri': savedPathOrUri,
          'mimeType': mimeType ?? _guessMimeType(savedPathOrUri),
        });
        return;
      } catch (_) {}
    }
    // Fallback: utiliser open_file
    try {
      // importé dynamiquement par l'appelant si nécessaire
      // Ici on ne dépend pas de open_file pour ne pas coupler ce service
    } catch (_) {}
  }

  static String _guessMimeType(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.mp4')) return 'video/mp4';
    if (name.endsWith('.mkv')) return 'video/x-matroska';
    if (name.endsWith('.webm')) return 'video/webm';
    if (name.endsWith('.m4a')) return 'audio/mp4';
    if (name.endsWith('.aac')) return 'audio/aac';
    if (name.endsWith('.mp3')) return 'audio/mpeg';
    if (name.endsWith('.opus') || name.endsWith('.ogg')) return 'audio/ogg';
    return 'application/octet-stream';
  }
}

class DownloadsSaveException implements Exception {
  final String message;
  final Object? cause;

  const DownloadsSaveException(this.message, {this.cause});

  @override
  String toString() => message;
}
