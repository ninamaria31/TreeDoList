import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:wakelock/wakelock.dart';
import '../settings/settings.dart';

class TimerService {
  late Timer _timer;
  StreamController<int> _tickController = StreamController<int>.broadcast();
  final ValueNotifier<bool> _isRunning = ValueNotifier(false);

  TimerService(int noseModeDuration);

  Stream<int> get tickStream => _tickController.stream;
  ValueNotifier<bool> get isRunning => _isRunning;

  void startTimer() {
    print("#");
    print(noseModeDuration);
    if (!_isRunning.value) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // Pass the remaining time to the stream
        _tickController.add((noseModeDuration - timer.tick) as int);
      });
      _isRunning.value = true;
      Wakelock.enable();
    }
  }

  void stopTimer() {
    if (_isRunning.value) {
      _timer.cancel();
      _isRunning.value = false;
      Wakelock.disable();
      resetTimer();
    }
  }

  void resetTimer() {
    _tickController.add(noseModeDuration.toInt());
  }

  void dispose() {
    _timer.cancel();
    _tickController.close();
    _isRunning.dispose();
  }
}