import 'package:get/get.dart';

import '../controllers/airprint_setting_controller.dart';

class AirprintSettingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AirprintSettingController>(
      () => AirprintSettingController(),
    );
  }
}
