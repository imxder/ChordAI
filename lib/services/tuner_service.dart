import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'pitch_detector.dart';

class TunerService {
  static const int sampleRate = 22050;
  static const int _windowSizeSamples = 4096;

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _subscription;
  final List<int> _byteBuffer = [];

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
    const windowBytes = _windowSizeSamples * 2;

    _subscription = stream.listen((chunk) {
      _byteBuffer.addAll(chunk);
      while (_byteBuffer.length >= windowBytes) {
        final windowBytesList = _byteBuffer.sublist(0, windowBytes);
        _byteBuffer.removeRange(0, windowBytes);
        final samples = _bytesToFloatSamples(windowBytesList);
        onPitch(detectPitch(samples, sampleRate.toDouble()));
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
