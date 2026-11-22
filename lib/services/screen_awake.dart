import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

@visibleForTesting
Future<void> Function(bool on) wakelockToggle = (on) =>
    WakelockPlus.toggle(enable: on);

/// Deixa a tela acesa enquanto a pessoa toca sem encostar no aparelho
/// (rolagem automática e tocar junto). Se a plataforma não deixar, só segue.
Future<void> keepScreenOn(bool on) async {
  try {
    await wakelockToggle(on);
  } catch (_) {}
}
