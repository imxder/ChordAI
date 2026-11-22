import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'platform_style.dart';

/// Cara de Windows 11. Só vale quando desktopLook é windows; no celular e no
/// Mac nada daqui é usado.

/// Fonte do Windows 11. A "Variable Text" só existe no Windows 11; no
/// Windows 10 cai pra Segoe UI.
const windowsFont = 'Segoe UI Variable Text';
const windowsFontFallback = ['Segoe UI'];

/// Troca a fonte do texto pela do Windows 11. Os estilos que já têm fonte
/// própria (os acordes, em mono) continuam com ela.
TextTheme withWindowsFont(TextTheme theme) {
  TextStyle? font(TextStyle? style) => style?.fontFamily != null
      ? style
      : style?.copyWith(
          fontFamily: windowsFont,
          fontFamilyFallback: windowsFontFallback,
        );
  return theme.copyWith(
    displayLarge: font(theme.displayLarge),
    displayMedium: font(theme.displayMedium),
    displaySmall: font(theme.displaySmall),
    headlineLarge: font(theme.headlineLarge),
    headlineMedium: font(theme.headlineMedium),
    headlineSmall: font(theme.headlineSmall),
    titleLarge: font(theme.titleLarge),
    titleMedium: font(theme.titleMedium),
    titleSmall: font(theme.titleSmall),
    bodyLarge: font(theme.bodyLarge),
    bodyMedium: font(theme.bodyMedium),
    bodySmall: font(theme.bodySmall),
    labelLarge: font(theme.labelLarge),
    labelMedium: font(theme.labelMedium),
    labelSmall: font(theme.labelSmall),
  );
}

/// Cor da barra lateral, um pouco mais escura que o fundo da folha de
/// conteúdo, como o painel do NavigationView do Windows 11. No claro escurece
/// de leve; no escuro, um pouco mais, pra a folha ficar um tom acima.
Color windowsPaneColor(ThemeData theme) {
  final dark = theme.brightness == Brightness.dark;
  return Color.alphaBlend(
    dark
        ? const Color(0xFF000000).withValues(alpha: 0.28)
        : theme.colorScheme.onSurface.withValues(alpha: 0.035),
    theme.scaffoldBackgroundColor,
  );
}

const _window = MethodChannel('chordai/window');

/// Pinta a barra de título da janela (a faixa com o X) com a cor da barra
/// lateral, pra a janela parecer uma peça só. Quem pinta é o runner em C++
/// (windows/runner/flutter_window.cpp), porque o Flutter não desenha essa
/// barra. Muda junto quando a pessoa troca a aparência nas Configurações.
class WindowsTitleBarColor extends StatefulWidget {
  final Widget child;

  const WindowsTitleBarColor({super.key, required this.child});

  @override
  State<WindowsTitleBarColor> createState() => _WindowsTitleBarColorState();
}

class _WindowsTitleBarColorState extends State<WindowsTitleBarColor> {
  Color? _painted;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (desktopLook != DesktopLook.windows) return;
    final theme = Theme.of(context);
    final background = windowsPaneColor(theme);
    if (background == _painted) return;
    _painted = background;
    _window
        .invokeMethod<void>('setTitleBarColors', {
          'background': background.toARGB32(),
          'text': theme.colorScheme.onSurface.toARGB32(),
        })
        .catchError((Object _) {
          // Teste ou Windows sem suporte: a barra fica com a cor padrão.
        });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Troca de tela do Windows 11: a tela nova aparece por cima da anterior,
/// subindo só um pouquinho (3% da altura) enquanto ganha opacidade. A
/// anterior fica parada embaixo até a nova cobrir, então não aparece fundo
/// vazio no meio da troca.
class WindowsPageTransitionsBuilder extends PageTransitionsBuilder {
  const WindowsPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
