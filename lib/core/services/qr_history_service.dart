import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum QrContentType { text, url, wifi, vcard, email, phone }

class ParsedQrData {
  final QrContentType type;
  final String raw;
  final String? ssid;
  final String? password;
  final String? security;
  final String? email;
  final String? phone;
  final String? url;
  final String? fullName;

  const ParsedQrData({
    required this.type,
    required this.raw,
    this.ssid,
    this.password,
    this.security,
    this.email,
    this.phone,
    this.url,
    this.fullName,
  });

  String get typeLabel => switch (type) {
    QrContentType.url => 'Lien URL',
    QrContentType.wifi => 'Réseau Wi-Fi',
    QrContentType.vcard => 'Contact vCard',
    QrContentType.email => 'E-mail',
    QrContentType.phone => 'Téléphone',
    QrContentType.text => 'Texte',
  };
}

class QrHistoryEntry {
  final String id;
  final String data;
  final QrContentType type;
  final bool isScanned;
  final DateTime createdAt;

  const QrHistoryEntry({
    required this.id,
    required this.data,
    required this.type,
    required this.isScanned,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': data,
    'type': type.name,
    'isScanned': isScanned,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory QrHistoryEntry.fromJson(Map<String, dynamic> json) {
    final typeName = json['type']?.toString() ?? 'text';
    final resolvedType = QrContentType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => QrContentType.text,
    );
    return QrHistoryEntry(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      data: json['data']?.toString() ?? '',
      type: resolvedType,
      isScanned: json['isScanned'] == true,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}

class QrHistoryService {
  const QrHistoryService();

  static const String historyKey = 'qr_history_v1';
  static const int maxEntries = 50;
  static int _idCounter = 0;

  static Future<SharedPreferences> _preferences(
    SharedPreferences? preferences,
  ) async => preferences ?? SharedPreferences.getInstance();

  String _escapeWifi(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll(':', r'\:')
        .replaceAll('"', r'\"');
  }

  String _unescapeWifi(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      if (value[i] == r'\' && i + 1 < value.length) {
        buffer.write(value[i + 1]);
        i++;
      } else {
        buffer.write(value[i]);
      }
    }
    return buffer.toString();
  }

  String buildWifiPayload({
    required String ssid,
    required String password,
    String security = 'WPA',
    bool hidden = false,
  }) {
    final cleanSsid = ssid.trim();
    if (cleanSsid.isEmpty) return '';
    final normalizedSecurity = switch (security.toUpperCase()) {
      'WEP' => 'WEP',
      'NOPASS' || 'NONE' => 'nopass',
      _ => 'WPA',
    };
    final parts = <String>[
      'T:$normalizedSecurity',
      'S:${_escapeWifi(cleanSsid)}',
      if (normalizedSecurity != 'nopass' && password.isNotEmpty)
        'P:${_escapeWifi(password)}',
      if (hidden) 'H:true',
    ];
    return 'WIFI:${parts.join(';')};;';
  }

  String buildVCardPayload({
    required String fullName,
    String phone = '',
    String email = '',
    String org = '',
    String url = '',
  }) {
    final name = fullName.trim();
    if (name.isEmpty) return '';
    final lines = <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'FN:$name',
      if (org.trim().isNotEmpty) 'ORG:${org.trim()}',
      if (phone.trim().isNotEmpty) 'TEL;TYPE=CELL:${phone.trim()}',
      if (email.trim().isNotEmpty) 'EMAIL:${email.trim()}',
      if (url.trim().isNotEmpty) 'URL:${url.trim()}',
      'END:VCARD',
    ];
    return lines.join('\n');
  }

  String buildEmailPayload({
    required String to,
    String subject = '',
    String body = '',
  }) {
    final address = to.trim();
    if (address.isEmpty) return '';
    final params = <String, String>{};
    if (subject.trim().isNotEmpty) params['subject'] = subject.trim();
    if (body.trim().isNotEmpty) params['body'] = body.trim();
    final uri = Uri(
      scheme: 'mailto',
      path: address,
      queryParameters: params.isEmpty ? null : params,
    );
    return uri.toString().replaceAll('+', '%20');
  }

  ParsedQrData parseQrData(String raw) {
    final trimmed = raw.trim();
    final upper = trimmed.toUpperCase();

    if (upper.startsWith('WIFI:')) {
      final body = trimmed.substring(5);
      final fields = <String, String>{};
      final token = StringBuffer();
      var escaped = false;
      for (var i = 0; i < body.length; i++) {
        final ch = body[i];
        if (escaped) {
          token.write(r'\');
          token.write(ch);
          escaped = false;
        } else if (ch == r'\') {
          escaped = true;
        } else if (ch == ';') {
          _storeWifiField(fields, token.toString());
          token.clear();
        } else {
          token.write(ch);
        }
      }
      _storeWifiField(fields, token.toString());
      return ParsedQrData(
        type: QrContentType.wifi,
        raw: trimmed,
        ssid: fields['S'],
        password: fields['P'],
        security: fields['T'] ?? 'WPA',
      );
    }

    if (upper.startsWith('BEGIN:VCARD')) {
      String? fullName;
      String? phone;
      String? email;
      String? url;
      for (final line in trimmed.split(RegExp(r'\r?\n'))) {
        final lineUpper = line.toUpperCase();
        if (lineUpper.startsWith('FN:')) {
          fullName = line.substring(3).trim();
        } else if (lineUpper.startsWith('TEL')) {
          final idx = line.indexOf(':');
          if (idx >= 0) phone ??= line.substring(idx + 1).trim();
        } else if (lineUpper.startsWith('EMAIL')) {
          final idx = line.indexOf(':');
          if (idx >= 0) email ??= line.substring(idx + 1).trim();
        } else if (lineUpper.startsWith('URL')) {
          final idx = line.indexOf(':');
          if (idx >= 0) url ??= line.substring(idx + 1).trim();
        }
      }
      return ParsedQrData(
        type: QrContentType.vcard,
        raw: trimmed,
        fullName: fullName,
        phone: phone,
        email: email,
        url: url,
      );
    }

    if (upper.startsWith('MAILTO:')) {
      final uri = Uri.tryParse(trimmed);
      return ParsedQrData(
        type: QrContentType.email,
        raw: trimmed,
        email: uri?.path.isNotEmpty == true ? uri!.path : trimmed.substring(7),
        url: trimmed,
      );
    }

    if (upper.startsWith('TEL:')) {
      return ParsedQrData(
        type: QrContentType.phone,
        raw: trimmed,
        phone: trimmed.substring(4).trim(),
        url: trimmed,
      );
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty) {
      return ParsedQrData(type: QrContentType.url, raw: trimmed, url: trimmed);
    }

    return ParsedQrData(type: QrContentType.text, raw: trimmed);
  }

  void _storeWifiField(Map<String, String> fields, String segment) {
    final idx = segment.indexOf(':');
    if (idx <= 0) return;
    final key = segment.substring(0, idx).toUpperCase();
    final value = _unescapeWifi(segment.substring(idx + 1));
    fields[key] = value;
  }

  List<QrHistoryEntry> decodeHistoryList(dynamic rawList) {
    if (rawList is! List) return [];
    final entries = <QrHistoryEntry>[];
    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        entries.add(QrHistoryEntry.fromJson(item));
      } else if (item is Map) {
        entries.add(
          QrHistoryEntry.fromJson(
            item.map((k, v) => MapEntry(k.toString(), v)),
          ),
        );
      }
    }
    return entries;
  }

