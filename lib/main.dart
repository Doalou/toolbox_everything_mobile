import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/providers/downloader_provider.dart';
import 'package:toolbox_everything_mobile/core/providers/theme_provider.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';
import 'package:toolbox_everything_mobile/presentation/screens/home_screen.dart';
import 'package:toolbox_everything_mobile/core/services/notification_service.dart';
import 'package:flutter/painting.dart' as painting;

class NoGlowScrollBehavior extends ScrollBehavior {
  const NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // Supprime l'effet de glow d'overscroll
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Uniformise le comportement de scroll (sans rebond)
    return const ClampingScrollPhysics();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation asynchrone des services et préférences
  final prefs = await SharedPreferences.getInstance();
  await NotificationService.instance.initialize();
  // Optimisation mémoire pour appareils low-cost
  painting.imageCache.maximumSize = 100; // nombre max d'images en cache
  painting.imageCache.maximumSizeBytes = 50 << 20; // ~50 Mo
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(prefs),
        ),
        ChangeNotifierProvider(create: (_) => DownloaderProvider()..initialize()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            final useDynamic = themeProvider.useDynamicColor;
            final ThemeData lightTheme = useDynamic && lightDynamic != null
                ? themeProvider.lightTheme.copyWith(
                    colorScheme: lightDynamic.harmonized(),
                  )
                : themeProvider.lightTheme;
            final ThemeData darkTheme = useDynamic && darkDynamic != null
                ? themeProvider.darkTheme.copyWith(
                    colorScheme: darkDynamic.harmonized(),
                  )
                : themeProvider.darkTheme;

            return MaterialApp(
              title: 'Toolbox Everything',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeProvider.themeMode,
              themeAnimationDuration: Duration.zero,
              themeAnimationCurve: Curves.linear,
              scrollBehavior: const NoGlowScrollBehavior(),
              home: const HomeScreen(),
            );
          },
        );
      },
    );
  }
}
