import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/services/qr_history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QrHistoryService', () {
    const svc = QrHistoryService();

    test('construit et analyse un QR Wi-Fi avec caractères spéciaux', () {
      final payload = svc.buildWifiPayload(
        ssid: 'Mon:Wifi;Perso',
        password: r'secret\pass',
        security: 'WPA',
        hidden: true,
      );
      expect(payload, contains('T:WPA'));
      expect(payload, contains('H:true'));

      final parsed = svc.parseQrData(payload);
      expect(parsed.type, QrContentType.wifi);
      expect(parsed.ssid, 'Mon:Wifi;Perso');
      expect(parsed.password, r'secret\pass');
      expect(parsed.security, 'WPA');
    });

    test('construit et analyse un contact vCard et un e-mail', () {
      final vcard = svc.buildVCardPayload(
        fullName: 'Ada Lovelace',
        phone: '+33612345678',
        email: 'ada@example.org',
      );
      final parsedVCard = svc.parseQrData(vcard);
      expect(parsedVCard.type, QrContentType.vcard);
      expect(parsedVCard.fullName, 'Ada Lovelace');
      expect(parsedVCard.phone, '+33612345678');
      expect(parsedVCard.email, 'ada@example.org');

      final mail = svc.buildEmailPayload(
        to: 'contact@doalo.fr',
        subject: 'Bonjour monde',
        body: 'Test QR',
      );
      expect(mail, startsWith('mailto:contact@doalo.fr'));
      expect(mail, isNot(contains('+')));
      final parsedMail = svc.parseQrData(mail);
      expect(parsedMail.type, QrContentType.email);
      expect(parsedMail.email, 'contact@doalo.fr');
    });

    test('détecte les URL, téléphones et textes simples', () {
      expect(
        svc.parseQrData('https://toolbox.doalo.fr').type,
        QrContentType.url,
      );
      expect(svc.parseQrData('tel:+33102030405').type, QrContentType.phone);
      expect(svc.parseQrData('Note simple').type, QrContentType.text);
    });

    test('persiste, déduplique et limite l’historique QR', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await svc.add('https://example.com', isScanned: true, preferences: prefs);
      await svc.add(
        'WIFI:T:WPA;S:Home;P:1234;;',
        isScanned: false,
        preferences: prefs,
      );
      final list = await svc.add(
        'https://example.com',
        isScanned: true,
        preferences: prefs,
      );

      expect(list, hasLength(2));
      expect(list.first.data, 'https://example.com');
      expect(list.first.isScanned, isTrue);

      final afterRemove = await svc.remove(list.first.id, preferences: prefs);
      expect(afterRemove, hasLength(1));

      await svc.clear(preferences: prefs);
      expect(await svc.load(preferences: prefs), isEmpty);
    });
  });
}
