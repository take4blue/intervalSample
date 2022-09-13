import 'dart:async';
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'alarminterval.dart';
import 'timerinterval.dart';
import 'workerinterval.dart';

/// 呼び出すアラームの種別
enum AlarmType {
  /// Android Alarm Manager
  alarm,

  /// Timer
  timer,

  /// WorkManager
  workmanager,
}

abstract class IInterval {
  FutureOr<void> start();
  FutureOr<void> stop();
}

/// 間隔でタイマー処理[awake]を実行する
class IntervalTimer extends GetxController {
  IntervalTimer(this.awake)
      : _type = canUse(AlarmType.alarm) ? AlarmType.alarm : AlarmType.timer;

  /// 発動しているアラームの種別
  // ignore: prefer_final_fields
  AlarmType _type;

  AlarmType get type => _type;

  set type(AlarmType value) {
    if (canUse(value)) {
      _type = value;
    }
  }

  late IInterval _interval;

  late TimerInterval _timer;
  late AlarmInterval _alarm;
  late WorkerInterval _worker;

  /// アラームを発動しているか
  bool _isStarted = false;

  bool get isStarted => _isStarted;

  /// 発動間隔
  Duration duration = const Duration(seconds: 20);

  /// 発動間隔変更。単位は秒。
  set interval(int value) {
    duration = Duration(seconds: value);
  }

  /// UI側で実行する関数
  void Function() awake;

  /// アラーム処理を開始する
  FutureOr<void> start() async {
    stop();
    _isStarted = true;
    switch (type) {
      case AlarmType.alarm:
        _interval = _alarm;
        break;
      case AlarmType.timer:
        _interval = _timer;
        break;
      case AlarmType.workmanager:
        _interval = _worker;
        break;
    }
    _interval.start();
  }

  /// 発動を止める
  FutureOr<void> stop() async {
    if (_isStarted) {
      _interval.stop();
      _isStarted = false;
    }
  }

  Future<void> _awake() async {
    awake();
    start();
  }

  /// ポートの初期化
  @override
  void onInit() {
    super.onInit();
    port.listen((_) async => await _awake());
    _timer = TimerInterval(this);
    _alarm = AlarmInterval(this);
    _worker = WorkerInterval(this);
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }

  /// A port used to communicate from a background isolate to the UI isolate.
  static final ReceivePort port = ReceivePort();

  /// The name associated with the UI isolate's [SendPort].
  static const String isolateName = 'isolate';

  /// パッケージの初期化関数
  static FutureOr<void> initialize() async {
    if (!kIsWeb && Platform.isAndroid) {
      final ans = await AndroidAlarmManager.initialize();
      debugPrint("initialize $ans");
      IsolateNameServer.registerPortWithName(
        port.sendPort,
        isolateName,
      );
    }
  }

  /// 指定したアラーム種別がこの機種で使用可能かどうかの判断
  static bool canUse(AlarmType type) {
    switch (type) {
      case AlarmType.alarm:
        return AlarmInterval.canUse();
      case AlarmType.timer:
        return TimerInterval.canUse();
      case AlarmType.workmanager:
        return WorkerInterval.canUse();
    }
  }
}
