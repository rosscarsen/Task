import 'package:get/get.dart';

import '../config.dart';
import '../modules/airprint_setting/bindings/airprint_setting_binding.dart';
import '../modules/airprint_setting/views/airprint_setting_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/ip_ping/bindings/ip_ping_binding.dart';
import '../modules/ip_ping/views/ip_ping_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../utils/storage_manage.dart';

// ignore_for_file: non_constant_identifier_names

part 'app_routes.dart';

class AppPages {
  AppPages._();
  static final box = StorageManage();
  static final INITIAL = (box.hasData(Config.localStorageHasLogin) && box.read(Config.localStorageHasLogin) == true)
      ? Routes.HOME
      : Routes.LOGIN;

  static final routes = [
    GetPage(name: _Paths.HOME, page: () => const HomeView(), binding: HomeBinding()),
    GetPage(name: _Paths.LOGIN, page: () => const LoginView(), binding: LoginBinding()),
    GetPage(name: _Paths.IP_PING, page: () => const IpPingView(), binding: IpPingBinding()),
    GetPage(name: _Paths.AIRPRINT_SETTING, page: () => const AirprintSettingView(), binding: AirprintSettingBinding()),
  ];
}
