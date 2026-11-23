import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../state/app_state.dart';

enum AppSound {
  clickStrong('assets/sounds/click_forte.wav'),
  click('assets/sounds/click.wav'),
  chordLearned('assets/sounds/acorde_aprendido.wav'),
  inTune('assets/sounds/afinado.wav');

  final String asset;

  const AppSound(this.asset);
}

abstract class SoundOutput {
  Future<void> prepare();

  void play(AppSound sound);
}

class SoloudOutput implements SoundOutput {
  final _sources = <AppSound, AudioSource>{};
  Future<void>? _loading;

  @override
  Future<void> prepare() => _loading ??= _load().catchError((_) {
    _loading = null;
  });

  Future<void> _load() async {
    final soloud = SoLoud.instance;
    if (!soloud.isInitialized) await soloud.init(bufferSize: 512);
    for (final sound in AppSound.values) {
      _sources[sound] ??= await soloud.loadAsset(sound.asset);
    }
  }

  @override
  void play(AppSound sound) {
    final source = _sources[sound];
    if (source == null) {
      prepare();
      return;
    }
    try {
      SoLoud.instance.play(source);
    } catch (_) {}
  }
}

class AppSounds {
  final SoundOutput _output;

  AppSounds({SoundOutput? output}) : _output = output ?? SoloudOutput();

  bool get prepareAtLaunch => defaultTargetPlatform == TargetPlatform.macOS;

  Future<void> prepare() => _output.prepare();

  void playClick({required bool strong}) {
    if (!appState.metronomeSound) return;
    _play(strong ? AppSound.clickStrong : AppSound.click);
  }

  void playChordLearned() => _play(AppSound.chordLearned);

  void playInTune() => _play(AppSound.inTune);

  void _play(AppSound sound) {
    if (!appState.soundsEnabled) return;
    _output.play(sound);
  }
}

AppSounds appSounds = AppSounds();
