import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/platform_style.dart';

/// Espaço começa e para (Reconhecer, Tocar e testar, Sequências e Tocar
/// junto), como o play e pause de um player no computador. [onToggle] null
/// é o botão desligado (sem sequência escolhida, por exemplo).
///
/// O Focus com autofocus faz a tela receber o teclado assim que abre. No
/// celular não tem teclado físico na prática, então nada muda.
class SpaceToToggle extends StatelessWidget {
  final VoidCallback? onToggle;
  final Widget child;

  const SpaceToToggle({super.key, required this.onToggle, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!isDesktop) return child;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () => onToggle?.call(),
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}

/// Cursor de mão em coisas clicáveis que não são botões do Material (as
/// casinhas das cordas no afinador, as cores nas Configurações). Os botões e as
/// linhas com InkWell já mostram a mão sozinhos.
class ClickCursor extends StatelessWidget {
  final Widget child;

  const ClickCursor({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!isDesktop) return child;
    return MouseRegion(cursor: SystemMouseCursors.click, child: child);
  }
}
