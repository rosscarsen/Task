// ignore_for_file: non_constant_identifier_names

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/ip_ping/bindings/ip_ping_binding.dart';
import '../modules/ip_ping/views/ip_ping_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();
  static final box = GetStorage();
  static final bool isUserLoggedIn = box.read("hasLogin") ?? false;
  static final INITIAL = isUserLoggedIn ? Routes.HOME : Routes.LOGIN;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.IP_PING,
      page: () => const IpPingView(),
      binding: IpPingBinding(),
    ),
  ];
}
