/// Service pur de conversion timestamp ↔︎ DateTime.
class TimestampService {
  const TimestampService();

  /// Convertit un timestamp (s ou ms selon [milliseconds]) en [DateTime] UTC.
  DateTime fromTimestamp(
    int value, {
    bool milliseconds = false,
    bool utc = true,
  }) {
    final dt = milliseconds
        ? DateTime.fromMillisecondsSinceEpoch(value, isUtc: utc)
        : DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: utc);
    return utc ? dt.toUtc() : dt.toLocal();
  }

  /// Convertit un [DateTime] en timestamp Unix.
  int toTimestamp(DateTime dt, {bool milliseconds = false}) {
    final ms = dt.toUtc().millisecondsSinceEpoch;
    return milliseconds ? ms : (ms / 1000).floor();
  }

  /// Format ISO 8601 avec offset (ex: 2026-04-25T12:34:56.000Z).
  String toIso(DateTime dt) => dt.toIso8601String();

  /// Format lisible local (ex: « 25 avr. 2026 14:34:56 »).
  String toReadable(DateTime dt) {
    final l = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year} '
        '${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
  }

  /// Timestamp courant en secondes.
  int nowSeconds() => (DateTime.now().millisecondsSinceEpoch / 1000).floor();

  /// Timestamp courant en millisecondes.
  int nowMillis() => DateTime.now().millisecondsSinceEpoch;
}
