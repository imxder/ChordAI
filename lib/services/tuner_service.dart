import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'pcm16_decoder.dart';
import 'pitch_detector.dart';
import 'pitch_smoother.dart';
import 'sliding_pcm_buffer.dart';

class TunerService {
  static const int sampleRate = 22050;
  static const int _windowSizeSamples = 4096;
  static const int _hopSizeSamples = 1024;

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _subscription;
  SlidingPcmBuffer? _buffer;
  PitchSmoother? _smoother;
  final Pcm16Decoder _decoder = Pcm16Decoder();

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

    // Janela deslizante com 75% de sobreposição: cada leitura reaproveita a
    // maior parte da anterior e avança só um salto de 1024 amostras
    // (~46 ms), em vez de consumir a janela inteira (~186 ms) — assim o
    // ponteiro atualiza bem mais rápido. O YIN leva ~1 ms por chamada (bem
    // dentro desse orçamento de 46 ms), então roda direto aqui, sem Isolate.
    _buffer = SlidingPcmBuffer(
      windowSize: _windowSizeSamples,
      hopSize: _hopSizeSamples,
    );
    _smoother = PitchSmoother();
    _decoder.reset();

    _subscription = stream.listen((chunk) {
      final samples = _decoder.decode(chunk);
      for (final window in _buffer!.addSamples(samples)) {
        final estimate = detectPitchWithConfidence(window, sampleRate.toDouble());
        onPitch(_smoother!.update(estimate));
      }
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _buffer = null;
    _decoder.reset();
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
  }
}
