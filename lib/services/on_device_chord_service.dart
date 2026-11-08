import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/chord_model_info.dart';
import '../models/chord_prediction.dart';
import 'chord_recognizer.dart';
import 'chord_stabilizer.dart';
import 'latest_samples_buffer.dart';
import 'pcm16_decoder.dart';

/// Reconhece acordes no aparelho com o modelo TFLite exportado pelo backend
/// (ver ChordAI-backend/export/README.md): a extração de feature (chroma da
/// STFT) já está dentro do `.tflite`, então aqui só grava áudio, monta a
/// janela de 1,5s e lê a saída — nenhuma FFT/chroma/MFCC em Dart.
class OnDeviceChordService implements ChordRecognizer {
  final AudioRecorder _recorder = AudioRecorder();
  final Pcm16Decoder _decoder = Pcm16Decoder();

  StreamSubscription<Uint8List>? _subscription;
  Timer? _inferenceTimer;
  LatestSamplesBuffer? _buffer;
  ChordStabilizer? _stabilizer;
  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  ChordModelInfo? _modelInfo;
  InputDevice? _selectedDevice;
  bool _running = false;
  bool _inferring = false;

  /// Tempo da última inferência, em microssegundos — só pra diagnóstico
  /// (ver tela de configurações/prática, que mostra isso discretamente).
  int? lastInferenceMicros;

  @override
  bool get isRunning => _running;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<List<InputDevice>> listInputDevices() => _recorder.listInputDevices();

  @override
  void selectDevice(InputDevice? device) {
    _selectedDevice = device;
  }

  @override
  Future<void> start({
    String? serverUrl,
    required void Function(ChordPrediction prediction) onPrediction,
    required void Function(Object error) onError,
  }) async {
    if (_running) return;

    try {
      _modelInfo ??= await ChordModelInfo.load();
      _interpreter ??= await Interpreter.fromAsset('assets/models/chord_model.tflite');
      _isolateInterpreter ??=
          await IsolateInterpreter.create(address: _interpreter!.address);
    } catch (e) {
      onError(e);
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      onError(StateError('Sem permissão de microfone'));
      return;
    }

    _running = true;
    _decoder.reset();
    _buffer = LatestSamplesBuffer(_modelInfo!.inputSamples);
    _stabilizer = ChordStabilizer();

    final stream = await _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _modelInfo!.sampleRate,
        numChannels: 1,
        device: _selectedDevice,
      ),
    );

    _subscription = stream.listen((chunk) {
      _buffer?.addSamples(_decoder.decode(chunk));
    });

    _inferenceTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _tick(onPrediction, onError),
    );
  }

  Future<void> _tick(
    void Function(ChordPrediction) onPrediction,
    void Function(Object error) onError,
  ) async {
    if (!_running || _inferring) return;

    final window = _buffer?.snapshot();
    if (window == null) {
      _report(const ChordPrediction(status: 'too_short'), onPrediction);
      return;
    }

    if (_rms(window) < _modelInfo!.silenceRmsThreshold) {
      _report(const ChordPrediction(status: 'silence'), onPrediction);
      return;
    }

    _inferring = true;
    try {
      final raw = await _infer(window);
      if (_running) _report(raw, onPrediction);
    } catch (e) {
      if (_running) onError(e);
    } finally {
      _inferring = false;
    }
  }

  void _report(
    ChordPrediction raw,
    void Function(ChordPrediction) onPrediction,
  ) {
    final stabilized = _stabilizer?.process(raw);
    if (stabilized != null) onPrediction(stabilized);
  }

  Future<ChordPrediction> _infer(Float32List window) async {
    final info = _modelInfo!;
    final input = [window];
    final output = [List<double>.filled(info.labels.length, 0.0)];

    final stopwatch = Stopwatch()..start();
    await _isolateInterpreter!.run(input, output);
    stopwatch.stop();
    lastInferenceMicros = stopwatch.elapsedMicroseconds;

    final probabilities = output[0];
    var bestIndex = 0;
    for (var i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > probabilities[bestIndex]) bestIndex = i;
    }
    final label = info.labels[bestIndex];
    final confidence = probabilities[bestIndex];

    if (label == info.noneLabel || confidence < info.confidenceThreshold) {
      return ChordPrediction(status: 'unknown', confidence: confidence);
    }
    return ChordPrediction(status: 'ok', chord: label, confidence: confidence);
  }

  double _rms(Float32List samples) {
    var sum = 0.0;
    for (final sample in samples) {
      sum += sample * sample;
    }
    return sqrt(sum / samples.length);
  }

  @override
  Future<void> stop() async {
    _running = false;
    _inferenceTimer?.cancel();
    _inferenceTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    _buffer = null;
    _stabilizer = null;
    _decoder.reset();
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _isolateInterpreter?.close();
    _isolateInterpreter = null;
    _interpreter?.close();
    _interpreter = null;
    await _recorder.dispose();
  }
}