  Future<List<QrHistoryEntry>> load({SharedPreferences? preferences}) async {
    final prefs = await _preferences(preferences);
    final raw = prefs.getString(historyKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return decodeHistoryList(json.decode(raw));
    } catch (_) {
      return [];
    }
  }

  Future<List<QrHistoryEntry>> add(
    String data, {
    required bool isScanned,
    SharedPreferences? preferences,
  }) async {
    final trimmed = data.trim();
    if (trimmed.isEmpty) return load(preferences: preferences);

    final prefs = await _preferences(preferences);
    final list = await load(preferences: prefs);
    list.removeWhere((e) => e.data == trimmed && e.isScanned == isScanned);
    final parsed = parseQrData(trimmed);
    final now = DateTime.now();
    final entry = QrHistoryEntry(
      id: '${now.microsecondsSinceEpoch}_${_idCounter++}',
      data: trimmed,
      type: parsed.type,
      isScanned: isScanned,
      createdAt: now,
    );
    list.insert(0, entry);
    final capped = list.take(maxEntries).toList();
    await prefs.setString(
      historyKey,
      json.encode(capped.map((e) => e.toJson()).toList()),
    );
    return capped;
  }

  Future<List<QrHistoryEntry>> remove(
    String id, {
    SharedPreferences? preferences,
  }) async {
    final prefs = await _preferences(preferences);
    final list = await load(preferences: prefs);
    list.removeWhere((e) => e.id == id);
    await prefs.setString(
      historyKey,
      json.encode(list.map((e) => e.toJson()).toList()),
    );
    return list;
  }

  Future<void> clear({SharedPreferences? preferences}) async {
    final prefs = await _preferences(preferences);
    await prefs.remove(historyKey);
  }
}
