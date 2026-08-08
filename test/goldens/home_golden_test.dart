import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';
import 'package:toolbox_everything_mobile/core/providers/theme_provider.dart';
import 'package:toolbox_everything_mobile/presentation/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpGolden(
    WidgetTester tester, {
    required Size size,
    required bool dark,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final themeProvider = ThemeProvider(preferences);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider(create: (_) => SettingsProvider(preferences)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final scenarios = <({String name, Size size, bool dark})>[
    (name: 'home_phone_light', size: const Size(390, 844), dark: false),
    (name: 'home_phone_dark', size: const Size(390, 844), dark: true),
    (name: 'home_tablet_light', size: const Size(1280, 800), dark: false),
    (name: 'home_tablet_dark', size: const Size(1280, 800), dark: true),
  ];

  for (final scenario in scenarios) {
    testWidgets('golden ${scenario.name}', (tester) async {
      await pumpGolden(tester, size: scenario.size, dark: scenario.dark);

      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('${scenario.name}.png'),
      );
    }, skip: !Platform.isWindows);
  }
}
