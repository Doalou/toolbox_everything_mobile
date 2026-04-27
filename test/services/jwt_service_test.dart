import 'package:flutter_test/flutter_test.dart';
import 'package:toolbox_everything_mobile/core/services/jwt_service.dart';

void main() {
  group('JwtService', () {
    const svc = JwtService();
    // {"alg":"HS256","typ":"JWT"} . {"sub":"42","name":"Toolbox","iat":1516239022} . sig
    const sample =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJzdWIiOiI0MiIsIm5hbWUiOiJUb29sYm94IiwiaWF0IjoxNTE2MjM5MDIyfQ.'
        'fakesig';

    test('decode retourne header+payload+signature', () {
      final d = svc.decode(sample);
      expect(d.header['alg'], 'HS256');
      expect(d.header['typ'], 'JWT');
      expect(d.payload['sub'], '42');
      expect(d.payload['name'], 'Toolbox');
      expect(d.payload['iat'], 1516239022);
      expect(d.signature, 'fakesig');
    });

    test('decode lance FormatException si moins de 3 segments', () {
      expect(() => svc.decode('aaa.bbb'), throwsFormatException);
    });

    test('decode lance FormatException si segment non base64', () {
      expect(() => svc.decode('!!!.???.zzz'), throwsA(isA<Exception>()));
    });

    test('issuedAt parse iat correctement', () {
      final d = svc.decode(sample);
      expect(d.issuedAt, isNotNull);
      expect(d.issuedAt!.year, 2018);
    });

    test('isExpired = false sans claim exp', () {
      final d = svc.decode(sample);
      expect(d.isExpired, isFalse);
    });
  });
}
