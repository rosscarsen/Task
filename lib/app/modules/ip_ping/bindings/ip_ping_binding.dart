import 'package:get/get.dart';

import '../controllers/ip_ping_controller.dart';

class IpPingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IpPingController>(
      () => IpPingController(),
    );
  }
}
