import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:record/record.dart';

import '../models/chord_prediction.dart';

class ChordRecognitionService {
  static const Duration windowDuration = Duration(milliseconds: 1500);

  final AudioRecorder _recorder = AudioRecorder();
  bool _running = false;
  InputDevice? _selectedDevice;

  bool get isRunning => _running;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<List<InputDevice>> listInputDevices() => _recorder.listInputDevices();

  void selectDevice(InputDevice? device) {
    _selectedDevice = device;
  }

  void start({
    required String serverUrl,
    required void Function(ChordPrediction prediction) onPrediction,
    required void Function(Object error) onError,
  }) {
    if (_running) return;
    _running = true;
    _loop(serverUrl, onPrediction, onError);
  }

  Future<void> stop() async {
    _running = false;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

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
      String? filePath;
      try {
        filePath = await _recordWindow();
        if (!_running) break;
        final prediction = await _predict(filePath, serverUrl);
        if (_running) onPrediction(prediction);
      } catch (e) {
        if (_running) onError(e);
        await Future.delayed(const Duration(seconds: 1));
      } finally {
        if (filePath != null) {
          try {
            await File(filePath).delete();
          } catch (_) {}
        }
      }
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
