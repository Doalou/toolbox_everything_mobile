import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';
import 'package:toolbox_everything_mobile/core/providers/theme_provider.dart';
import 'package:toolbox_everything_mobile/presentation/screens/home_screen.dart';
import 'package:toolbox_everything_mobile/shared/widgets/tool_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHome(
    WidgetTester tester, {
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
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
          theme: themeProvider.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('l’accueil éditorial construit le catalogue', (tester) async {
    await pumpHome(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Catégories'), findsOneWidget);
    expect(
      find.textContaining('Tous vos outils', findRichText: true),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('la recherche filtre les outils', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byTooltip('Rechercher'));
    await tester.pump();
    await tester.enterText(find.byType(SearchBar), 'UUID');
    await tester.pump();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
    await tester.pumpAndSettle();

    expect(find.text('UUID'), findsOneWidget);
    expect(find.byType(ExpressiveToolCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('l’accueil reste utilisable sur tablette avec grand texte', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpHome(tester, textScaler: const TextScaler.linear(1.6));

    expect(find.text('Catégories'), findsOneWidget);
    expect(
      find.textContaining('Tous vos outils', findRichText: true),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
