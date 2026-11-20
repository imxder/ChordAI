import 'package:flutter/foundation.dart';

bool get useLiquidGlass =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// Windows e Mac: barra lateral no lugar das abas de baixo, colunas mais
/// largas, mouse e teclado. No celular é sempre falso, e nada disso aparece.
bool get isDesktop => desktopLook != null;

/// Cara de cada computador. É o único lugar que escolhe o estilo por
/// plataforma no desktop: a casca (barra lateral, cabeçalho, diálogos)
/// pergunta aqui, e cada estilo preenche o seu caso.
enum DesktopLook {
  /// Windows 11: cantos menores, fonte Segoe UI Variable, cores de fundo do
  /// Fluent (ver theme/windows_style.dart).
  windows,

  /// macOS: fica pra sessão do Mac. Por enquanto usa a casca comum.
  mac,
}

DesktopLook? get desktopLook {
  if (kIsWeb) return null;
  return switch (defaultTargetPlatform) {
    TargetPlatform.windows => DesktopLook.windows,
    TargetPlatform.macOS => DesktopLook.mac,
    _ => null,
  };
}
