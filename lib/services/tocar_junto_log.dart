import 'package:flutter/foundation.dart';

class TocarJuntoLog {
  static double _mediaRms = 0;

  static void evento(String texto) {
    if (!kDebugMode) return;
    debugPrint('[tj] ${DateTime.now().millisecondsSinceEpoch} $texto');
  }

  static void blocoDeAudio(List<double> amostras) {
    if (!kDebugMode || amostras.isEmpty) return;
    var soma = 0.0;
    for (final a in amostras) {
      soma += a * a;
    }
    final rms = soma / amostras.length;
    if (rms > 0.0004 && rms > _mediaRms * 4) {
      evento('ataque rms2=${rms.toStringAsFixed(5)}');
    }
    _mediaRms = _mediaRms * 0.9 + rms * 0.1;
  }
}
