import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'intervaltimer.dart';

// バックグラウンドからの通信キーワード
const _kMCommand = "cmd"; // サーバーへのコマンド送付のメソッド名
const _kTFunction = "func"; // サーバーへの関数のタグ名
const _kFStart = "start"; // 定時処理起動
const _kFKill = "kill"; // Isolate終了
const _kFStop = "stop"; // 定時処理終了

class BackgroundInterval extends IInterval {
  BackgroundInterval(this.timer);
  final IntervalTimer timer;

  bool isRunning = false;

  @override
  FutureOr<void> start() async {
    _service.invoke(_kMCommand, {
      _kTFunction: _kFStart,
      "interval": timer.duration.inSeconds,
      "periodic": timer.periodic
    });
  }

  @override
  FutureOr<void> stop() async {
    _service.invoke(_kMCommand, {_kTFunction: _kFStop});
  }

  /// サービスの停止
  FutureOr<void> kill() {
    debugPrint("kill");
    _service.invoke(_kMCommand, {_kTFunction: _kFKill});
    isRunning = false;
    timer.update(["bpara"]);
  }

  /// サービスの開始
  FutureOr<void> execute() async {
    // サービススタート
    debugPrint("start = ${await _service.startService()}");
    isRunning = true;
    timer.update(["bpara"]);
  }

  late FlutterBackgroundService _service;

  /// バックグラウンド処理の初期化
  FutureOr<void> initialize() async {
    if (Platform.isWindows) {
      // Windows用の初期設定
      // AsyncBackgroundService.registerWith();
    }

    // サービス初期化
    _service = FlutterBackgroundService();
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: backgroundFunc,
        autoStart: false,
        isForegroundMode: true,
      ),
      iosConfiguration: IosConfiguration(
        // auto start service
        onForeground: backgroundFunc,
        autoStart: false,
        onBackground: (service) {
          WidgetsFlutterBinding.ensureInitialized();
          return true;
        },
      ),
    );

    // サーバーからコマンド受け取ったら[awake]を呼び出す
    _service.on(_kMCommand).listen((event) {
      timer.awake();
    });

    isRunning = await _service.isRunning();
  }

  /// バックグラウンド側の処理ルーチン
  static void backgroundFunc(ServiceInstance val) async {
    debugPrint("backgroundFunc");
    Timer? timer;
    val.on(_kMCommand).listen((event) {
      switch (event![_kTFunction]) {
        case _kFKill:
          debugPrint("kill");
          val.stopSelf();
          break;

        case _kFStop:
          timer?.cancel();
          timer = null;
          debugPrint("stop");
          break;

        case _kFStart:
          final interval = event["interval"];
          final periodic = event["periodic"];
          final duration = Duration(seconds: interval);
          timer?.cancel();
          if (periodic) {
            debugPrint("periodic");
            timer = Timer.periodic(
                duration,
                (_) => val.invoke(
                      _kMCommand,
                    ));
          } else {
            debugPrint("not periodic");
            timer = Timer(duration, () {
              val.invoke(
                _kMCommand,
              );
              debugPrint("next");
            });
          }
          break;
      }
    });
  }

  static bool canUse() {
    return (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) ? true : false;
  }
}
