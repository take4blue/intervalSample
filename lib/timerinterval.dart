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
    if (timer.periodic) {
      _id = Timer.periodic(timer.duration, (_) => timer.awake());
    } else {
      _id = Timer(timer.duration, timer.awake);
    }
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
