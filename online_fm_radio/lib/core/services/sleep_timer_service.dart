import 'dart:async';

import 'package:flutter/foundation.dart';

class SleepTimerService extends ChangeNotifier {
  Timer? _timer;
  Duration? _remaining;
  bool _isActive = false;

  Duration? get remaining => _remaining;
  bool get isActive => _isActive;

  void start(Duration duration) {
    cancel();

    _remaining = duration;
    _isActive = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining != null && _remaining! > Duration.zero) {
        _remaining = _remaining! - const Duration(seconds: 1);
        notifyListeners();
      } else {
        _complete();
      }
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _remaining = null;
    _isActive = false;
    notifyListeners();
  }

  void _complete() {
    _timer?.cancel();
    _timer = null;
    _remaining = Duration.zero;
    _isActive = false;
    notifyListeners();
  }

  bool get isCompleted => !_isActive && _remaining == Duration.zero;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}