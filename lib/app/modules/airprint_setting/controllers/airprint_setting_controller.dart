import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';

import '../../../utils/stroage_manage.dart';

class AirprintSettingController extends GetxController {
  static AirprintSettingController get to => Get.find();
  final _service = FlutterBackgroundService();
  final StorageManage storageManage = StorageManage();
  //打印服务是否运行
  RxBool isRunning = false.obs;
  Rx<Locale> locale = const Locale("zh", "HK").obs;
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
    var ret = await _service.isRunning();
    if (!ret) {
      _service.startService();
      isRunning.value = true;
    }
  }

  Future<void> checkServicRuning() async {
    isRunning.value = await _service.isRunning();
  }
}
