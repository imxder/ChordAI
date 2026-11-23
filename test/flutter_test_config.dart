import 'dart:async';

import 'package:chordai/services/app_sounds.dart';

import 'test_helpers.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  appSounds = AppSounds(output: FakeSoundOutput());
  await testMain();
}
