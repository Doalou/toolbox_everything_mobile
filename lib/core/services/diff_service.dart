/// Type d'opération sur une ligne du diff.
enum DiffOp { keep, add, remove }

/// Représente une ligne dans le résultat d'un diff.
class DiffLine {
  final DiffOp op;
  final String text;
  const DiffLine(this.op, this.text);
}

/// Service pur de diff ligne-à-ligne, basé sur l'algorithme LCS classique.
/// Les performances sont O(n × m), suffisantes pour des entrées de taille
/// raisonnable (texte/code court).
class DiffService {
  const DiffService();

  List<DiffLine> diff(String oldText, String newText) {
    final a = oldText.split('\n');
    final b = newText.split('\n');

    // Table de programmation dynamique pour la LCS
    final n = a.length;
    final m = b.length;
    final dp = List<List<int>>.generate(
      n + 1,
      (_) => List<int>.filled(m + 1, 0),
      growable: false,
    );
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < m; j++) {
        if (a[i] == b[j]) {
          dp[i + 1][j + 1] = dp[i][j] + 1;
        } else {
          dp[i + 1][j + 1] = dp[i + 1][j] > dp[i][j + 1]
              ? dp[i + 1][j]
              : dp[i][j + 1];
        }
      }
    }

    // Backtrack
    final lines = <DiffLine>[];
    var i = n;
    var j = m;
    while (i > 0 && j > 0) {
      if (a[i - 1] == b[j - 1]) {
        lines.insert(0, DiffLine(DiffOp.keep, a[i - 1]));
        i--;
        j--;
      } else if (dp[i - 1][j] >= dp[i][j - 1]) {
        lines.insert(0, DiffLine(DiffOp.remove, a[i - 1]));
        i--;
      } else {
        lines.insert(0, DiffLine(DiffOp.add, b[j - 1]));
        j--;
      }
    }
    while (i > 0) {
      lines.insert(0, DiffLine(DiffOp.remove, a[i - 1]));
      i--;
    }
    while (j > 0) {
      lines.insert(0, DiffLine(DiffOp.add, b[j - 1]));
      j--;
    }
    return lines;
  }

  /// Renvoie un résumé : (ajouts, suppressions).
  ({int added, int removed}) summary(List<DiffLine> lines) {
    var added = 0, removed = 0;
    for (final l in lines) {
      if (l.op == DiffOp.add) added++;
      if (l.op == DiffOp.remove) removed++;
    }
    return (added: added, removed: removed);
  }
}
