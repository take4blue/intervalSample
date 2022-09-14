import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optimize_battery/optimize_battery.dart';

import 'intervalpage.dart';
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
  runApp(GetMaterialApp(
    title: 'Flutter Demo',
    home: const IntervalPage(title: 'Alarm Manager demo'),
    initialBinding:
        BindingsBuilder(() => Get.put<IntervalTimer>(IntervalTimer())),
  ));
}
