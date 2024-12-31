import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:win32/win32.dart';

import '../model/login_model.dart';
import 'print_method.dart';
import 'service_globals.dart';

UserData? cachedLoginUser;
// 防止电脑进入睡眠状态
void preventSleep() {
  // 设置线程执行状态，防止电脑进入睡眠状态
  SetThreadExecutionState(
      EXECUTION_STATE.ES_CONTINUOUS | EXECUTION_STATE.ES_SYSTEM_REQUIRED | EXECUTION_STATE.ES_AWAYMODE_REQUIRED);
}

// 允许睡眠
void allowSleep() {
  // 设置线程执行状态为连续执行
  SetThreadExecutionState(EXECUTION_STATE.ES_CONTINUOUS);
}

// 定义一个函数，用于启动Windows任务
Future<void> win32StartTask() async {
  printStatus = true;
  printKitchenErrorCount = 0; // 初始化打印错误计数器
  final bool isRunning = win32TimerIsRunning();
  if (!isRunning) {
    // 阻止系统休眠
    preventSleep();
    //显示托盘图标
    await showIcon();
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }
    await updateCachedData();
    timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        // 如果缓存数据为空，尝试重新获取
        if (cachedLoginUser == null) {
          await updateCachedData();
          if (cachedLoginUser == null) {
            debugPrint("无法获取登录信息，跳过本次任务");
            return;
          }
        }

        final station = cachedLoginUser?.station;
        final airprintStation = cachedLoginUser?.airPrintStation;

        // 检查数据一致性
        if (station == null || airprintStation == null || station != airprintStation) {
          debugPrint("本地信息为空或打印机信息不一致");
          return;
        }

        debugPrint("打印状态：$printStatus");
        if (printStatus) {
          printStatus = false;
          getPrintData(queryData: cachedLoginUser!.toJson());
        }
      } catch (e) {
        debugPrint("后台任务异常: $e");
      }
    });

    // 定期刷新缓存数据
    if (cacheTimer != null && cacheTimer!.isActive) {
      cacheTimer?.cancel();
    }
    cacheTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await updateCachedData();
    });
  }
}

Future<void> updateCachedData() async {
  int retryCount = 0;
  const maxRetry = 3;
  while (retryCount < maxRetry) {
    try {
      cachedLoginUser = await getLoginInfo();
      if (cachedLoginUser != null) break;
    } catch (e) {
      debugPrint("更新缓存数据失败: $e");
    }
    retryCount++;
    await Future.delayed(const Duration(seconds: 2));
  }
  if (cachedLoginUser == null) {
    debugPrint("多次尝试后仍无法获取登录信息");
  } else {
    debugPrint("缓存数据更新完成: ${cachedLoginUser?.toJson()}");
  }
}

Future<void> win32StopTask() async {
  printStatus = false;
  printKitchenErrorCount = 0; // 初始化打印错误计数器
  final bool isRunning = win32TimerIsRunning(); // 检查timer是否在运行
  if (isRunning) {
    // 允许系统休眠
    allowSleep();

    // 关闭托盘图标
    await closeIcon();

    // 停止定时器
    if (timer != null && timer!.isActive) {
      timer?.cancel();
    }
    if (cacheTimer != null && cacheTimer!.isActive) {
      cacheTimer?.cancel();
    }
  }
}

//检测timer是否在运行
bool win32TimerIsRunning() {
  return timer != null && timer!.isActive;
}

// 异步函数，用于显示图标
Future<void> showIcon() async {
  // 设置托盘图标为leaf.ico
  await TrayManager.instance.setIcon('assets/print.ico');
  // 设置托盘提示信息为Task Airprint Running
  await TrayManager.instance.setToolTip("Task Airprint Running");
}

// 关闭托盘图标
Future<void> closeIcon() async {
  TrayManager.instance.destroy();
}
