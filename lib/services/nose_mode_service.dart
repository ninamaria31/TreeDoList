import 'dart:async';
import 'package:battery_info/enums/charging_status.dart';
import 'package:flutter/cupertino.dart';
import 'package:wakelock/wakelock.dart';
import '../settings/settings.dart';
import 'package:battery_info/battery_info_plugin.dart';

class TimerService {
  late Timer _timer;
  StreamController<int> _tickController = StreamController<int>.broadcast();
  final ValueNotifier<bool> _isRunning = ValueNotifier(false);
  bool isAllowed = true;

  TimerService(int noseModeDuration);

  Stream<int> get tickStream => _tickController.stream;
  ValueNotifier<bool> get isRunning => _isRunning;

  void startTimer() {
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

  void isNoseModeAllowed() async {
    var batteryLevel = (await BatteryInfoPlugin().androidBatteryInfo)?.batteryLevel;
    var chargingStatus = (await BatteryInfoPlugin().androidBatteryInfo)?.chargingStatus;
    if (chargingStatus == ChargingStatus.Charging) {
      isAllowed = true;
    } else if (batteryLevel! > 30) {
      isAllowed = true;
    } else {
      isAllowed = false;
    }
  }
}