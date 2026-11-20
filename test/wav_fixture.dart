import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Lê um WAV PCM de 16 bits das gravações de teste. Se for estéreo, fica só
/// o canal esquerdo.
class Wav {
  final double sampleRate;
  final List<double> samples;

  const Wav(this.sampleRate, this.samples);
}

Wav readWav(File file) {
  final bytes = file.readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  String tag(int offset) =>
      String.fromCharCodes(bytes.sublist(offset, offset + 4));
  if (tag(0) != 'RIFF' || tag(8) != 'WAVE') {
    throw FormatException('${file.path} não é WAV');
  }

  int? channels;
  int? sampleRate;
  int? bitsPerSample;
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final id = tag(offset);
    final size = data.getUint32(offset + 4, Endian.little);
    final body = offset + 8;
    if (id == 'fmt ') {
      channels = data.getUint16(body + 2, Endian.little);
      sampleRate = data.getUint32(body + 4, Endian.little);
      bitsPerSample = data.getUint16(body + 14, Endian.little);
    } else if (id == 'data') {
      if (channels == null || sampleRate == null) break;
      if (bitsPerSample != 16) {
        throw FormatException('${file.path}: só PCM de 16 bits');
      }
      final frameBytes = 2 * channels;
      final end = min(body + size, bytes.length);
      final samples = <double>[];
      for (var i = body; i + frameBytes <= end; i += frameBytes) {
        samples.add(data.getInt16(i, Endian.little) / 32768.0);
      }
      return Wav(sampleRate.toDouble(), samples);
    }
    // Chunks de tamanho ímpar têm um byte de preenchimento.
    offset = body + size + (size.isOdd ? 1 : 0);
  }
  throw FormatException('${file.path}: sem chunk fmt/data');
}
