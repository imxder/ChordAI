import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'platform_style.dart';

bool get isMacLook => desktopLook == DesktopLook.mac;

const double macTitleBarHeight = 28;

const Color macDarkSurface = Color(0xFF1E1E1E);

const _window = MethodChannel('chordai/window');

class MacWindowAppearance extends StatefulWidget {
  final Widget child;

  const MacWindowAppearance({super.key, required this.child});

  @override
  State<MacWindowAppearance> createState() => _MacWindowAppearanceState();
}

class _MacWindowAppearanceState extends State<MacWindowAppearance> {
  bool? _dark;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isMacLook) return;
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark == _dark) return;
    _dark = dark;
    _window
        .invokeMethod<void>('setAppearance', {'dark': dark})
        .catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
