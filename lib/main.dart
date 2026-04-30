import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_everything_mobile/core/providers/theme_provider.dart';
import 'package:toolbox_everything_mobile/core/providers/settings_provider.dart';
import 'package:toolbox_everything_mobile/presentation/screens/home_screen.dart';
import 'package:toolbox_everything_mobile/core/services/quick_actions_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/painting.dart' as painting;

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
    // Animation de fondu et de léger glissement vers le haut
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
  // Optimisation mémoire pour appareils low-cost
  painting.imageCache.maximumSize = 100; // nombre max d'images en cache
  painting.imageCache.maximumSizeBytes = 50 << 20; // ~50 Mo
  // Edge-to-edge et styles barres système
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));

  // Ce listener met à jour le style des icônes de la barre de statut en fonction du thème
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
    // Une fois l'UI prête, on initialise les services non critiques.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeDeferredServices());
    });
  }

  Future<void> _initializeDeferredServices() async {
    // Laisse le premier rendu respirer avant d'ouvrir les canaux natifs non critiques.
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

            // Mettre à jour le style de la barre de statut en fonction du thème
            final Brightness platformBrightness =
                MediaQuery.platformBrightnessOf(context);
            final bool isDarkMode =
                themeProvider.themeMode == ThemeMode.dark ||
                (themeProvider.themeMode == ThemeMode.system &&
                    platformBrightness == Brightness.dark);

            SystemChrome.setSystemUIOverlayStyle(
              SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
                statusBarIconBrightness: isDarkMode
                    ? Brightness.light
                    : Brightness.dark,
                systemNavigationBarIconBrightness: isDarkMode
                    ? Brightness.light
                    : Brightness.dark,
              ),
            );

            final pageTransitionsTheme = lowResource
                ? const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
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
              navigatorKey: QuickActionsService.navigatorKey,
              theme: lightTheme.copyWith(
                pageTransitionsTheme: pageTransitionsTheme,
              ),
              darkTheme: darkTheme.copyWith(
                pageTransitionsTheme: pageTransitionsTheme,
              ),
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
