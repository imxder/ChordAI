import 'package:flutter/foundation.dart';

bool get useLiquidGlass =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;
