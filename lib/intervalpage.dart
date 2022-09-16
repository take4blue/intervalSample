import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'intervaltimer.dart';

/// 定時処理のページ部分
class IntervalPage extends StatelessWidget {
  const IntervalPage({super.key, required this.title});

  final String title;
  @override
  Widget build(BuildContext context) {
    return GetBuilder<IntervalTimer>(
        builder: (timer) => Scaffold(
              appBar: AppBar(
                title: Text(title),
              ),
              body: Column(
                children: [
                  Row(
                    children: [
                      const TypeDrop(), // 定時処理機能の選択
                      const VerticalDivider(),
                      Expanded(
                        // 数値のみを入力可能なテキスト。
                        // キーボードで確定したらフォーカスを外す。
                        child: TextField(
                          controller: timer.text,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onEditingComplete: () {
                            final value = int.tryParse(timer.text.text);
                            if (value != null) {
                              timer.interval = value;
                            }
                            final FocusScopeNode currentScope =
                                FocusScope.of(context);
                            if (!currentScope.hasPrimaryFocus &&
                                currentScope.hasFocus) {
                              FocusManager.instance.primaryFocus?.unfocus();
                            }
                          },
                        ),
                      ),
                      const VerticalDivider(),
                      TextButton(
                          onPressed: timer.startStop,
                          child: Text(timer.isStarted ? "Stop" : "Start")),
                    ],
                  ),
                  if (ParameterBase.hasParameter(timer.type))
                    const ParameterBase(),
                  const Divider(),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(5)),
                      child: ListView.builder(
                        itemCount: timer.list.length,
                        itemBuilder: (context, index) =>
                            Text(timer.list[index]),
                      ),
                    ),
                  ),
                ],
              ),
            ));
  }
}

/// 定時処理機能の選択ウィジェット
class TypeDrop extends StatelessWidget {
  const TypeDrop({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<IntervalTimer>(
      id: "type",
      builder: (timer) => Row(children: [
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
            ),
            DropdownMenuItem<AlarmType>(
              value: AlarmType.background,
              enabled: IntervalTimer.canUse(AlarmType.background),
              child: const Text("Background"),
            ),
          ],
          onChanged: (value) => timer.type = value!,
          value: timer.type,
        ),
        Checkbox(value: timer.periodic, onChanged: timer.setPeriodic),
        const Text("periodic"),
      ]),
    );
  }
}

class ParameterBase extends StatelessWidget {
  const ParameterBase({super.key});

  Widget parameter(IntervalTimer timer) {
    switch (timer.type) {
      case AlarmType.alarm:
        return Container(
          key: ValueKey<AlarmType>(timer.type),
          width: 200.0,
          height: 23.0,
          color: Colors.green,
        );
      case AlarmType.timer:
        return Container(
          key: ValueKey<AlarmType>(timer.type),
          width: 200.0,
          height: 23.0,
          color: Colors.red,
        );
      case AlarmType.workmanager:
        return Container(
          key: ValueKey<AlarmType>(timer.type),
          width: 200.0,
          height: 23.0,
          color: Colors.lightBlue,
        );
      case AlarmType.background:
        return BackgroundParameters(
          key: ValueKey<AlarmType>(timer.type),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<IntervalTimer>(
      id: "parameter",
      builder: (timer) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: parameter(timer),
        );
      },
    );
  }

  static bool hasParameter(AlarmType type) {
    switch (type) {
      case AlarmType.alarm:
        return false;
      case AlarmType.timer:
        return false;
      case AlarmType.workmanager:
        return false;
      case AlarmType.background:
        return true;
    }
  }
}

class BackgroundParameters extends StatelessWidget {
  const BackgroundParameters({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<IntervalTimer>(
        id: "bpara",
        builder: (timer) {
          return Row(
            children: [
              const Text("Background service"),
              const VerticalDivider(),
              TextButton(
                  onPressed: () {
                    if (timer.background.isRunning) {
                      timer.background.stop();
                      timer.background.kill();
                    } else {
                      timer.background.execute();
                    }
                  },
                  child: Text(timer.background.isRunning ? "Stop" : "Start")),
            ],
          );
        });
  }
}
