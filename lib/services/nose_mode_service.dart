import 'dart:async';
import 'package:wakelock/wakelock.dart';

class TimerService {
  late Timer _timer;
  late bool _isRunning;

  TimerService() : _isRunning = false;

  void startTimer(Function (int) callback) {
    if (!_isRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // Pass the timer tick count to the callback function
        callback(timer.tick);
      });
      _isRunning = true;
      Wakelock.enable();
    }
  }

  void stopTimer() {
    if (_isRunning) {
      _timer.cancel();
      _isRunning = false;
      Wakelock.disable();
    }
  }

  bool isRunning() => _isRunning;
}
