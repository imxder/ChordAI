import 'package:flutter/animation.dart';

import 'platform_style.dart';

abstract final class GlassTokens {
  // No Windows 11 os cards têm cantos bem menores (uns 8 px) que no iPhone.
  static bool get _windows => desktopLook == DesktopLook.windows;
  static double get radiusMd => _windows ? 6.0 : 12.0;
  static double get radiusLg => _windows ? 8.0 : 16.0;
  static double get radiusXl => _windows ? 8.0 : 24.0;

  static const durationFast = Duration(milliseconds: 150);
  static const durationNormal = Duration(milliseconds: 300);
  static const spring = Cubic(0.22, 1, 0.36, 1);

  static const pressedScale = 0.97;

  static Color scrim({required bool dark}) {
    return const Color(0xFF000000).withValues(alpha: dark ? 0.5 : 0.25);
  }
}
