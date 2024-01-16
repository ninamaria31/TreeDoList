import 'dart:async';
import 'package:battery_info/enums/charging_status.dart';
import 'package:flutter/cupertino.dart';
import 'package:wakelock/wakelock.dart';
import '../settings/settings.dart';
import 'package:battery_info/battery_info_plugin.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';


class TimerService {
  late Timer _timer;
  StreamController<int> _tickController = StreamController<int>.broadcast();
  final ValueNotifier<bool> _isRunning = ValueNotifier(false);
  bool isAllowed = true;
  late double _initialBrightness;

  TimerService(int noseModeDuration);

  Stream<int> get tickStream => _tickController.stream;
  ValueNotifier<bool> get isRunning => _isRunning;

  Future<void> startTimer() async {
    if (!_isRunning.value) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // Pass the remaining time to the stream
        var ticks = noseModeDuration - timer.tick;
        _tickController.add(ticks);
        if (ticks < 0) {
        stopTimer();
        return;
        }
      });
      _isRunning.value = true;
      _initialBrightness = await ScreenBrightnessPlatform.instance.current;
      Wakelock.enable();
      await ScreenBrightnessPlatform.instance.setScreenBrightness(0.3);
    }
  }

  Future<void> stopTimer() async {
    if (_isRunning.value) {
      _timer.cancel();
      _isRunning.value = false;
      await ScreenBrightnessPlatform.instance.setScreenBrightness(_initialBrightness);
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