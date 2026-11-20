import 'package:flutter/widgets.dart';

/// Pras telas que usam o microfone: avisa quando o app some (foi pra segundo
/// plano ou o celular bloqueou) e quando volta. Sem isso o microfone e o
/// cálculo continuavam ligados com o app escondido.
///
/// Cada tela decide o que fazer: o afinador desliga e liga de novo sozinho,
/// as telas com botão de começar param como se a pessoa tivesse apertado
/// Parar, e o tocar junto pausa e continua de onde estava.
mixin MicLifecycle<T extends StatefulWidget> on State<T> {
  late final AppLifecycleListener _lifecycle;

  /// O app ficou escondido: segundo plano, celular bloqueado ou outra tela
  /// do sistema por cima.
  void onAppHidden();

  /// O app voltou a aparecer.
  void onAppShown() {}

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () {
        if (mounted) onAppHidden();
      },
      onShow: () {
        if (mounted) onAppShown();
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }
}
