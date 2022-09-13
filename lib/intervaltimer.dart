import 'dart:async';
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';

/// 呼び出すアラームの種別
enum AlarmType {
  /// Android Alarm Manager
  alarm,

  /// Timer
  timer,
}

/// 間隔でタイマー処理[awake]を実行する
class IntervalTimer {
  IntervalTimer(this.awake)
      : type = canUse(AlarmType.alarm) ? AlarmType.alarm : AlarmType.timer;

  /// 発動しているアラームの種別
  AlarmType type;

  /// Alarm Managerの識別番号
  static int kAlarmId = 0;

  /// Timer設定時のオブジェクト
  Timer? _timer;

  /// アラームを発動しているか
  bool _isStarted = false;

  bool get isStarted => _isStarted;

  /// 発動間隔
  Duration _interval = const Duration(seconds: 20);

  /// 発動間隔変更
  set interval(int second) {
    _interval = Duration(seconds: second);
  }

  /// UI側で実行する関数
  void Function() awake;

  /// 次回のアラーム設定をする
  FutureOr<void> oneShot() async {
    _isStarted = true;
    switch (type) {
      case AlarmType.alarm:
        await AndroidAlarmManager.oneShot(
          _interval,
          kAlarmId,
          callback,
          exact: true,
          wakeup: true,
          allowWhileIdle: true,
        );
        break;
      case AlarmType.timer:
        _timer = Timer(_interval, _awake);
        break;
    }
  }

  /// 発動を止める
  FutureOr<void> stop() async {
    if (_isStarted) {
      switch (type) {
        case AlarmType.alarm:
          await AndroidAlarmManager.cancel(kAlarmId);
          break;
        case AlarmType.timer:
          if (_timer != null) {
            _timer!.cancel();
          }
          break;
      }
      _isStarted = false;
    }
  }

  /// アラームの再設定。
  /// [type]が設定不可の場合は、種別変更せずに再スタートする。
  FutureOr<void> restart(AlarmType type) async {
    await stop();
    if (canUse(type)) {
      type = type;
    }
    await oneShot();
  }

  Future<void> _awake() async {
    awake();
    oneShot();
  }

  /// ポートの初期化
  void initState() {
    port.listen((_) async => await _awake());
  }

  /// callbackからUIへのポート
  static SendPort? uiSendPort;

  /// アラームの起動関数。
  /// 起動された後、ポート経由でポートリッスン中の[_awake]が呼び出される。
  static Future<void> callback() async {
    uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
    uiSendPort?.send(null);
  }

  /// The name associated with the UI isolate's [SendPort].
  static const String isolateName = 'isolate';

  /// A port used to communicate from a background isolate to the UI isolate.
  static final ReceivePort port = ReceivePort();

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
        return (!kIsWeb && Platform.isAndroid) ? true : false;
      case AlarmType.timer:
        return true;
    }
  }
}
