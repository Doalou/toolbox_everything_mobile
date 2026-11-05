import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/design/editorial_tokens.dart';
import 'package:toolbox_everything_mobile/core/feature_flags/app_feature_flags.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';
import 'package:toolbox_everything_mobile/core/providers/theme_provider.dart';
import 'package:toolbox_everything_mobile/core/services/quick_actions_service.dart';
import 'package:toolbox_everything_mobile/presentation/screens/home_screen.dart';

// Builder de transition de page personnalisé pour une animation de fondu et de glissement
class FadeUpwardsPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeUpwardsPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }
}

class NoGlowScrollBehavior extends ScrollBehavior {
  const NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return switch (getPlatform(context)) {
      TargetPlatform.iOS || TargetPlatform.macOS => const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      _ => const ClampingScrollPhysics(),
    };
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  // Optimisation mémoire pour appareils low-cost
  painting.imageCache.maximumSize = 100;
  painting.imageCache.maximumSizeBytes = 50 << 20; // ~50 Mo
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeDeferredServices());
    });
  }

  Future<void> _initializeDeferredServices() async {
    if (!AppFeatureFlags.quickActions) return;
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    try {
      await QuickActionsService.instance.initialize();
      QuickActionsService.instance.processPendingAction();
    } catch (_) {
      // Les raccourcis ne doivent pas bloquer l'ouverture de l'app.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, SettingsProvider>(
      builder: (context, themeProvider, settingsProvider, child) {
        final lowResource = settingsProvider.lowResourceMode;
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            final useDynamic = themeProvider.useDynamicColor;
            final ThemeData lightTheme = useDynamic && lightDynamic != null
                ? themeProvider.createThemeFromScheme(
                    lightDynamic.harmonized(),
                    Brightness.light,
                  )
                : themeProvider.lightTheme;
            final ThemeData darkTheme = useDynamic && darkDynamic != null
                ? themeProvider.createThemeFromScheme(
                    darkDynamic.harmonized(),
                    Brightness.dark,
                  )
                : themeProvider.darkTheme;

            final pageTransitionsTheme = lowResource
                ? const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android:
                          FadeUpwardsPageTransitionsBuilder(),
                    },
                  )
                : const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android:
                          PredictiveBackPageTransitionsBuilder(),
                    },
                  );

            return MaterialApp(
              title: 'Toolbox Everything',
              debugShowCheckedModeBanner: false,
              navigatorKey: QuickActionsService.navigatorKey,
              theme: lightTheme.copyWith(
                pageTransitionsTheme: pageTransitionsTheme,
              ),
              darkTheme: darkTheme.copyWith(
                pageTransitionsTheme: pageTransitionsTheme,
              ),
              themeMode: themeProvider.themeMode,
              themeAnimationDuration: lowResource
                  ? Duration.zero
                  : EditorialTokens.duration,
              themeAnimationCurve: Curves.easeOut,
              scrollBehavior: const NoGlowScrollBehavior(),
              home: const HomeScreen(),
            );
          },
        );
      },
    );
  }
}
