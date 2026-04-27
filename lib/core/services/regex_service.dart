/// Match individuel exporté par RegexService.
class RegexMatchInfo {
  final int start;
  final int end;
  final String text;
  final List<String?> groups;

  const RegexMatchInfo({
    required this.start,
    required this.end,
    required this.text,
    required this.groups,
  });
}

/// Service pur d'évaluation d'expressions régulières.
class RegexService {
  const RegexService();

  /// Compile une regex avec les options demandées. Lance [FormatException]
  /// si la regex est invalide.
  RegExp compile(
    String pattern, {
    bool multiLine = false,
    bool caseSensitive = true,
    bool unicode = false,
    bool dotAll = false,
  }) {
    try {
      return RegExp(
        pattern,
        multiLine: multiLine,
        caseSensitive: caseSensitive,
        unicode: unicode,
        dotAll: dotAll,
      );
    } on FormatException catch (e) {
      throw FormatException('Regex invalide : ${e.message}');
    }
  }

  /// Retourne tous les matchs d'un pattern dans une chaîne.
  List<RegexMatchInfo> findAll(
    String pattern,
    String input, {
    bool multiLine = false,
    bool caseSensitive = true,
    bool unicode = false,
    bool dotAll = false,
  }) {
    final re = compile(
      pattern,
      multiLine: multiLine,
      caseSensitive: caseSensitive,
      unicode: unicode,
      dotAll: dotAll,
    );
    final matches = re.allMatches(input);
    return matches
        .map((m) {
          final groups = <String?>[];
          for (var i = 0; i <= m.groupCount; i++) {
            groups.add(m.group(i));
          }
          return RegexMatchInfo(
            start: m.start,
            end: m.end,
            text: m.group(0) ?? '',
            groups: groups,
          );
        })
        .toList(growable: false);
  }

  /// Remplace tous les matchs (compatible groupes `$1`, `$2`).
  String replaceAll(
    String pattern,
    String input,
    String replacement, {
    bool multiLine = false,
    bool caseSensitive = true,
  }) {
    final re = compile(
      pattern,
      multiLine: multiLine,
      caseSensitive: caseSensitive,
    );
    return input.replaceAllMapped(re, (m) {
      var out = replacement;
      for (var i = 0; i <= m.groupCount; i++) {
        out = out.replaceAll('\$$i', m.group(i) ?? '');
      }
      return out;
    });
  }
}
