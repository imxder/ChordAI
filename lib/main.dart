import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'models/app_theme.dart';
import 'screens/app_shell.dart';
import 'screens/onboarding_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'theme/platform_style.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Sem o await, quem já passou pelo onboarding veria ele piscar ao abrir o app.
  await appState.loadProgress();
  if (!useLiquidGlass) {
    runApp(const ChordAIApp());
    return;
  }
  // Compila os shaders do vidro antes da primeira tela, senão ela engasga.
  await LiquidGlassWidgets.initialize();
  runApp(
    LiquidGlassWidgets.wrap(
      // O ajuste automático de qualidade ainda é experimental no pacote.
      adaptiveQuality: false,
      respectSystemAccessibility: true,
      brightnessResolver: Theme.maybeBrightnessOf,
      child: const ChordAIApp(),
    ),
  );
}

const appLocalizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

class ChordAIApp extends StatelessWidget {
  const ChordAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final option = appThemeOptions[appState.selectedThemeIndex];
        final appearance = appState.appearance;
        final lightAppearance = appearance == AppAppearance.white
            ? AppAppearance.white
            : AppAppearance.paper;

        return MaterialApp(
          title: 'ChordAI',
          debugShowCheckedModeBanner: false,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: appLocalizationsDelegates,
          theme: buildAppTheme(option, appearance: lightAppearance),
          darkTheme: buildAppTheme(option, appearance: AppAppearance.dark),
          themeMode: switch (appearance) {
            AppAppearance.dark => ThemeMode.dark,
            AppAppearance.system => ThemeMode.system,
            _ => ThemeMode.light,
          },
          // As telas usam barra do Cupertino, que não ajusta os ícones da barra
          // de status ao tema escuro por conta própria.
          builder: (context, child) {
            final dark = Theme.of(context).brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              child: child!,
            );
          },
          home: appState.hasCompletedOnboarding
              ? const AppShell()
              : const OnboardingScreen(),
        );
      },
    );
  }
}
