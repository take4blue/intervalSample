import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
  runApp(const GetMaterialApp(
    title: 'Flutter Demo',
    home: _AlarmHomePage(title: 'Alarm Manager demo'),
  ));
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

  late IntervalTimer timer;

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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.text = "20";
    timer = Get.put<IntervalTimer>(IntervalTimer(awake));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ラジオボタンのコールバック
  void _setRadio(AlarmType? select) {
    setState(() {
      timer.type = select!;
    });
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
              DropdownButton<AlarmType>(
                items: [
                  DropdownMenuItem<AlarmType>(
                    value: AlarmType.alarm,
                    enabled: IntervalTimer.canUse(AlarmType.alarm),
                    child: const Text("Alarm"),
                  ),
                  const DropdownMenuItem<AlarmType>(
                    value: AlarmType.timer,
                    child: Text("Timer"),
                  ),
                  DropdownMenuItem<AlarmType>(
                    value: AlarmType.workmanager,
                    enabled: IntervalTimer.canUse(AlarmType.workmanager),
                    child: const Text("WorkManager"),
                  )
                ],
                onChanged: _setRadio,
                value: timer.type,
              ),
              const SizedBox(
                width: 10,
              ),
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
                    } else {
                      timer.start();
                      _list.clear();
                      _prev = DateTime.now();
                      _list.insert(0, formatter.format(_prev.toLocal()));
                    }
                    setState(() {});
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
