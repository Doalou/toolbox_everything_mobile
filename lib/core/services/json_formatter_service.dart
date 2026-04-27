import 'dart:convert';

/// Service pur de formatage JSON. Aucune dépendance Flutter.
class JsonFormatterService {
  const JsonFormatterService();

  /// Formate un JSON avec une indentation donnée.
  /// Lance [FormatException] si l'entrée n'est pas un JSON valide.
  String prettify(String input, {int indent = 2}) {
    final dynamic parsed = json.decode(input);
    final encoder = JsonEncoder.withIndent(' ' * indent);
    return encoder.convert(parsed);
  }

  /// Compacte un JSON (supprime indentation et espaces superflus).
  String minify(String input) {
    final dynamic parsed = json.decode(input);
    return json.encode(parsed);
  }

  /// Indique si une chaîne est un JSON valide.
  bool isValid(String input) {
    if (input.trim().isEmpty) return false;
    try {
      json.decode(input);
      return true;
    } catch (_) {
      return false;
    }
  }
}
