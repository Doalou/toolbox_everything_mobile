import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/design/editorial_tokens.dart';
import 'package:toolbox_everything_mobile/core/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('une nouvelle installation utilise la palette de marque', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = ThemeProvider(await SharedPreferences.getInstance());

    expect(provider.advancedCustomization, isFalse);
    expect(
      provider.lightTheme.colorScheme.primary,
      EditorialPalette.accentLight,
    );
    expect(
      provider.lightTheme.scaffoldBackgroundColor,
      EditorialPalette.paperLight,
    );
  });

  test('une ancienne préférence dynamique active le mode avancé', () async {
    SharedPreferences.setMockInitialValues({
      'pref_use_dynamic_color': true,
      'pref_seed_color': const Color(0xFFE0398B).toARGB32(),
    });
    final provider = ThemeProvider(await SharedPreferences.getInstance());

    expect(provider.advancedCustomization, isTrue);
    expect(provider.useDynamicColor, isTrue);

    provider.setAdvancedCustomization(false);
    expect(provider.useDynamicColor, isFalse);
    expect(provider.seedColor, EditorialPalette.accentLight);
  });
}
