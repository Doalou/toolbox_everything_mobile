import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:toolbox_everything_mobile/core/services/youtube_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  group('YoutubeService.userMessage', () {
    test('explique une limitation temporaire', () {
      final message = YoutubeService.userMessage(
        RequestLimitExceededException('rate limited'),
      );

      expect(message, contains('limite temporairement'));
    });

    test('distingue une vidéo indisponible', () {
      final message = YoutubeService.userMessage(
        VideoUnavailableException('unavailable'),
      );

      expect(message, contains('privée, supprimée ou indisponible'));
    });

    test('traduit les erreurs 403 et les délais dépassés', () {
      final forbidden = YoutubeService.userMessage(
        YoutubeExplodeException('Video returned 403'),
      );
      final timeout = YoutubeService.userMessage(
        TimeoutException('stream stalled'),
      );

      expect(forbidden, contains('n’a pas délivré le flux'));
      expect(timeout, contains('n’a pas délivré le flux'));
    });

    test('ne divulgue pas une erreur interne inconnue', () {
      final message = YoutubeService.userMessage(StateError('secret details'));

      expect(message, 'Impossible de récupérer cette vidéo pour le moment.');
      expect(message, isNot(contains('secret details')));
    });
  });
}
