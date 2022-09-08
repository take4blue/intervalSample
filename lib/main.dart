// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:optimize_battery/optimize_battery.dart';

/// The name associated with the UI isolate's [SendPort].
const String isolateName = 'isolate';

/// A port used to communicate from a background isolate to the UI isolate.
final ReceivePort port = ReceivePort();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isAndroid) {
    AndroidAlarmManager.initialize();
  }
  if (Platform.isAndroid) {
    final isIgnored = await OptimizeBattery.isIgnoringBatteryOptimizations();
    if (!isIgnored) {
      await OptimizeBattery.stopOptimizingBatteryUsage();
    }
  }

  // Register the UI isolate's SendPort to allow for communication from the
  // background isolate.
  IsolateNameServer.registerPortWithName(
    port.sendPort,
    isolateName,
  );

  runApp(const AlarmManagerExampleApp());
}

/// Example app for Espresso plugin.
class AlarmManagerExampleApp extends StatelessWidget {
  const AlarmManagerExampleApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: _AlarmHomePage(title: 'Alarm Manager demo'),
    );
  }
}

class _AlarmHomePage extends StatefulWidget {
  const _AlarmHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _AlarmHomePageState createState() => _AlarmHomePageState();
}

/// 呼び出すアラームの種別
enum AlarmType {
  /// Android Alarm Manager
  alarm,

  /// Timer
  timer,
}

class _AlarmHomePageState extends State<_AlarmHomePage> {
  /// リストに表示するタイムスタンプ情報
  final _list = <String>[];

  /// タイムスタンプの時刻フォーマット
  static DateFormat formatter = DateFormat('yyyy-MM-dd hh:mm:ss');

  /// 前回発動してからの経過時間を求めるための前回の時刻
  var _prev = DateTime.now();

  /// 発動しているアラームの種別
  AlarmType _type = AlarmType.alarm;

  /// Alarm Managerの識別番号
  static int kAlarmId = 0;

  /// Timer設定時のオブジェクト
  Timer? _timer;

  /// アラームを発動しているか
  bool isStarted = false;

  /// 発動間隔
  Duration interval = const Duration(seconds: 20);

  late TextEditingController _controller;

  /// 次回のアラーム設定をする
  FutureOr<void> _oneShot() async {
    isStarted = true;
    switch (_type) {
      case AlarmType.alarm:
        await AndroidAlarmManager.oneShot(
          interval,
          kAlarmId,
          callback,
          exact: true,
          wakeup: true,
          allowWhileIdle: true,
        );
        break;
      case AlarmType.timer:
        _timer = Timer(interval, _awake);
        break;
    }
  }

  /// 発動を止める
  FutureOr<void> _stop() async {
    if (isStarted) {
      switch (_type) {
        case AlarmType.alarm:
          await AndroidAlarmManager.cancel(kAlarmId);
          break;
        case AlarmType.timer:
          if (_timer != null) {
            _timer!.cancel();
          }
          break;
      }
      isStarted = false;
      setState(() {});
    }
  }

  /// アラームの再設定
  FutureOr<void> _restart(AlarmType type) async {
    await _stop();
    setState(() {
      _type = type;
      _list.clear();
    });
    _prev = DateTime.now();
    await _oneShot();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.text = "20";
    port.listen((_) async => await _awake());
    _type = (!kIsWeb && Platform.isAndroid) ? AlarmType.alarm : AlarmType.timer;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// アラームからの呼び出し
  Future<void> _awake() async {
    developer.log('awake');
    final now = DateTime.now();
    final span = now.difference(_prev);
    setState(() {
      _list.insert(0, "${formatter.format(now.toLocal())}  ${span.inSeconds}");
    });
    _prev = now;
    _oneShot();
  }

  /// callbackからUIへのポート
  static SendPort? uiSendPort;

  /// アラームの起動関数。
  /// 起動された後、ポート経由でポートリッスン中の[_awake]が呼び出される。
  static Future<void> callback() async {
    developer.log('Alarm fired!');

    // This will be null if we're running in the background.
    uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
    uiSendPort?.send(null);
  }

  /// ラジオボタンのコールバック
  void setRadio(AlarmType? select) {
    _restart(select ?? AlarmType.alarm);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Row(
            children: [
              Radio<AlarmType>(
                value: AlarmType.alarm,
                groupValue: _type,
                onChanged: (!kIsWeb && Platform.isAndroid) ? setRadio : null,
              ),
              const Text("Alarm"),
              Radio<AlarmType>(
                value: AlarmType.timer,
                groupValue: _type,
                onChanged: setRadio,
              ),
              const Text("Timer"),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onEditingComplete: () {
                    final value = int.tryParse(_controller.text);
                    if (value != null) {
                      interval = Duration(seconds: value);
                    }
                    final FocusScopeNode currentScope = FocusScope.of(context);
                    if (!currentScope.hasPrimaryFocus &&
                        currentScope.hasFocus) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    }
                  },
                ),
              ),
              TextButton(
                  onPressed: () {
                    if (isStarted) {
                      _stop();
                    } else {
                      _restart(_type);
                    }
                  },
                  child: Text(isStarted ? "Stop" : "Start")),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _list.length,
              itemBuilder: (context, index) => Text(_list[index]),
            ),
          ),
        ],
      ),
    );
  }
}
