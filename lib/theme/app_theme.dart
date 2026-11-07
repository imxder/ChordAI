import '../theme/glass_tokens.dart';

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/app_theme.dart';

// Texto usa a fonte do sistema (SF Pro no iPhone). Só os acordes ficam em mono,
// porque a cifra depende de cada caractere ter a mesma largura.
const fontChord = 'IBMPlexMono';

class _Surface {
  final Brightness brightness;
  final Color background;
  final Color cell;
  final Color fill;
  final Color label;
  final Color secondaryLabel;
  final Color separator;
  final Color error;
  final Color onError;
  final Color correct;
  final Color warning;

  const _Surface({
    required this.brightness,
    required this.background,
    required this.cell,
    required this.fill,
    required this.label,
    required this.secondaryLabel,
    required this.separator,
    required this.error,
    required this.onError,
    required this.correct,
    required this.warning,
  });
}

const _paperSurface = _Surface(
  brightness: Brightness.light,
  background: Color(0xFFF3F0EA),
  cell: Color(0xFFFFFDF9),
  fill: Color(0xFFE7E3DA),
  label: Color(0xFF1C1A17),
  secondaryLabel: Color(0xFF66615A),
  separator: Color(0xFFD9D4CA),
  error: Color(0xFFC1271F),
  onError: Colors.white,
  correct: Color(0xFF237043),
  warning: Color(0xFF8F5400),
);

// O secondaryLabel do iOS (cinza a 60%) não passa de 4.5:1 de contraste; aqui é mais escuro.
const _whiteSurface = _Surface(
  brightness: Brightness.light,
  background: Color(0xFFF2F2F7),
  cell: Color(0xFFFFFFFF),
  fill: Color(0xFFE3E3E8),
  label: Color(0xFF000000),
  secondaryLabel: Color(0xFF636366),
  separator: Color(0xFFC6C6C8),
  error: Color(0xFFD70015),
  onError: Colors.white,
  correct: Color(0xFF1E7A3C),
  warning: Color(0xFF8F5400),
);

const _darkSurface = _Surface(
  brightness: Brightness.dark,
  background: Color(0xFF000000),
  cell: Color(0xFF1C1C1E),
  fill: Color(0xFF2C2C2E),
  label: Color(0xFFFFFFFF),
  secondaryLabel: Color(0xFFA1A1A8),
  separator: Color(0xFF38383A),
  error: Color(0xFFFF6961),
  onError: Color(0xFF1C0606),
  correct: Color(0xFF4CD27A),
  warning: Color(0xFFFFB340),
);

class AppTokens extends ThemeExtension<AppTokens> {
  final Color correct;
  final Color warning;
  final Color rule;
  final Color cell;
  final Color fill;

  const AppTokens({
    required this.correct,
    required this.warning,
    required this.rule,
    required this.cell,
    required this.fill,
  });

  static final light = AppTokens(
    correct: _paperSurface.correct,
    warning: _paperSurface.warning,
    rule: _paperSurface.separator,
    cell: _paperSurface.cell,
    fill: _paperSurface.fill,
  );

  @override
  AppTokens copyWith({
    Color? correct,
    Color? warning,
    Color? rule,
    Color? cell,
    Color? fill,
  }) {
    return AppTokens(
      correct: correct ?? this.correct,
      warning: warning ?? this.warning,
      rule: rule ?? this.rule,
      cell: cell ?? this.cell,
      fill: fill ?? this.fill,
    );
  }

