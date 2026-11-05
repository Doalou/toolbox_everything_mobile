import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NetworkDiagnosticResult {
  final bool hasInternet;
  final String ipv4;
  final String ipv6;
  final String location;
  final String isp;
  final double pingMs;
  final double downloadSpeedKbps;

  const NetworkDiagnosticResult({
    required this.hasInternet,
    required this.ipv4,
    required this.ipv6,
    required this.location,
    required this.isp,
    required this.pingMs,
    required this.downloadSpeedKbps,
  });
}

class NetworkDiagnosticException implements Exception {
  final String message;
  const NetworkDiagnosticException(this.message);

  @override
  String toString() => message;
}

class NetworkDiagnosticService {
  static const Duration _requestTimeout = Duration(seconds: 4);
  static const Duration _totalTimeout = Duration(seconds: 18);

  final http.Client? client;

  const NetworkDiagnosticService({this.client});

  Future<http.Response> _get(Uri uri, {Map<String, String>? headers}) {
    final mergedHeaders = <String, String>{
      'User-Agent': 'ToolboxEverything/1.0',
      ...?headers,
    };
    final activeClient = client;
    if (activeClient != null) {
      return activeClient
          .get(uri, headers: mergedHeaders)
          .timeout(_requestTimeout);
    }
    return http.get(uri, headers: mergedHeaders).timeout(_requestTimeout);
  }

  Future<NetworkDiagnosticResult> runDiagnostics() async {
    final results = await Future.wait<Object>([
      testPing(),
      getIpInfo(),
      getIPv4(),
      getIPv6(),
      testDownloadSpeed(),
    ]).timeout(_totalTimeout);

    final pingMs = results[0] as double;
    final ipInfo = results[1] as Map<String, String>;
    final ipv4 = results[2] as String;
    final ipv6 = results[3] as String;
    final downloadSpeed = results[4] as double;

    final hasInternet =
        pingMs > 0 || ipv4 != 'Non disponible' || ipv6 != 'Non disponible';
    if (!hasInternet) {
      throw const NetworkDiagnosticException(
        'Aucun accès Internet n’a pu être confirmé.',
      );
    }

    return NetworkDiagnosticResult(
      hasInternet: hasInternet,
      ipv4: ipv4,
      ipv6: ipv6,
      location: ipInfo['location'] ?? 'Non détecté',
      isp: ipInfo['isp'] ?? 'Non détecté',
      pingMs: pingMs,
      downloadSpeedKbps: downloadSpeed,
    );
  }

  Future<String> getIPv4() async {
    const endpoints = <String>[
      'https://api.ipify.org',
      'https://ipv4.icanhazip.com',
      'https://v4.ident.me',
    ];
    for (final url in endpoints) {
      try {
        final res = await _get(Uri.parse(url));
        if (res.statusCode == 200) {
          final text = res.body.trim();
          if (looksLikeIPv4(text)) return text;
        }
      } catch (_) {}
    }
    return 'Non disponible';
  }

  Future<String> getIPv6() async {
    const endpoints = <String>[
      'https://api64.ipify.org',
      'https://ipv6.icanhazip.com',
      'https://v6.ident.me',
    ];
    for (final url in endpoints) {
      try {
        final res = await _get(Uri.parse(url));
        if (res.statusCode == 200) {
          final text = res.body.trim();
          if (looksLikeIPv6(text)) return text;
        }
      } catch (_) {}
    }
    return 'Non disponible';
  }

  bool looksLikeIPv4(String s) {
    final parts = s.split('.');
    if (parts.length != 4) return false;
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n < 0 || n > 255) return false;
    }
    return true;
  }

  bool looksLikeIPv6(String s) {
    if (!s.contains(':')) return false;
    final hex = RegExp(r'^[0-9a-fA-F:]+$');
    return hex.hasMatch(s);
  }

  Future<double> testPing() async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await _get(Uri.parse('https://www.google.com'));
      stopwatch.stop();

      if (response.statusCode == 200) {
        return stopwatch.elapsedMilliseconds.toDouble();
      }
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<Map<String, String>> getIpInfo() async {
    try {
      final res = await _get(
        Uri.parse('https://ipapi.co/json/'),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return {
          'ip': data['ip']?.toString() ?? 'Non détecté',
          'location': _formatLocation(data['city'], data['country_name']),
          'isp': data['org']?.toString() ?? 'Non détecté',
        };
      }
    } catch (_) {}

    try {
      final res = await _get(
        Uri.parse('https://ipwho.is/'),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true || data['ip'] != null) {
          final conn = data['connection'] as Map<String, dynamic>?;
          return {
            'ip': (data['ip'] ?? 'Non détecté').toString(),
            'location': _formatLocation(data['city'], data['country']),
            'isp':
                (conn != null ? conn['isp'] : null)?.toString() ??
                'Non détecté',
          };
        }
      }
    } catch (_) {}

    try {
      final res = await _get(
        Uri.parse('https://ipinfo.io/json'),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return {
          'ip': data['ip']?.toString() ?? 'Non détecté',
          'location': _formatLocation(data['city'], data['country']),
          'isp': data['org']?.toString() ?? 'Non détecté',
        };
      }
    } catch (_) {}

    try {
      final res = await _get(
        Uri.parse('https://ifconfig.co/json'),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return {
          'ip': data['ip']?.toString() ?? 'Non détecté',
          'location': 'Non disponible',
          'isp': data['asn_org']?.toString() ?? 'Non détecté',
        };
      }
    } catch (_) {}

    return {
      'ip': 'Non détecté',
      'location': 'Non disponible',
      'isp': 'Non disponible',
    };
  }

  String _formatLocation(dynamic city, dynamic country) {
    final c = city?.toString().trim() ?? '';
    final co = country?.toString().trim() ?? '';
    if (c.isNotEmpty && co.isNotEmpty) return '$c, $co';
    if (c.isNotEmpty) return c;
    if (co.isNotEmpty) return co;
    return 'Non détecté';
  }

  Future<double> testDownloadSpeed() async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await _get(
        Uri.parse('https://httpbin.org/bytes/100000'),
      );
      stopwatch.stop();

      if (response.statusCode == 200 && stopwatch.elapsedMilliseconds > 0) {
        final bytes = response.bodyBytes.length;
        final seconds = stopwatch.elapsedMilliseconds / 1000.0;
        return (bytes / 1024.0) / seconds;
      }
      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }
}
