import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/ph.dart';
import '../theme/platform_style.dart';
import '../theme/windows_style.dart';

/// Uma aba da barra lateral: as mesmas do AppShell no celular.
class DesktopDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const DesktopDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Item do pé da barra lateral que não é aba: abre alguma coisa (o
/// diálogo da entrada de áudio, por exemplo), como "Configurações" no
/// NavigationView do Windows 11.
class DesktopPaneAction {
  final IconData icon;
  final String label;
  final void Function(BuildContext context) onTap;

  const DesktopPaneAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// Casca do app no computador: barra lateral à esquerda, como o
/// NavigationView do Windows 11, e o conteúdo da aba à direita.
///
/// Cada aba tem a própria pilha de telas (um Navigator só dela). Abrindo um
/// acorde ou uma música, a tela nova aparece do lado da barra, e a barra
/// continua lá, como num programa de computador. As telas não mudam: elas
/// continuam chamando Navigator.push, que acha o Navigator da aba.
class DesktopShell extends StatefulWidget {
  final List<DesktopDestination> destinations;

  /// Itens no pé da barra, embaixo das abas.
  final List<DesktopPaneAction> actions;

  /// A primeira tela de cada aba. É uma função, não a tela pronta, porque o
  /// Navigator da aba guarda a tela que criou: assim ela se refaz quando
  /// [rebuildOn] avisa (as configurações do app mudaram).
  final List<WidgetBuilder> pages;
  final Listenable rebuildOn;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const DesktopShell({
    super.key,
    required this.destinations,
    this.actions = const [],
    required this.pages,
    required this.rebuildOn,
    required this.selectedIndex,
    required this.onSelected,
  });

  /// Abaixo dessa largura de janela a barra recolhe pra só os ícones, e o
  /// conteúdo ganha o espaço.
  static const compactBelow = 1000.0;
  static const paneWidth = 232.0;
  // Recolhida: 4 de margem + 40 do ícone + 4.
  static const compactPaneWidth = 48.0;

  @override
  State<DesktopShell> createState() => DesktopShellState();
}

class DesktopShellState extends State<DesktopShell> {
  late final _navigators = List.generate(
    widget.pages.length,
    (_) => GlobalKey<NavigatorState>(),
  );

  /// null: segue a largura da janela. true/false: a pessoa abriu ou fechou
  /// pelo botão de menu.
  bool? _openByUser;

  /// Volta uma tela na aba aberta. Devolve false se já está na primeira.
  Future<bool> popInCurrentTab() async {
    final navigator = _navigators[widget.selectedIndex].currentState;
    if (navigator == null || !navigator.canPop()) return false;
    navigator.pop();
    return true;
  }

  void _select(int index) {
    // Tocar de novo na aba aberta volta pra primeira tela dela.
    if (index == widget.selectedIndex) {
      _navigators[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    widget.onSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= DesktopShell.compactBelow;
    final open = _openByUser ?? wide;
    // Windows 11: a barra lateral fica num tom acima do fundo, e o conteúdo
    // numa "folha" com o canto de cima arredondado e uma borda fina, como no
    // NavigationView. Os outros computadores usam a casca simples.
    final theme = Theme.of(context);
    final windows = desktopLook == DesktopLook.windows;

    // Esc volta uma tela na aba aberta, como o botão de voltar.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): popInCurrentTab,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: windows ? windowsPaneColor(theme) : null,
          body: Row(
            children: [
              _Pane(
                destinations: widget.destinations,
                actions: widget.actions,
                selectedIndex: widget.selectedIndex,
                open: open,
                onSelected: _select,
                onToggle: () => setState(() => _openByUser = !open),
              ),
              Expanded(
                child: _ContentSheet(
                  enabled: windows,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // As telas medem a largura pela MediaQuery (ver pagePadding).
                      // Aqui ela passa a ser a da área de conteúdo, sem a barra.
                      final media = MediaQuery.of(context);
                      return MediaQuery(
                        data: media.copyWith(size: constraints.biggest),
                        child: IndexedStack(
                          index: widget.selectedIndex,
                          children: [
                            for (var i = 0; i < widget.pages.length; i++)
                              HeroControllerScope.none(
                                child: Navigator(
                                  key: _navigators[i],
                                  onGenerateRoute: (settings) =>
                                      MaterialPageRoute(
                                        settings: settings,
                                        builder: (context) => ListenableBuilder(
                                          listenable: widget.rebuildOn,
                                          builder: (context, _) =>
                                              widget.pages[i](context),
                                        ),
                                      ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  final List<DesktopDestination> destinations;
  final List<DesktopPaneAction> actions;
  final int selectedIndex;
  final bool open;
  final ValueChanged<int> onSelected;
  final VoidCallback onToggle;

  const _Pane({
    required this.destinations,
    required this.actions,
    required this.selectedIndex,
    required this.open,
    required this.onSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      width: open ? DesktopShell.paneWidth : DesktopShell.compactPaneWidth,
      // A margem dos lados fica em cada item (a pílula), não aqui.
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PaneItem(
            icon: Ph.list,
            label: 'ChordAI',
            labelStyle: textTheme.titleSmall,
            tooltip: open ? 'Recolher o menu' : 'Abrir o menu',
            open: open,
            selected: false,
            onTap: onToggle,
          ),
          const SizedBox(height: 8),
          for (final (i, destination) in destinations.indexed)
            _PaneItem(
              key: ValueKey('aba ${destination.label}'),
              icon: i == selectedIndex
                  ? destination.selectedIcon
                  : destination.icon,
              label: destination.label,
              open: open,
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
            ),
          const Spacer(),
          for (final action in actions)
            _PaneItem(
              key: ValueKey('ação ${action.label}'),
              icon: action.icon,
              label: action.label,
              open: open,
              selected: false,
              onTap: () => action.onTap(context),
            ),
        ],
      ),
    );
  }
}

/// Item da barra, com as medidas do NavigationView do Windows 11: uma
/// pílula de 36 de altura e cantos de 4, com 4 de margem dos dois lados (não
/// encosta na borda da janela). Fundo de leve ao passar o mouse, mais forte
/// quando é a aba aberta, e a barrinha da cor do app dentro da pílula, na
/// ponta esquerda (3 x 16, centralizada na altura).
class _PaneItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextStyle? labelStyle;
  final String? tooltip;
  final bool open;
  final bool selected;
  final VoidCallback onTap;

  const _PaneItem({
    super.key,
    required this.icon,
    required this.label,
    required this.open,
    required this.selected,
    required this.onTap,
    this.labelStyle,
    this.tooltip,
  });

  static const margin = 4.0;
  static const height = 36.0;
  static const iconBox = 40.0;
  static const radius = BorderRadius.all(Radius.circular(4));

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onSurface = colorScheme.onSurface;

    Widget item = Padding(
      padding: const EdgeInsets.symmetric(horizontal: margin, vertical: 2),
      child: Material(
        color: selected
            ? onSurface.withValues(alpha: 0.07)
            : Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          hoverColor: onSurface.withValues(alpha: 0.05),
          splashFactory: NoSplash.splashFactory,
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                // Ocupa a pílula toda e centraliza na altura. Sem isso o Stack
                // põe a linha no topo e sobra espaço só embaixo.
                Positioned.fill(
                  child: Row(
                    children: [
                      // O ícone fica numa caixa de 40 no começo da pílula. O ☰
                      // usa este mesmo item, então os ícones ficam alinhados
                      // com ele.
                      SizedBox(
                        width: iconBox,
                        child: Icon(
                          icon,
                          size: 18,
                          color: selected ? colorScheme.primary : onSurface,
                        ),
                      ),
                      if (open)
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                            style:
                                labelStyle ??
                                textTheme.bodyMedium?.copyWith(
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  Positioned(
                    left: 0,
                    top: (height - 16) / 2,
                    width: 3,
                    height: 16,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    item = Semantics(
      button: true,
      selected: selected,
      label: tooltip ?? label,
      excludeSemantics: true,
      child: item,
    );

    // Recolhida, a barra só mostra o ícone: o nome aparece ao parar o mouse.
    if (!open || tooltip != null) {
      item = Tooltip(
        message: tooltip ?? label,
        waitDuration: const Duration(milliseconds: 400),
        child: item,
      );
    }
    return item;
  }
}

/// Uma coluna de tela no computador. As telas medem a largura pela
/// MediaQuery (ver pagePadding); aqui ela vira a largura da coluna, então
/// uma tela inteira (lista, detalhe do acorde) cabe certinho dentro dela.
class DesktopPane extends StatelessWidget {
  final Widget child;

  const DesktopPane({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: constraints.biggest),
        child: child,
      ),
    );
  }
}

/// Duas colunas lado a lado, com uma linha fina entre elas. A da esquerda
/// tem largura fixa; a da direita fica com o resto.
class DesktopSplit extends StatelessWidget {
  final double leftWidth;
  final Widget left;
  final Widget right;

  const DesktopSplit({
    super.key,
    required this.leftWidth,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: leftWidth,
          child: DesktopPane(child: left),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
        Expanded(child: DesktopPane(child: right)),
      ],
    );
  }
}

/// A "folha" de conteúdo do Windows 11: fundo do app, canto de cima à
/// esquerda arredondado e uma borda fina separando da barra lateral.
class _ContentSheet extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const _ContentSheet({required this.enabled, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final theme = Theme.of(context);
    const radius = BorderRadius.only(topLeft: Radius.circular(8));
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: radius,
        border: Border(
          left: BorderSide(color: theme.colorScheme.outlineVariant),
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}
