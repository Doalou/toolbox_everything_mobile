import 'package:flutter/material.dart';
// Animations retirées pour alléger l'écran et éviter les saccades
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectionTesterScreen extends StatefulWidget {
  const ConnectionTesterScreen({super.key});

  @override
  State<ConnectionTesterScreen> createState() => _ConnectionTesterScreenState();
}

class _ConnectionTesterScreenState extends State<ConnectionTesterScreen>
    with TickerProviderStateMixin {
  bool _isTesting = false;
  bool _hasInternet = false;
  String _ipAddress = 'Non détecté';
  String _ipv4 = 'Non détecté';
  String _ipv6 = 'Non détecté';
  String _location = 'Non détecté';
  String _isp = 'Non détecté';
  double _pingTime = 0.0;
  double _downloadSpeed = 0.0;
  String _connectionType = 'Non détecté';
  Stream<List<ConnectivityResult>>? _connectivityStream;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    // Test automatique au démarrage
    _runConnectionTest();

    // Ecoute en direct du type de connexion
    _connectivityStream = Connectivity().onConnectivityChanged;
    _connectivitySub = _connectivityStream!.listen((results) {
      if (!mounted) return;
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      setState(() {
        switch (result) {
          case ConnectivityResult.wifi:
            _connectionType = 'WiFi';
            break;
          case ConnectivityResult.mobile:
            _connectionType = 'Données mobiles';
            break;
          case ConnectivityResult.ethernet:
            _connectionType = 'Ethernet';
            break;
          case ConnectivityResult.vpn:
            _connectionType = 'VPN';
            break;
          case ConnectivityResult.bluetooth:
            _connectionType = 'Bluetooth';
            break;
          case ConnectivityResult.other:
            _connectionType = 'Autre';
            break;
          case ConnectivityResult.none:
            _connectionType = 'Non connecté';
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _runConnectionTest() async {
    setState(() {
      _isTesting = true;
      _hasInternet = false;
      _ipAddress = 'Test en cours...';
      _ipv4 = 'Test en cours...';
      _ipv6 = 'Test en cours...';
      _location = 'Test en cours...';
      _isp = 'Test en cours...';
      _pingTime = 0.0;
      _downloadSpeed = 0.0;
      _connectionType = 'Test en cours...';
    });

    try {
      // Test de connectivité (peut retourner plusieurs types simultanés)
      final resultsConnectivity = await Connectivity().checkConnectivity();
      final connectivityResult = resultsConnectivity.isNotEmpty
          ? resultsConnectivity.first
          : ConnectivityResult.none;
      String connectionType = 'Non connecté';

      switch (connectivityResult) {
        case ConnectivityResult.wifi:
          connectionType = 'WiFi';
          break;
        case ConnectivityResult.mobile:
          connectionType = 'Données mobiles';
          break;
        case ConnectivityResult.ethernet:
          connectionType = 'Ethernet';
          break;
        case ConnectivityResult.vpn:
          connectionType = 'VPN';
          break;
        case ConnectivityResult.bluetooth:
          connectionType = 'Bluetooth';
          break;
        case ConnectivityResult.other:
          connectionType = 'Autre';
          break;
        case ConnectivityResult.none:
          connectionType = 'Non connecté';
          break;
      }

      // Test de ping
      double pingTime = await _testPing();

      // Récupération de l'IP et informations
      final ipInfoFuture = _getIpInfo();
      final ipv4Future = _getIPv4();
      final ipv6Future = _getIPv6();
      final ipInfo = await ipInfoFuture;
      final ipResults = await Future.wait<String>([ipv4Future, ipv6Future]);
      final ipv4 = ipResults[0];
      final ipv6 = ipResults[1];

      // Test de vitesse de téléchargement
      double downloadSpeed = await _testDownloadSpeed();

      if (mounted) {
        setState(() {
          _isTesting = false;
          _hasInternet = true;
          _ipv4 = ipv4;
          _ipv6 = ipv6;
          _ipAddress = 'IPv4: $ipv4\nIPv6: $ipv6';
          _location = ipInfo['location'] ?? 'Non détecté';
          _isp = ipInfo['isp'] ?? 'Non détecté';
          _pingTime = pingTime;
          _downloadSpeed = downloadSpeed;
          _connectionType = connectionType;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _hasInternet = false;
          _ipAddress = 'Erreur de connexion';
          _location = 'Non disponible';
          _isp = 'Non disponible';
          _pingTime = 0.0;
          _downloadSpeed = 0.0;
          _connectionType = 'Non connecté';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de test: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<String> _getIPv4() async {
    final endpoints = <String>[
      'https://api.ipify.org',
      'https://ipv4.icanhazip.com',
      'https://v4.ident.me',
    ];
    for (final url in endpoints) {
      try {
        final res = await http
            .get(Uri.parse(url), headers: {'User-Agent': 'ToolboxEverything/1.0'})
            .timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final text = res.body.trim();
          if (_looksLikeIPv4(text)) return text;
        }
      } catch (_) {}
    }
    return 'Non disponible';
  }

  Future<String> _getIPv6() async {
    final endpoints = <String>[
      'https://api64.ipify.org',
      'https://ipv6.icanhazip.com',
      'https://v6.ident.me',
    ];
    for (final url in endpoints) {
      try {
        final res = await http
            .get(Uri.parse(url), headers: {'User-Agent': 'ToolboxEverything/1.0'})
            .timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final text = res.body.trim();
          if (_looksLikeIPv6(text)) return text;
        }
      } catch (_) {}
    }
    return 'Non disponible';
  }

  bool _looksLikeIPv4(String s) {
    // Simple validation IPv4
    final parts = s.split('.');
    if (parts.length != 4) return false;
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n < 0 || n > 255) return false;
    }
    return true;
  }

  bool _looksLikeIPv6(String s) {
    // Validation grossière IPv6: présence de ':' et caractères hex
    if (!s.contains(':')) return false;
    final hex = RegExp(r'^[0-9a-fA-F:]+$');
    return hex.hasMatch(s);
  }

  Future<double> _testPing() async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(
            Uri.parse('https://www.google.com'),
            headers: {'User-Agent': 'ToolboxEverything/1.0'},
          )
          .timeout(const Duration(seconds: 10));
      stopwatch.stop();

      if (response.statusCode == 200) {
        return stopwatch.elapsedMilliseconds.toDouble();
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<Map<String, String>> _getIpInfo() async {
    // Essaye plusieurs fournisseurs pour maximiser les chances en conditions réelles
    // 1) ipapi.co
    try {
      final res = await http
          .get(
            Uri.parse('https://ipapi.co/json/'),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'ToolboxEverything/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return {
          'ip': data['ip'] ?? 'Non détecté',
          'location': '${data['city'] ?? ''}, ${data['country_name'] ?? ''}',
          'isp': data['org'] ?? 'Non détecté',
        };
      }
    } catch (_) {}

    // 2) ipwho.is
    try {
      final res = await http
          .get(
            Uri.parse('https://ipwho.is/'),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'ToolboxEverything/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true || data['ip'] != null) {
          final conn = data['connection'] as Map<String, dynamic>?;
          return {
            'ip': (data['ip'] ?? 'Non détecté').toString(),
            'location': '${data['city'] ?? ''}, ${data['country'] ?? ''}',
            'isp': (conn != null ? conn['isp'] : null) ?? 'Non détecté',
          };
        }
      }
    } catch (_) {}

    // 3) ipinfo.io
    try {
      final res = await http
          .get(
            Uri.parse('https://ipinfo.io/json'),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'ToolboxEverything/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return {
          'ip': data['ip'] ?? 'Non détecté',
          'location': '${data['city'] ?? ''}, ${data['country'] ?? ''}',
          'isp': data['org'] ?? 'Non détecté',
        };
      }
    } catch (_) {}

    // 4) ifconfig.co (ip seulement)
    try {
      final res = await http
          .get(
            Uri.parse('https://ifconfig.co/json'),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'ToolboxEverything/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return {
          'ip': data['ip'] ?? 'Non détecté',
          'location': 'Non disponible',
          'isp': data['asn_org'] ?? 'Non détecté',
        };
      }
    } catch (_) {}

    // Fallback final
    return {
      'ip': 'Non détecté',
      'location': 'Non disponible',
      'isp': 'Non disponible',
    };
  }

  Future<double> _testDownloadSpeed() async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(Uri.parse('https://httpbin.org/bytes/100000'))
          .timeout(const Duration(seconds: 10));
      stopwatch.stop();

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes.length;
        final seconds = stopwatch.elapsedMilliseconds / 1000;
        return (bytes / 1024) / seconds; // KB/s
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Testeur de Connexion'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête simplifiée (fond plein)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      _hasInternet ? Icons.wifi : Icons.wifi_off,
                      size: 32,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Statut de la connexion',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hasInternet ? 'Connecté à Internet' : 'Non connecté',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Informations IP (IPv4 + IPv6 affichées côte à côte)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.language, color: Colors.blue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adresses IP publiques',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _buildKeyValue('IPv4', _ipv4),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildKeyValue('IPv6', _ipv6),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Localisation
              _buildInfoCard(
                'Localisation',
                _location,
                Icons.location_on,
                Colors.orange,
              ),

              const SizedBox(height: 16),

              // FAI
              _buildInfoCard(
                'Fournisseur Internet',
                _isp,
                Icons.business,
                Colors.purple,
              ),

              const SizedBox(height: 16),

              // Type de connexion
              _buildInfoCard(
                'Type de connexion',
                _connectionType,
                Icons.router,
                Colors.teal,
              ),

              const SizedBox(height: 24),

              // Métriques de performance
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Ping',
                      '${_pingTime.toStringAsFixed(0)} ms',
                      Icons.speed,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      'Vitesse',
                      '${_downloadSpeed.toStringAsFixed(1)} KB/s',
                      Icons.download,
                      Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Bouton de test
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isTesting ? null : _runConnectionTest,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _isTesting ? 'Test en cours...' : 'Relancer le test',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValue(String key, String value) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
