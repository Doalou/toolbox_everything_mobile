import 'dart:convert';

/// Représentation décodée d'un JWT.
class DecodedJwt {
  final Map<String, dynamic> header;
  final Map<String, dynamic> payload;
  final String signature;

  const DecodedJwt({
    required this.header,
    required this.payload,
    required this.signature,
  });

  /// Date d'expiration parsée depuis le claim `exp` (epoch seconds).
  DateTime? get expiresAt {
    final exp = payload['exp'];
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    }
    return null;
  }

  /// Date d'émission parsée depuis le claim `iat`.
  DateTime? get issuedAt {
    final iat = payload['iat'];
    if (iat is int) {
      return DateTime.fromMillisecondsSinceEpoch(iat * 1000, isUtc: true);
    }
    return null;
  }

  /// Vrai si `exp` est dans le passé.
  bool get isExpired {
    final exp = expiresAt;
    if (exp == null) return false;
    return DateTime.now().toUtc().isAfter(exp);
  }
}

/// Décode un JWT **sans** vérifier la signature.
///
/// Limites volontaires :
/// - Aucune validation cryptographique.
/// - Convient pour l'inspection / debug uniquement.
class JwtService {
  const JwtService();

  DecodedJwt decode(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('JWT invalide : 3 segments attendus');
    }
    final header = _decodeSegment(parts[0]);
    final payload = _decodeSegment(parts[1]);
    return DecodedJwt(header: header, payload: payload, signature: parts[2]);
  }

  Map<String, dynamic> _decodeSegment(String seg) {
    final normalized = base64.normalize(
      seg.replaceAll('-', '+').replaceAll('_', '/'),
    );
    final bytes = base64.decode(normalized);
    final str = utf8.decode(bytes);
    final dynamic parsed = json.decode(str);
    if (parsed is Map<String, dynamic>) return parsed;
    throw const FormatException('Segment JWT non-JSON');
  }
}
