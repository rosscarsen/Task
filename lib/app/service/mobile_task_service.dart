import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../model/login_model.dart';
import 'print_method.dart';
import 'service_globals.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      autoStartOnBoot: false,
    ),
    iosConfiguration: IosConfiguration(autoStart: false, onForeground: onStart, onBackground: onIosBackground),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  printStatus = true;
  printKitchenErrorCount = 0; // 初始化打印错误计数器
  debugPrint("开始服务:$printStatus");
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  UserData? cachedLoginUser;

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

  // 初始化缓存数据
  await updateCachedData();

  // 设置前台服务
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      debugPrint("设置前台服务");
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      debugPrint("设置后台服务");
      service.setAsBackgroundService();
    });
  }

  // 监听停止服务事件
  service.on('stopService').listen((event) {
    printStatus = false;
    printKitchenErrorCount = 0; // 初始化打印错误计数器
    debugPrint("停止服务:$printStatus");
    if (timer != null && timer!.isActive) {
      timer?.cancel();
    }
    if (cacheTimer != null && cacheTimer!.isActive) {
      cacheTimer?.cancel();
    }
    service.stopSelf();
  });

  // 更改打印语言
  service.on('updatePrintLang').listen((event) {
    printlang = event?['lang'] ?? "zh_HK";
  });

  // 获取数据定时器存在则关闭它
  if (timer != null && timer!.isActive) {
    timer!.cancel();
  }

  // 启动打印定时任务
  timer = Timer.periodic(const Duration(seconds: 5), (t) async {
    // debugPrint("===>$printlang");
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

      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: "Printer Service running",
            content: "Updated at ${DateTime.now()}",
          );
        }
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

  // 缓存定时器存在则关闭它
  if (cacheTimer != null && cacheTimer!.isActive) {
    cacheTimer!.cancel();
  }
  // 定期刷新缓存数据
  cacheTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
    await updateCachedData();
  });
}
