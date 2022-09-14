import 'dart:async';
import 'dart:developer' as developer;

import 'package:intl/intl.dart';

/// 起動される処理を行うクラス
class AwakeAction {
  final list = <String>[];

  /// タイムスタンプの時刻フォーマット
  static DateFormat formatter = DateFormat('yyyy-MM-dd hh:mm:ss');

  /// 前回発動してからの経過時間を求めるための前回の時刻
  var _prev = DateTime.now();

  FutureOr<void> awake() async {
    developer.log('awake');
    final now = DateTime.now();
    final span = now.difference(_prev);
    list.insert(0, "${formatter.format(now.toLocal())}  ${span.inSeconds}");
    _prev = now;
  }

  /// 表示データのクリア
  FutureOr<void> clear() {
    list.clear();
    _prev = DateTime.now();
    list.insert(0, formatter.format(_prev.toLocal()));
  }
}
