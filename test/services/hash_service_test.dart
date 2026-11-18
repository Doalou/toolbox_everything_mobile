import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:toolbox_everything_mobile/core/services/hash_service.dart';

void main() {
  group('HashService', () {
    const svc = HashService();

    test('calcule MD5, SHA-1, SHA-256 et SHA-512 exacts pour "abc"', () {
      final res = svc.hashUtf8('abc');
      expect(res[HashAlgorithm.md5], '900150983cd24fb0d6963f7d28e17f72');
      expect(
        res[HashAlgorithm.sha1],
        'a9993e364706816aba3e25717850c26c9cd0d89d',
      );
      expect(
        res[HashAlgorithm.sha256],
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      expect(
        res[HashAlgorithm.sha512],
        'ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a'
        '2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f',
      );
    });

    test('hashFile calcule les mêmes empreintes en streaming', () async {
      final tempDir = await Directory.systemTemp.createTemp('hash_svc_test_');
      addTearDown(() => tempDir.delete(recursive: true));
      final file = File('${tempDir.path}/sample.txt');
      await file.writeAsString('Hello Toolbox!');

      double lastProgress = 0.0;
      final fileHashes = await svc.hashFile(
        file.path,
        onProgress: (p) => lastProgress = p,
      );
      final memHashes = svc.hashUtf8('Hello Toolbox!');

      expect(lastProgress, 1.0);
      expect(fileHashes, equals(memHashes));
    });

    test('matchExpected détecte la correspondance insensible à la casse', () {
      final hashes = svc.hashUtf8('abc');
      expect(
        svc.matchExpected(hashes, ' A9993E364706816ABA3E25717850C26C9CD0D89D '),
        HashAlgorithm.sha1,
      );
      expect(
        svc.matchExpected(hashes, hashes[HashAlgorithm.sha256]!),
        HashAlgorithm.sha256,
      );
      expect(svc.matchExpected(hashes, '00000000'), isNull);
      expect(svc.matchExpected(hashes, '   '), isNull);
    });
  });
}
