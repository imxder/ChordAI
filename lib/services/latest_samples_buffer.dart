import 'dart:typed_data';

/// Guarda sempre as últimas [capacity] amostras recebidas, num buffer
/// circular de tamanho fixo. Diferente do SlidingPcmBuffer (que emite uma
/// janela a cada salto fixo de amostras), aqui quem decide quando olhar o
/// buffer é um timer externo — por isso [snapshot] pode ser chamado a
/// qualquer momento, e não "consome" nada.
class LatestSamplesBuffer {
  final int capacity;

  final Float32List _ring;
  int _writePos = 0;
  int _count = 0;

  LatestSamplesBuffer(this.capacity) : _ring = Float32List(capacity);

  void addSamples(List<double> samples) {
    for (final sample in samples) {
      _ring[_writePos] = sample;
      _writePos++;
      if (_writePos == capacity) _writePos = 0;
      if (_count < capacity) _count++;
    }
  }

  bool get isFull => _count >= capacity;

  /// As últimas [capacity] amostras, na ordem em que chegaram, ou `null`
  /// enquanto o buffer ainda não encheu pela primeira vez.
  Float32List? snapshot() {
    if (!isFull) return null;
    final out = Float32List(capacity);
    for (var i = 0; i < capacity; i++) {
      out[i] = _ring[(_writePos + i) % capacity];
    }
    return out;
  }

  void reset() {
    _writePos = 0;
    _count = 0;
  }
}
