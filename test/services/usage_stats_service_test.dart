import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/services/usage_stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'tool_usage_stats': jsonEncode({'QR Code': 3, 'Ancien outil': 2}),
      'favorite_tools': ['QR Code', 'Ancien outil'],
    });
  });

  test(
    'migre favoris et statistiques des titres vers les identifiants',
    () async {
      final preferences = await SharedPreferences.getInstance();

      await UsageStatsService.migrateLegacyData({
        'QR Code': 'qr-code',
      }, preferences: preferences);

      expect(await UsageStatsService.loadFavorites(preferences: preferences), [
        'qr-code',
      ]);
      expect(await UsageStatsService.getUsageStats(preferences: preferences), {
        'qr-code': 3,
      });
    },
  );

  test(
    'la migration est idempotente et les nouveaux compteurs progressent',
    () async {
      final preferences = await SharedPreferences.getInstance();
      const mapping = {'QR Code': 'qr-code'};

      await UsageStatsService.migrateLegacyData(
        mapping,
        preferences: preferences,
      );
      await UsageStatsService.recordToolUsage(
        'qr-code',
        preferences: preferences,
      );
      await UsageStatsService.migrateLegacyData(
        mapping,
        preferences: preferences,
      );

      expect(await UsageStatsService.getUsageStats(preferences: preferences), {
        'qr-code': 4,
      });
    },
  );
}
