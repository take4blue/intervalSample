import 'dart:async';
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'alarminterval.dart';
import 'awakeaction.dart';
import 'timerinterval.dart';
import 'workerinterval.dart';
import 'backgroundinterval.dart';

/// 呼び出す定期処理の種別
enum AlarmType {
  /// Android Alarm Manager
  alarm,

  /// Timer
  timer,

  /// WorkManager
  workmanager,

  /// Background service
  background,
}

/// 定時処理のインターフェース
abstract class IInterval {
  FutureOr<void> start();
  FutureOr<void> stop();
}

/// 間隔でタイマー処理[awake]を実行する
class IntervalTimer extends GetxController {
  IntervalTimer()
      : _type = canUse(AlarmType.alarm) ? AlarmType.alarm : AlarmType.timer;

  /// 定時処理の種類
  // ignore: prefer_final_fields
  AlarmType _type;

  AlarmType get type => _type;

  set type(AlarmType value) {
    if (canUse(value)) {
      _type = value;
    }
    update(["type", "parameter"]);
    update();
  }

  late TextEditingController text;

  /// 実際に処理を行う定時処理本体。
  late IInterval _interval;

  // 以下は機能ごとの定時処理オブジェクト。
  late TimerInterval _timer;
  late AlarmInterval _alarm;
  late WorkerInterval _worker;
  late BackgroundInterval background;

  final action = AwakeAction();

  List<String> get list => action.list;

  /// 定時処理を実行中かどうか
  bool _isStarted = false;

  bool get isStarted => _isStarted;

  /// 処理間隔
  Duration duration = const Duration(seconds: 20);

  /// 処理間隔変更。単位は秒。
  set interval(int value) {
    duration = Duration(seconds: value);
  }

  void setPeriodic(bool? value) {
    periodic = value ?? true;
    update(["type"]);
  }

  /// periodicな関数呼び出しで定期処理を実施するかどうか
  bool periodic = false;

  FutureOr<void> startStop() async {
    if (isStarted) {
      _stop();
    } else {
      action.clear();
      _start();
    }
    update();
  }

  /// 定時処理を開始する
  FutureOr<void> _start() async {
    _stop();
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
      case AlarmType.background:
        _interval = background;
        break;
    }
    _interval.start();
  }

  /// 定時処理を止める
  FutureOr<void> _stop() async {
    if (_isStarted) {
      _interval.stop();
      _isStarted = false;
    }
  }

  Future<void> awake() async {
    action.awake();
    if (!periodic) {
      _interval.start(); // 再スタートする
    }
    update();
  }

  /// ポートの初期化
  @override
  void onInit() {
    super.onInit();
    text = TextEditingController();
    text.text = "20";
    // Isolate側からの通信でawakeを呼び出すようにする
    port.listen((_) async => await awake());
    // 種類ごとの定期処理オブジェクト
    _timer = TimerInterval(this);
    _alarm = AlarmInterval(this);
    _worker = WorkerInterval(this);
    background = BackgroundInterval(this);
    background.initialize();
  }

  @override
  void onClose() {
    _stop(); // 後処理として定期処理を止めておく
    text.dispose();
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
      case AlarmType.background:
        return BackgroundInterval.canUse();
    }
  }
}
