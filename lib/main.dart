import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  await NotificationService.instance.initialize();
  // Optimisation mémoire pour appareils low-cost
  painting.imageCache.maximumSize = 100; // nombre max d'images en cache
  painting.imageCache.maximumSizeBytes = 50 << 20; // ~50 Mo
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
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
        return MaterialApp(
          title: 'Toolbox Everything',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          scrollBehavior: const NoGlowScrollBehavior(),
          home: const HomeScreen(),
        );
      },
    );
  }
}
