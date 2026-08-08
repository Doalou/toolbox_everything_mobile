import 'package:flutter_test/flutter_test.dart';
import 'package:toolbox_everything_mobile/core/services/download_service.dart';

void main() {
  test('nettoie les caractères interdits des noms de fichiers', () {
    expect(
      DownloadService.sanitizeFileName('  vidéo: test / 2026?  '),
      'vidéo_ test _ 2026_',
    );
    expect(DownloadService.sanitizeFileName('   '), 'telechargement');
  });

  test('le jeton d’annulation expose une erreur utilisateur stable', () {
    final token = DownloadCancelToken()..cancel();

    expect(
      token.throwIfCancelled,
      throwsA(
        isA<DownloadException>().having(
          (error) => error.message,
          'message',
          'Téléchargement annulé.',
        ),
      ),
    );
  });

  test('la progression reste bornée entre zéro et un', () {
    const normal = DownloadProgress(
      receivedBytes: 50,
      totalBytes: 100,
      phase: DownloadPhase.downloading,
    );
    const overflow = DownloadProgress(
      receivedBytes: 150,
      totalBytes: 100,
      phase: DownloadPhase.downloading,
    );

    expect(normal.fraction, 0.5);
    expect(overflow.fraction, 1);
  });
}
