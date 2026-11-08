/// Converte bytes PCM16 little-endian em amostras double (-1..1). Mantém
/// entre chamadas o byte que sobrar quando um chunk chega com tamanho
/// ímpar — sem isso, a amostra seguinte ficaria desalinhada, já que PCM16
/// usa 2 bytes por amostra.
class Pcm16Decoder {
  int? _pendingLowByte;

  List<double> decode(List<int> bytes) {
    final samples = <double>[];
    var i = 0;

    if (_pendingLowByte != null) {
      if (bytes.isEmpty) return samples;
      samples.add(_toSample(_pendingLowByte!, bytes[0]));
      _pendingLowByte = null;
      i = 1;
    }

    for (; i + 1 < bytes.length; i += 2) {
      samples.add(_toSample(bytes[i], bytes[i + 1]));
    }

    if (i < bytes.length) {
      _pendingLowByte = bytes[i];
    }

    return samples;
  }

  double _toSample(int lowByte, int highByte) {
    var value = lowByte | (highByte << 8);
    if (value >= 0x8000) value -= 0x10000;
    return value / 32768.0;
  }

  void reset() {
    _pendingLowByte = null;
  }
}
