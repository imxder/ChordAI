import 'dart:math';

import 'package:chordai/models/app_theme.dart';
import 'package:chordai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  const looks = [AppAppearance.paper, AppAppearance.white, AppAppearance.dark];
  for (final option in appThemeOptions) {
    for (final look in looks) {
      test(
        'cor ${option.name} no fundo ${look.label} tem contraste de texto (WCAG AA)',
        () {
          final theme = buildAppTheme(option, appearance: look);
          final scheme = theme.colorScheme;
          final tokens = theme.extension<AppTokens>()!;
          final paper = scheme.surface;
          final raised = scheme.surfaceContainerLowest;

          expect(
            _contrast(scheme.onPrimary, scheme.primary),
            greaterThanOrEqualTo(4.5),
          );
          expect(_contrast(scheme.primary, paper), greaterThanOrEqualTo(4.5));
          expect(_contrast(scheme.primary, raised), greaterThanOrEqualTo(4.5));
          expect(
            _contrast(scheme.onSurface, scheme.primaryContainer),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrast(scheme.onSurfaceVariant, paper),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrast(scheme.onSurfaceVariant, raised),
            greaterThanOrEqualTo(4.5),
          );
          expect(_contrast(tokens.correct, paper), greaterThanOrEqualTo(4.5));
          expect(_contrast(tokens.warning, paper), greaterThanOrEqualTo(4.5));
          expect(_contrast(scheme.error, paper), greaterThanOrEqualTo(4.5));
          expect(
            _contrast(scheme.surface, scheme.onSurface),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrast(scheme.onError, scheme.error),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrast(scheme.onSurface, scheme.surfaceContainerHigh),
            greaterThanOrEqualTo(4.5),
          );
        },
      );
    }
  }
}
