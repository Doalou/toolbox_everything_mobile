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

  /// Tente d'analyser une date ISO 8601 ou au format `DD/MM/YYYY [HH:MM[:SS]]`.
  DateTime? tryParseDate(String input, {bool utc = false}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final frMatch = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4})(?:[ T](\d{1,2}):(\d{2})(?::(\d{2}))?)?$',
    ).firstMatch(trimmed);
    if (frMatch != null) {
      final day = int.parse(frMatch.group(1)!);
      final month = int.parse(frMatch.group(2)!);
      final year = int.parse(frMatch.group(3)!);
      final hour = frMatch.group(4) != null ? int.parse(frMatch.group(4)!) : 0;
      final minute = frMatch.group(5) != null
          ? int.parse(frMatch.group(5)!)
          : 0;
      final second = frMatch.group(6) != null
          ? int.parse(frMatch.group(6)!)
          : 0;
      if (month < 1 ||
          month > 12 ||
          day < 1 ||
          day > 31 ||
          hour > 23 ||
          minute > 59 ||
          second > 59) {
        return null;
      }
      final candidate = utc
          ? DateTime.utc(year, month, day, hour, minute, second)
          : DateTime(year, month, day, hour, minute, second);
      if (candidate.year != year ||
          candidate.month != month ||
          candidate.day != day) {
        return null;
      }
      return candidate;
    }

    final iso = DateTime.tryParse(trimmed);
    if (iso == null) return null;
    final hasExplicitZone =
        trimmed.endsWith('Z') ||
        trimmed.endsWith('z') ||
        RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(trimmed);
    if (hasExplicitZone) return iso;
    if (utc && !iso.isUtc) {
      return DateTime.utc(
        iso.year,
        iso.month,
        iso.day,
        iso.hour,
        iso.minute,
        iso.second,
        iso.millisecond,
        iso.microsecond,
      );
    }
    return iso;
  }

  /// Libellé relatif lisible en français (ex: « il y a 5 min », « dans 2 j »).
  String relativeFromNow(DateTime dt, {DateTime? reference}) {
    final now = (reference ?? DateTime.now()).toUtc();
    final diff = now.difference(dt.toUtc());
    final abs = diff.abs();
    if (abs.inSeconds < 5) {
      return 'à l’instant';
    }
    final isPast = !diff.isNegative;
    final prefix = isPast ? 'il y a' : 'dans';

    if (abs.inSeconds < 60) {
      return '$prefix ${abs.inSeconds} s';
    }
    if (abs.inMinutes < 60) {
      return '$prefix ${abs.inMinutes} min';
    }
    if (abs.inHours < 24) {
      return '$prefix ${abs.inHours} h';
    }
    if (abs.inDays < 30) {
      return '$prefix ${abs.inDays} j';
    }
    if (abs.inDays < 365) {
      return '$prefix ${(abs.inDays / 30).floor()} mois';
    }
    final years = (abs.inDays / 365).floor();
    return '$prefix $years ${years > 1 ? 'ans' : 'an'}';
  }

  /// Format ISO 8601 avec offset (ex: 2026-04-25T12:34:56.000Z).
  String toIso(DateTime dt) => dt.toIso8601String();

  /// Format lisible local (ex: « 25/04/2026 14:34:56 »).
  String toReadable(DateTime dt, {bool utc = false}) {
    final l = utc ? dt.toUtc() : dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year} '
        '${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
  }

  /// Timestamp courant en secondes.
  int nowSeconds() => (DateTime.now().millisecondsSinceEpoch / 1000).floor();

  /// Timestamp courant en millisecondes.
  int nowMillis() => DateTime.now().millisecondsSinceEpoch;
}
