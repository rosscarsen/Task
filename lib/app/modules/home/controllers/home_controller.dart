import 'dart:ui';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../model/login_model.dart';
import '../../../utils/stroage_manage.dart';

class HomeController extends GetxController {
  RxBool isRunning = false.obs;
  final StorageManage storageManage = StorageManage();
  Rx<Locale> locale = const Locale("zh", "HK").obs;

  Future<void> checkServicRuning() async {}

  UserData? getLoginInfo() {
    final GetStorage box = GetStorage();
    var loginUserJson = box.read("loginInfo");
    UserData? loginUser = loginUserJson != null ? UserData.fromJson(loginUserJson) : null;
    if (loginUser != null) {
      return loginUser;
    }
    return null;
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
