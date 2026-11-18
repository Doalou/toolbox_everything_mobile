import 'package:flutter_test/flutter_test.dart';
import 'package:toolbox_everything_mobile/core/services/share_intent_service.dart';

void main() {
  group('ShareIntentService routing', () {
    final svc = ShareIntentService.instance;

    test('route directement un lien YouTube vers le Téléchargeur', () {
      final d1 = svc.decideRoute(
        const SharedPayload(
          type: SharedPayloadType.text,
          text: 'https://youtu.be/dQw4w9WgXcQ?si=test',
        ),
      );
      expect(d1.directDownloader, isTrue);
      expect(d1.actions, [ShareTargetAction.downloader]);

      final d2 = svc.decideRoute(
        const SharedPayload(
          type: SharedPayloadType.text,
          text: 'Regarde cette vidéo : https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        ),
      );
      expect(d2.directDownloader, isTrue);
    });

    test('ne route PAS un mot de 11 caractères vers le Téléchargeur', () {
      final decision = svc.decideRoute(
        const SharedPayload(type: SharedPayloadType.text, text: 'BonjourTous'),
      );
      expect(decision.directDownloader, isFalse);
      expect(decision.actions, contains(ShareTargetAction.notes));
      expect(decision.actions, contains(ShareTargetAction.qrCode));
      expect(decision.actions, isNot(contains(ShareTargetAction.downloader)));
    });

    test('priorise Formateur JSON et JWT Decoder selon le texte', () {
      final jsonDecision = svc.decideRoute(
        const SharedPayload(
          type: SharedPayloadType.text,
          text: '{"hello": "world"}',
        ),
      );
      expect(jsonDecision.directDownloader, isFalse);
      expect(jsonDecision.actions.first, ShareTargetAction.jsonFormatter);

      final jwtDecision = svc.decideRoute(
        const SharedPayload(
          type: SharedPayloadType.text,
          text: 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0In0.signature',
        ),
      );
      expect(jwtDecision.directDownloader, isFalse);
      expect(jwtDecision.actions.first, ShareTargetAction.jwtDecoder);
    });

    test('propose scanner QR sur image et convertisseur sur CSV', () {
      final imgDecision = svc.decideRoute(
        const SharedPayload(
          type: SharedPayloadType.file,
          filePath: '/tmp/photo.png',
          fileName: 'photo.png',
          mimeType: 'image/png',
        ),
      );
      expect(imgDecision.directDownloader, isFalse);
      expect(
        imgDecision.actions,
        containsAllInOrder([
          ShareTargetAction.qrScanImage,
          ShareTargetAction.hash,
        ]),
      );

      final csvDecision = svc.decideRoute(
        const SharedPayload(
          type: SharedPayloadType.file,
          filePath: '/tmp/data.csv',
          fileName: 'data.csv',
        ),
      );
      expect(csvDecision.directDownloader, isFalse);
      expect(
        csvDecision.actions,
        containsAll([ShareTargetAction.hash, ShareTargetAction.fileConverter]),
      );
    });

    test('toolbox://download force la route directe Téléchargeur', () {
      final deepLink = SharedPayload.fromMap({
        'type': 'text',
        'text': 'https://youtube.com/shorts/abc123def45',
        'target': 'download',
      });
      final decision = svc.decideRoute(deepLink);
      expect(decision.directDownloader, isTrue);
    });
  });
}
