import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

enum HashAlgorithm { md5, sha1, sha256, sha512 }

extension HashAlgorithmMeta on HashAlgorithm {
  String get label => switch (this) {
    HashAlgorithm.md5 => 'MD5',
    HashAlgorithm.sha1 => 'SHA-1',
    HashAlgorithm.sha256 => 'SHA-256',
    HashAlgorithm.sha512 => 'SHA-512',
  };
}

class _SingleDigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}

class HashService {
  const HashService();

  Map<HashAlgorithm, String> hashBytes(List<int> bytes) {
    return {
      HashAlgorithm.md5: md5.convert(bytes).toString(),
      HashAlgorithm.sha1: sha1.convert(bytes).toString(),
      HashAlgorithm.sha256: sha256.convert(bytes).toString(),
      HashAlgorithm.sha512: sha512.convert(bytes).toString(),
    };
  }

  Map<HashAlgorithm, String> hashUtf8(String text) =>
      hashBytes(utf8.encode(text));

  /// Calcule MD5, SHA-1, SHA-256 et SHA-512 en un seul passage disque par flux.
  Future<Map<HashAlgorithm, String>> hashFile(
    String path, {
    void Function(double progress)? onProgress,
  }) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('Fichier introuvable', path);
    }

    final totalBytes = await file.length();
    final md5DigestSink = _SingleDigestSink();
    final sha1DigestSink = _SingleDigestSink();
    final sha256DigestSink = _SingleDigestSink();
    final sha512DigestSink = _SingleDigestSink();

    final md5In = md5.startChunkedConversion(md5DigestSink);
    final sha1In = sha1.startChunkedConversion(sha1DigestSink);
    final sha256In = sha256.startChunkedConversion(sha256DigestSink);
    final sha512In = sha512.startChunkedConversion(sha512DigestSink);

    var processed = 0;
    await for (final chunk in file.openRead()) {
      md5In.add(chunk);
      sha1In.add(chunk);
      sha256In.add(chunk);
      sha512In.add(chunk);
      processed += chunk.length;
      if (onProgress != null) {
        final ratio = totalBytes > 0
            ? (processed / totalBytes).clamp(0.0, 1.0)
            : 1.0;
        onProgress(ratio);
      }
    }

    md5In.close();
    sha1In.close();
    sha256In.close();
    sha512In.close();
    onProgress?.call(1.0);

    return {
      HashAlgorithm.md5: md5DigestSink.value.toString(),
      HashAlgorithm.sha1: sha1DigestSink.value.toString(),
      HashAlgorithm.sha256: sha256DigestSink.value.toString(),
      HashAlgorithm.sha512: sha512DigestSink.value.toString(),
    };
  }

  /// Retourne l'algorithme correspondant au checksum attendu (insensible à la casse).
  HashAlgorithm? matchExpected(
    Map<HashAlgorithm, String> hashes,
    String expected,
  ) {
    final normalized = expected.trim().replaceAll(' ', '').toLowerCase();
    if (normalized.isEmpty) return null;
    for (final entry in hashes.entries) {
      if (entry.value.toLowerCase() == normalized) {
        return entry.key;
      }
    }
    return null;
  }
}
