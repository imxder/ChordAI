import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'audio_input.dart';
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
  MicrophoneWatch? _microphoneWatch;

  /// Suaviza as leituras de frequência e expõe a histerese do estado
  /// "afinado" (ver PitchSmoother.updateInTune) pra tela do afinador.
  PitchSmoother? get smoother => _smoother;

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// [onProblem] só é chamado no computador, se o microfone estiver
  /// bloqueado ou a entrada for desconectada (ver audio_input.dart).
  Future<void> start(
    void Function(double? frequency) onPitch, {
    void Function(MicrophoneProblem problem)? onProblem,
  }) async {
    _microphoneWatch = watchMicrophone(_recorder, (problem) {
      stop();
      onProblem?.call(problem);
    });
    final stream = await _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        device: await chosenInputDevice(_recorder),
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
        final estimate = detectPitchWithConfidence(
          window,
          sampleRate.toDouble(),
        );
        onPitch(_smoother!.update(estimate, level: newSamplesLevel(window)));
      }
    });
  }

  /// RMS só das [_hopSizeSamples] amostras que chegaram agora (o fim da
  /// janela). Comparando um salto com o anterior, o PitchSmoother percebe
  /// quando uma corda foi beliscada.
  static double newSamplesLevel(List<double> window) {
    var sum = 0.0;
    for (var i = window.length - _hopSizeSamples; i < window.length; i++) {
      sum += window[i] * window[i];
    }
    return sqrt(sum / _hopSizeSamples);
  }

  Future<void> stop() async {
    await _microphoneWatch?.cancel();
    _microphoneWatch = null;
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
