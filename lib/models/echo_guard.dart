import 'dart:async';

class EchoGuard {
  Timer? _timer;

  bool get active => _timer?.isActive ?? false;

  void hold(Duration duration) {
    _timer?.cancel();
    _timer = Timer(duration, () {});
  }

  void release() => _timer?.cancel();

  void dispose() => _timer?.cancel();
}