  @override
  AppTokens lerp(covariant AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      correct: Color.lerp(correct, other.correct, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      rule: Color.lerp(rule, other.rule, t)!,
      cell: Color.lerp(cell, other.cell, t)!,
      fill: Color.lerp(fill, other.fill, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}

EdgeInsets pagePadding(
  BuildContext context, {
  double top = 8,
  double bottom = 24,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final side = max(16.0, (width - 600) / 2);
  return EdgeInsets.fromLTRB(
    side,
    top,
    side,
    bottom + MediaQuery.paddingOf(context).bottom,
  );
}

Duration motion(BuildContext context, Duration duration) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

/// [appearance] aqui é papel, branco ou escuro; "igual ao celular" é resolvido no MaterialApp.
ThemeData buildAppTheme(
  AppThemeOption option, {
  AppAppearance appearance = AppAppearance.paper,
}) {
  final s = switch (appearance) {
    AppAppearance.white => _whiteSurface,
    AppAppearance.dark => _darkSurface,
    _ => _paperSurface,
  };
  final dark = s.brightness == Brightness.dark;
  final accent = dark ? option.darkColor : option.color;
  final onAccent = dark ? const Color(0xFF16120E) : Colors.white;
  final tint = Color.alphaBlend(
    accent.withValues(alpha: dark ? 0.22 : 0.12),
    s.cell,
  );

  final colorScheme = ColorScheme(
    brightness: s.brightness,
    primary: accent,
    onPrimary: onAccent,
    primaryContainer: tint,
    onPrimaryContainer: s.label,
    secondary: s.label,
    onSecondary: s.background,
    secondaryContainer: tint,
    onSecondaryContainer: s.label,
    error: s.error,
    onError: s.onError,
    surface: s.background,
    onSurface: s.label,
    onSurfaceVariant: s.secondaryLabel,
    surfaceContainerLowest: s.cell,
    surfaceContainerLow: s.cell,
    surfaceContainer: s.cell,
    surfaceContainerHigh: s.fill,
    surfaceContainerHighest: s.fill,
    outline: s.secondaryLabel,
    outlineVariant: s.separator,
  );

  final textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: fontChord,
      fontSize: 72,
      fontWeight: FontWeight.w600,
      height: 1.05,
      color: s.label,
    ),
    headlineLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.15,
      color: s.label,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.18,
      color: s.label,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: s.label,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: s.label,
    ),
    titleSmall: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: s.label,
    ),
    bodyLarge: TextStyle(fontSize: 17, height: 1.3, color: s.label),
    bodyMedium: TextStyle(fontSize: 15, height: 1.35, color: s.label),
    bodySmall: TextStyle(fontSize: 13, height: 1.35, color: s.secondaryLabel),
    labelLarge: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: s.label,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: s.label,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: s.secondaryLabel,
    ),
  );

  const capsule = StadiumBorder();
  const buttonSize = Size(64, 50);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 22, vertical: 12);
  final buttonText = textTheme.labelLarge!;

  return ThemeData(
    useMaterial3: true,
    brightness: s.brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: s.background,
    canvasColor: s.background,
    textTheme: textTheme,
    extensions: [
      AppTokens(
        correct: s.correct,
        warning: s.warning,
        rule: s.separator,
        cell: s.cell,
        fill: s.fill,
      ),
    ],
    // iOS não tem ripple: o toque escurece a célula.
    splashFactory: NoSplash.splashFactory,
    highlightColor: s.label.withValues(alpha: dark ? 0.12 : 0.07),
    hoverColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      },
    ),
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: s.brightness,
      primaryColor: accent,
      scaffoldBackgroundColor: s.background,
      barBackgroundColor: s.background.withValues(alpha: 0.86),
    ),
    dividerTheme: DividerThemeData(
      color: s.separator,
      thickness: 0.5,
      space: 0.5,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: capsule,
        minimumSize: buttonSize,
        padding: buttonPadding,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: capsule,
        minimumSize: buttonSize,
        padding: buttonPadding,
        textStyle: buttonText,
        backgroundColor: s.fill,
        foregroundColor: accent,
        side: BorderSide.none,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: accent,
        textStyle: textTheme.bodyLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: accent,
        minimumSize: const Size(44, 44),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: s.cell,
      floatingLabelBehavior: FloatingLabelBehavior.always,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: s.cell,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: s.background,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: s.secondaryLabel.withValues(alpha: 0.5),
      dragHandleSize: const Size(36, 5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GlassTokens.radiusXl),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: s.label,
      contentTextStyle: TextStyle(color: s.background, fontSize: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: accent,
      linearTrackColor: s.fill,
      linearMinHeight: 4,
    ),
  );
}
