// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:optimize_battery/optimize_battery.dart';

import 'intervaltimer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  IntervalTimer.initialize();
  if (Platform.isAndroid) {
    final isIgnored = await OptimizeBattery.isIgnoringBatteryOptimizations();
    if (!isIgnored) {
      await OptimizeBattery.stopOptimizingBatteryUsage();
    }
  }
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

class _AlarmHomePageState extends State<_AlarmHomePage> {
  /// リストに表示するタイムスタンプ情報
  final _list = <String>[];

  /// タイムスタンプの時刻フォーマット
  static DateFormat formatter = DateFormat('yyyy-MM-dd hh:mm:ss');

  /// 前回発動してからの経過時間を求めるための前回の時刻
  var _prev = DateTime.now();

  late IntervalTimer timer = IntervalTimer(awake);

  FutureOr<void> awake() async {
    developer.log('awake');
    final now = DateTime.now();
    final span = now.difference(_prev);
    setState(() {
      _list.insert(0, "${formatter.format(now.toLocal())}  ${span.inSeconds}");
    });
    _prev = now;
  }

  late TextEditingController _controller;

  /// アラームの再設定
  FutureOr<void> _restart(AlarmType type) async {
    timer.restart(type);
    setState(() {
      _list.clear();
      final now = DateTime.now();
      _list.insert(0, formatter.format(now.toLocal()));
      _prev = DateTime.now();
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.text = "20";
    timer.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ラジオボタンのコールバック
  void _setRadio(AlarmType? select) {
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
                groupValue: timer.type,
                onChanged:
                    IntervalTimer.canUse(AlarmType.alarm) ? _setRadio : null,
              ),
              const Text("Alarm"),
              Radio<AlarmType>(
                value: AlarmType.timer,
                groupValue: timer.type,
                onChanged: _setRadio,
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
                      timer.interval = value;
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
                    if (timer.isStarted) {
                      timer.stop();
                      setState(() {});
                    } else {
                      _restart(timer.type);
                    }
                  },
                  child: Text(timer.isStarted ? "Stop" : "Start")),
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
