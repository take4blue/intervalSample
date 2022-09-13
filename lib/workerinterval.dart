import 'dart:async';
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'intervaltimer.dart';

/// WorkManagerのユニーク名とタスク名(同じのを使用する)
const String workName = "workName";

/// callbackからUIへのポート
SendPort? uiSendPort;

/// WorkManagerの起動関数
void workCallback() {
  Workmanager().executeTask((task, inputData) {
    debugPrint(task);
    switch (task) {
      case workName:
        uiSendPort ??=
            IsolateNameServer.lookupPortByName(IntervalTimer.isolateName);
        uiSendPort?.send(null);
        break;
    }
    return Future.value(true);
  });
}

class WorkerInterval extends IInterval {
  WorkerInterval(this.timer) {
    initialize();
  }
  final IntervalTimer timer;

  static void initialize() {
    Workmanager().initialize(
      workCallback,
    );
  }

  @override
  FutureOr<void> start() async {
    await Workmanager().registerOneOffTask(
      workName,
      workName,
      initialDelay: timer.duration,
    );
  }

  @override
  FutureOr<void> stop() async {
    await Workmanager().cancelAll();
  }

  static bool canUse() {
    return (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) ? true : false;
  }
}
