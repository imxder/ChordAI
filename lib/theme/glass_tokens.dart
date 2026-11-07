import 'package:flutter/animation.dart';

abstract final class GlassTokens {
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 24.0;

  static const durationFast = Duration(milliseconds: 150);
  static const durationNormal = Duration(milliseconds: 300);
  static const spring = Cubic(0.22, 1, 0.36, 1);

  static const pressedScale = 0.97;

  static Color scrim({required bool dark}) {
    return const Color(0xFF000000).withValues(alpha: dark ? 0.5 : 0.25);
  }
}
