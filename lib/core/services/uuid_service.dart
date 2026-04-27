import 'dart:math';

/// Génère des UUID v4 (RFC 4122) en pur Dart, sans dépendance externe.
class UuidService {
  UuidService({Random? random}) : _rng = random ?? Random.secure();

  final Random _rng;

  /// Génère un UUID v4 (variante DCE 1.1).
  String v4() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    // Version 4
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Variant 10xx
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final s = bytes.map(hex).join();
    return '${s.substring(0, 8)}-'
        '${s.substring(8, 12)}-'
        '${s.substring(12, 16)}-'
        '${s.substring(16, 20)}-'
        '${s.substring(20, 32)}';
  }

  /// Génère [count] UUID v4.
  List<String> v4Many(int count) =>
      List.generate(count, (_) => v4(), growable: false);

  /// Vérifie qu'une chaîne respecte le format UUID (toutes versions).
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  bool isValid(String input) => _uuidRegex.hasMatch(input);
}
