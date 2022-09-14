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
                      const SizedBox(
                        width: 10,
                      ),
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
                      TextButton(
                          onPressed: timer.startStop,
                          child: Text(timer.isStarted ? "Stop" : "Start")),
                    ],
                  ),
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
            )
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
