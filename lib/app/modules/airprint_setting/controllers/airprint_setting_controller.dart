import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';

import '../../../config.dart';
import '../../../model/login_model.dart';
import '../../../service/win32_task_service.dart';
import '../../../translations/app_translations.dart';
import '../../../utils/storage_manage.dart';

class AirprintSettingController extends GetxController with WidgetsBindingObserver {
  static AirprintSettingController get to => Get.find();
  final _service = FlutterBackgroundService();
  final StorageManage storageManage = StorageManage();
  //打印服务是否运行
  RxBool isRunning = false.obs;
  final box = StorageManage();
  @override
  void onInit() {
    WidgetsBinding.instance.addObserver(this);
    checkServicRuning();
    super.onInit();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.detached) {
      await closeService();
    }
    super.didChangeAppLifecycleState(state);
  }

  ///关闭打印服务
  Future closeService() async {
    if (Platform.isAndroid || Platform.isIOS) {
      var ret = await _service.isRunning();
      if (ret) {
        _service.invoke("stopService");
        isRunning.value = false;
      }
    }
    if (Platform.isWindows) {
      await win32StopTask();
      await checkServicRuning();
    }
    storageManage.save(Config.localStorageStartTask, false);
  }

  ///启动打印服务
  Future startService() async {
    UserData? loginUser = getLoginInfo();
    String? station = loginUser?.station;
    String? airprintStation = loginUser?.airPrintStation;
    if (station != airprintStation) {
      Get.defaultDialog(
        title: LocaleKeys.systemMessages.tr,
        content: Text(LocaleKeys.currentStationCannotSetUpAirprintService.trArgs(["$station"])),
        textConfirm: LocaleKeys.confirm.tr,
        onConfirm: () => Get.back(),
        barrierDismissible: false,
      );
      return;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      var ret = await _service.isRunning();
      if (!ret) {
        _service.startService();
        isRunning.value = true;
      }
    }
    if (Platform.isWindows) {
      await win32StartTask(Get.locale?.toString() ?? "zh_HK");
      await checkServicRuning();
    }
    storageManage.save(Config.localStorageStartTask, true);
  }

  Future<void> checkServicRuning() async {
    if (Platform.isAndroid || Platform.isIOS) {
      isRunning.value = await _service.isRunning();
    }
    if (Platform.isWindows) {
      isRunning.value = win32TimerIsRunning();
    }
  }

  ///获取登录信息
  UserData? getLoginInfo() {
    var loginUserJson = box.read(Config.localStorageLoginInfo);
    UserData? loginUser = loginUserJson != null ? UserData.fromJson(loginUserJson) : null;
    if (loginUser != null) {
      return loginUser;
    }
    return null;
  }
}
