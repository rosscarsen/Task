import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import '../../../utils/stroage_manage.dart';

class HomeController extends GetxController {
  static HomeController get to => Get.find();
  RxBool isRunning = false.obs;
  final StorageManage storageManage = StorageManage();
  Rx<Locale> locale = const Locale("zh", "HK").obs;
  final _service = FlutterBackgroundService();

  @override
  void onInit() {
    checkServicRuning();
    super.onInit();
  }

  @override
  void onClose() {
    closeService();
    super.onClose();
  }

  Future closeService() async {
    var ret = await _service.isRunning();
    if (ret) {
      _service.invoke("stopService");
      isRunning.value = false;
    }
  }

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

  ///获取语言
  void getLanguage() {
    var localeString = storageManage.read("localeLang") ?? "zh_HK";
    if (localeString != null) {
      List<String> localeParts = localeString.split('_');
      locale.value = Locale(localeParts[0], localeParts.length > 1 ? localeParts[1] : '');
    }
  }

  ///切换语言
  void changeLanguage(Locale locale) {
    Get.updateLocale(locale);
    this.locale.value = locale;
    saveLanguage(locale);
  }

  ///保存语言
  void saveLanguage(Locale locale) {
    storageManage.save("localeLang", locale.toString());
  }
}
