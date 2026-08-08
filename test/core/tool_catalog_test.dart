import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';
import 'package:toolbox_everything_mobile/core/providers/theme_provider.dart';
import 'package:toolbox_everything_mobile/core/tool_catalog.dart';
import 'package:toolbox_everything_mobile/shared/widgets/editorial_tool_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('les identifiants du catalogue sont stables et uniques', () {
    final tools = ToolCatalog.all();
    final ids = tools.map((tool) => tool.id).toList();

    expect(ids, isNotEmpty);
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids, everyElement(matches(RegExp(r'^[a-z0-9-]+$'))));
    expect(ToolCatalog.legacyTitleToId, hasLength(tools.length));
  });

  test('chaque entrée expose un écran et un hero tag unique', () {
    final tools = ToolCatalog.all();
    final heroTags = tools.map((tool) => tool.heroTag).toSet();

    expect(heroTags, hasLength(tools.length));
    for (final tool in tools) {
      expect(() => tool.screenBuilder(tool.heroTag), returnsNormally);
    }
  });

  for (final tool in ToolCatalog.all()) {
    testWidgets('ouvre l’outil ${tool.id}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final themeProvider = ThemeProvider(preferences);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider(
              create: (_) => SettingsProvider(preferences),
            ),
          ],
          child: MaterialApp(
            theme: themeProvider.lightTheme,
            home: tool.screenBuilder(tool.heroTag),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(EditorialToolScaffold), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
