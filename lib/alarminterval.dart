import 'dart:async';
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';

import 'intervaltimer.dart';

class AlarmInterval extends IInterval {
  AlarmInterval(this.timer);
  final IntervalTimer timer;

  /// Alarm Managerの識別番号
  static int kAlarmId = 0;

  /// callbackからUIへのポート
  static SendPort? uiSendPort;

  /// アラームの起動関数。
  /// 起動された後、ポート経由でポートリッスン中の[_awake]が呼び出される。
  static Future<void> alarmCallback() async {
    uiSendPort ??=
        IsolateNameServer.lookupPortByName(IntervalTimer.isolateName);
    uiSendPort?.send(null);
  }

  @override
  FutureOr<void> start() async {
    await AndroidAlarmManager.oneShot(
      timer.duration,
      kAlarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
    );
  }

  @override
  FutureOr<void> stop() async {
    await AndroidAlarmManager.cancel(kAlarmId);
  }

  static bool canUse() {
    return (!kIsWeb && Platform.isAndroid) ? true : false;
  }
}
