import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';

import '../../../config.dart';
import '../../../model/login_model.dart';
import '../../../translations/app_translations.dart';
import '../../../utils/stroage_manage.dart';

class AirprintSettingController extends GetxController {
  static AirprintSettingController get to => Get.find();
  final _service = FlutterBackgroundService();
  final StorageManage storageManage = StorageManage();
  //打印服务是否运行
  RxBool isRunning = false.obs;
  final box = StorageManage();
  @override
  void onInit() {
    checkServicRuning();
    super.onInit();
  }

  ///关闭打印服务
  Future closeService() async {
    var ret = await _service.isRunning();
    if (ret) {
      _service.invoke("stopService");
      isRunning.value = false;
    }
  }

  ///启动打印服务
  Future startService() async {
    UserData? loginUser = getLoginInfo();
    String? station = loginUser?.station;
    String? airprintStation = loginUser?.airPrintStation;
    if (station != airprintStation) {
      Get.defaultDialog(
        title: LocaleKeys.systemMessages.tr,
        content: Text(
          LocaleKeys.currentStationCannotSetUpAirprintService.trArgs(["$station"]),
        ),
        textConfirm: LocaleKeys.confirm.tr,
        onConfirm: () => Get.back(),
        barrierDismissible: false,
      );
      return;
    }

    var ret = await _service.isRunning();
    if (!ret) {
      _service.startService();
      isRunning.value = true;
    }
  }

  Future<void> checkServicRuning() async {
    isRunning.value = await _service.isRunning();
  }

  ///获取登录信息
  UserData? getLoginInfo() {
    var loginUserJson = box.read(Config.localStroageloginInfo);
    UserData? loginUser = loginUserJson != null ? UserData.fromJson(loginUserJson) : null;
    if (loginUser != null) {
      return loginUser;
    }
    return null;
  }
}
