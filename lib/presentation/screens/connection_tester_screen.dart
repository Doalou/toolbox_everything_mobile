import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_shapes.dart';
import 'package:toolbox_everything_mobile/core/design/expressive_tokens.dart';
import 'package:toolbox_everything_mobile/core/services/app_feedback.dart';
import 'package:toolbox_everything_mobile/core/services/network_diagnostic_service.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_components.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_action_button.dart';
import 'package:toolbox_everything_mobile/shared/widgets/expressive_card.dart';
import 'package:toolbox_everything_mobile/shared/widgets/status_badge.dart';

class ConnectionTesterScreen extends StatefulWidget {
  final String heroTag;

  const ConnectionTesterScreen({super.key, required this.heroTag});

  @override
  State<ConnectionTesterScreen> createState() => _ConnectionTesterScreenState();
}

class _ConnectionTesterScreenState extends State<ConnectionTesterScreen> {
  final NetworkDiagnosticService _diagnosticService =
      const NetworkDiagnosticService();

  bool _isTesting = false;
  bool _hasInternet = false;
  String _ipv4 = 'Non détecté';
  String _ipv6 = 'Non détecté';
  String _location = 'Non détecté';
  String _isp = 'Non détecté';
  double _pingTime = 0.0;
  double _downloadSpeed = 0.0;
  String _connectionType = 'Non détecté';
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _runConnectionTest();

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      setState(() {
        _connectionType = _labelForConnectivity(result);
      });
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  String _labelForConnectivity(ConnectivityResult result) => switch (result) {
    ConnectivityResult.wifi => 'Wi-Fi',
    ConnectivityResult.mobile => 'Données mobiles',
    ConnectivityResult.ethernet => 'Ethernet',
    ConnectivityResult.vpn => 'VPN',
    ConnectivityResult.bluetooth => 'Bluetooth',
    ConnectivityResult.other => 'Autre',
    ConnectivityResult.satellite => 'Satellite',
    ConnectivityResult.none => 'Non connecté',
  };

  Future<void> _runConnectionTest() async {
    setState(() {
      _isTesting = true;
      _hasInternet = false;
      _ipv4 = 'Test en cours…';
      _ipv6 = 'Test en cours…';
      _location = 'Test en cours…';
      _isp = 'Test en cours…';
      _pingTime = 0.0;
      _downloadSpeed = 0.0;
      _connectionType = 'Test en cours…';
    });

    try {
      final resultsConnectivity = await Connectivity().checkConnectivity();
      final connectivityResult = resultsConnectivity.isNotEmpty
          ? resultsConnectivity.first
          : ConnectivityResult.none;
      final connectionType = _labelForConnectivity(connectivityResult);

      final diagnostic = await _diagnosticService.runDiagnostics();

      if (mounted) {
        setState(() {
          _isTesting = false;
          _hasInternet = diagnostic.hasInternet;
          _ipv4 = diagnostic.ipv4;
          _ipv6 = diagnostic.ipv6;
          _location = diagnostic.location;
          _isp = diagnostic.isp;
          _pingTime = diagnostic.pingMs;
          _downloadSpeed = diagnostic.downloadSpeedKbps;
          _connectionType = connectionType;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _hasInternet = false;
          _ipv4 = 'Non disponible';
          _ipv6 = 'Non disponible';
          _location = 'Non disponible';
          _isp = 'Non disponible';
          _pingTime = 0.0;
          _downloadSpeed = 0.0;
          _connectionType = 'Non connecté';
        });

        AppFeedback.show(context, _friendlyError(e), tone: FeedbackTone.error);
      }
    }
  }

  String _friendlyError(Object error) {
    if (error is TimeoutException) {
      return 'Le diagnostic réseau a expiré. Vérifiez la connexion puis réessayez.';
    }
    if (error is NetworkDiagnosticException) return error.message;
    return 'Le diagnostic réseau est indisponible pour le moment.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return EditorialToolScaffold(
      title: 'Testeur de connexion',
      heroTag: widget.heroTag,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EditorialToolIntro(
              icon: _hasInternet ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              title: 'Statut de la connexion',
              description: _isTesting
                  ? 'Analyse de la connectivité et de la latence…'
                  : _hasInternet
                  ? 'Connecté à Internet ($_connectionType)'
                  : 'Aucune connexion Internet confirmée',
              accent: _hasInternet ? colorScheme.tertiary : colorScheme.primary,
              trailing: StatusBadge(
                label: _isTesting
                    ? 'Test…'
                    : _hasInternet
                    ? 'En ligne'
                    : 'Hors ligne',
                tone: _isTesting
                    ? BadgeTone.accent
                    : _hasInternet
                    ? BadgeTone.success
                    : BadgeTone.danger,
              ),
            ),
            const SizedBox(height: 16),
            ExpressiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(
                            ExpressiveShapes.small,
                          ),
                        ),
                        child: Icon(
                          Icons.language_rounded,
                          color: colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Adresses IP publiques',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildKeyValue('IPv4', _ipv4)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildKeyValue('IPv6', _ipv6)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              'Localisation',
              _location,
              Icons.location_on_rounded,
              ExpressivePalette.lemonZest,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              'Fournisseur Internet',
              _isp,
              Icons.business_rounded,
              ExpressivePalette.amberWarm,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              'Type de connexion',
              _connectionType,
              Icons.router_rounded,
              ExpressivePalette.tealOptimist,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Ping HTTP',
                    '${_pingTime.toStringAsFixed(0)} ms',
                    Icons.speed_rounded,
                    ExpressivePalette.tealOptimist,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Débit mesuré',
                    '${_downloadSpeed.toStringAsFixed(1)} KB/s',
                    Icons.download_rounded,
                    ExpressivePalette.violetVibrant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ExpressiveActionButton.iconLabel(
              icon: Icons.refresh_rounded,
              label: _isTesting ? 'Test en cours…' : 'Relancer le diagnostic',
              loading: _isTesting,
              onPressed: _isTesting ? null : _runConnectionTest,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color seedColor,
  ) {
    final baseScheme = Theme.of(context).colorScheme;
    final cardScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: baseScheme.brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );

    return ExpressiveCard(
      dense: true,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cardScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(ExpressiveShapes.medium),
            ),
            child: Icon(icon, color: cardScheme.onSecondaryContainer, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
    Color seedColor,
  ) {
    final baseScheme = Theme.of(context).colorScheme;
    final metricScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: baseScheme.brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );

    return ExpressiveCard(
      color: metricScheme.primaryContainer.withValues(
        alpha: baseScheme.brightness == Brightness.dark ? 0.42 : 0.65,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: ShapeDecoration(
              color: metricScheme.primary.withValues(alpha: 0.16),
              shape: const StadiumBorder(),
            ),
            child: Icon(icon, color: metricScheme.primary, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: metricScheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: metricScheme.onPrimaryContainer,
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
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(ExpressiveShapes.medium),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: cs.primary),
          ),
          const SizedBox(height: 6),
          SelectableText(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
