// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optimize_battery/optimize_battery.dart';

/// The name associated with the UI isolate's [SendPort].
const String isolateName = 'isolate';

/// A port used to communicate from a background isolate to the UI isolate.
final ReceivePort port = ReceivePort();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AndroidAlarmManager.initialize();
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
      home: _AlarmHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class _AlarmHomePage extends StatefulWidget {
  const _AlarmHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _AlarmHomePageState createState() => _AlarmHomePageState();
}

class _AlarmHomePageState extends State<_AlarmHomePage> {
  final _list = <String>[];
  final formatter = DateFormat('yyyy-MM-dd hh:mm:ss');
  var _prev = DateTime.now();

  static FutureOr<void> _oneShot() async {
    await AndroidAlarmManager.oneShot(
      const Duration(seconds: 20),
      Random().nextInt(pow(2, 31) as int),
      callback,
      alarmClock: true,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
    );
  }

  @override
  void initState() {
    super.initState();
    port.listen((_) async => await _awake());
    _oneShot();
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

  // The background
  static SendPort? uiSendPort;

  /// アラームの機動関数。
  /// 起動された後、ポート経由でポートリッスン中の[_awake]が呼び出される。
  static Future<void> callback() async {
    developer.log('Alarm fired!');

    // This will be null if we're running in the background.
    uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
    uiSendPort?.send(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: _list.length,
        itemBuilder: (context, index) => Text(_list[index]),
      ),
    );
  }
}
