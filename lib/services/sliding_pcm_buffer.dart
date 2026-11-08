import 'dart:typed_data';

/// Acumula amostras PCM recebidas aos poucos, em chunks de qualquer tamanho,
/// e entrega janelas de [windowSize] amostras deslizando [hopSize] a cada
/// vez. Usa um buffer circular de tamanho fixo (sem `List<int>`/sublist por
/// chunk) para não gerar lixo de alocação a cada pacote de áudio.
class SlidingPcmBuffer {
  final int windowSize;
  final int hopSize;

  final Float32List _ring;
  int _writePos = 0;
  int _totalWritten = 0;
  int _nextWindowEnd;

  SlidingPcmBuffer({required this.windowSize, required this.hopSize})
      : assert(hopSize > 0 && hopSize <= windowSize),
        _ring = Float32List(windowSize),
        _nextWindowEnd = windowSize;

  /// Adiciona amostras novas e devolve, na ordem em que ficaram completas,
  /// todas as janelas de [windowSize] amostras que esse chunk fechou — pode
  /// ser zero, uma ou várias, dependendo de quanto chegou de uma vez.
  List<Float64List> addSamples(List<double> samples) {
    final windows = <Float64List>[];
    for (final sample in samples) {
      _ring[_writePos] = sample;
      _writePos++;
      if (_writePos == windowSize) _writePos = 0;
      _totalWritten++;

      if (_totalWritten >= _nextWindowEnd) {
        windows.add(_extractWindow());
        _nextWindowEnd += hopSize;
      }
    }
    return windows;
  }

  Float64List _extractWindow() {
    final out = Float64List(windowSize);
    // _writePos é onde a próxima amostra entraria; como o buffer já deu (ou
    // está dando) a volta, é também onde começa a amostra mais antiga.
    for (var i = 0; i < windowSize; i++) {
      out[i] = _ring[(_writePos + i) % windowSize];
    }
    return out;
  }
}
