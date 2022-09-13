import 'dart:async';

import 'intervaltimer.dart';

/// タイマーを使ったインターバル処理クラス
class TimerInterval extends IInterval {
  TimerInterval(this.timer);
  final IntervalTimer timer;

  /// Timer設定時のオブジェクト
  Timer? _id;

  @override
  FutureOr<void> start() {
    _id = Timer(timer.duration, () {
      timer.awake();
      timer.start();
    });
  }

  @override
  FutureOr<void> stop() {
    if (_id != null) {
      _id!.cancel();
    }
  }

  static bool canUse() {
    return true;
  }
}
