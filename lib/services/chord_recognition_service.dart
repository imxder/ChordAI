import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:record/record.dart';

import '../models/chord_prediction.dart';
import 'chord_recognizer.dart';

class ChordRecognitionService implements ChordRecognizer {
  static const Duration windowDuration = Duration(milliseconds: 1500);

  final AudioRecorder _recorder = AudioRecorder();
  bool _running = false;
  InputDevice? _selectedDevice;
  int _issuedSeq = 0;
  int _lastAppliedSeq = 0;

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
    if (serverUrl == null) {
      onError(ArgumentError('serverUrl é obrigatório no modo servidor'));
      return;
    }
    _running = true;
    _issuedSeq = 0;
    _lastAppliedSeq = 0;
    _loop(serverUrl, onPrediction, onError);
  }

  @override
  Future<void> stop() async {
    _running = false;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
  }

  Future<void> _loop(
    String serverUrl,
    void Function(ChordPrediction) onPrediction,
    void Function(Object error) onError,
  ) async {
    while (_running) {
      try {
        final filePath = await _recordWindow();
        if (!_running) {
          try {
            await File(filePath).delete();
          } catch (_) {}
          break;
        }
        final seq = ++_issuedSeq;
        // Não espera a resposta do servidor: a próxima janela já começa a
        // gravar enquanto esta é enviada, senão a latência de rede (pior
        // ainda num servidor remoto) se soma ao atraso de 1.5s do modelo.
        unawaited(_predictAndReport(filePath, serverUrl, seq, onPrediction, onError));
      } catch (e) {
        if (_running) onError(e);
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  Future<void> _predictAndReport(
    String filePath,
    String serverUrl,
    int seq,
    void Function(ChordPrediction) onPrediction,
    void Function(Object error) onError,
  ) async {
    try {
      final prediction = await _predict(filePath, serverUrl);
      // Descarta respostas que chegaram fora de ordem (uma janela mais
      // recente já pode ter sido reportada enquanto esta estava em trânsito).
      if (_running && seq > _lastAppliedSeq) {
        _lastAppliedSeq = seq;
        onPrediction(prediction);
      }
    } catch (e) {
      if (_running) onError(e);
    } finally {
      try {
        await File(filePath).delete();
      } catch (_) {}
    }
  }

  Future<String> _recordWindow() async {
    final path =
        '${Directory.systemTemp.path}/chord_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 22050,
        numChannels: 1,
        device: _selectedDevice,
      ),
      path: path,
    );
    await Future.delayed(windowDuration);
    final resultPath = await _recorder.stop();
    return resultPath ?? path;
  }

  Future<ChordPrediction> _predict(String filePath, String serverUrl) async {
    final uri = Uri.parse('$serverUrl/predict_chord');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('audio', filePath));

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 10));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      return ChordPrediction.error(
        'Servidor retornou erro ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ChordPrediction.fromJson(json);
  }
}
