import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'pitch_detector.dart';
import 'pitch_smoother.dart';

class TunerService {
  static const int sampleRate = 22050;
  static const int _windowSizeSamples = 4096;
  static const int _hopSizeSamples = 1024;

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _subscription;
  final List<int> _byteBuffer = [];
  PitchSmoother? _smoother;

  /// Suaviza as leituras de frequência e expõe a histerese do estado
  /// "afinado" (ver PitchSmoother.updateInTune) pra tela do afinador.
  PitchSmoother? get smoother => _smoother;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start(void Function(double? frequency) onPitch) async {
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
      ),
    );

    _byteBuffer.clear();
    _smoother = PitchSmoother();
    const windowBytes = _windowSizeSamples * 2;
    const hopBytes = _hopSizeSamples * 2;

    _subscription = stream.listen((chunk) {
      _byteBuffer.addAll(chunk);
      // Janela deslizante: cada leitura reaproveita a maior parte da
      // anterior e avança só um salto de 1024 amostras (~46 ms), em vez de
      // consumir a janela inteira — assim a latência cai de ~186 ms pra
      // ~46 ms entre leituras.
      while (_byteBuffer.length >= windowBytes) {
        final windowBytesList = _byteBuffer.sublist(0, windowBytes);
        _byteBuffer.removeRange(0, hopBytes);
        final samples = _bytesToFloatSamples(windowBytesList);
        final estimate = detectPitchWithConfidence(samples, sampleRate.toDouble());
        onPitch(_smoother!.update(estimate));
      }
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _byteBuffer.clear();
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
  }

  List<double> _bytesToFloatSamples(List<int> bytes) {
    final samples = <double>[];
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      var value = bytes[i] | (bytes[i + 1] << 8);
      if (value >= 0x8000) value -= 0x10000;
      samples.add(value / 32768.0);
    }
    return samples;
  }
}
