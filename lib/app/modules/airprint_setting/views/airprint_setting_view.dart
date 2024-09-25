import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../translations/app_translations.dart';
import '../controllers/airprint_setting_controller.dart';

class AirprintSettingView extends GetView<AirprintSettingController> {
  const AirprintSettingView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(LocaleKeys.airprintService.tr),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              Get.toNamed(Routes.IP_PING);
            },
            icon: const Icon(Icons.cast_connected),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Obx(() => Text(
                  AirprintSettingController.to.isRunning.value
                      ? LocaleKeys.startArirprintService.tr
                      : LocaleKeys.airprintServiceIsStopped.tr,
                  style: const TextStyle(fontSize: 30),
                )),
            const SizedBox(height: 10),
            OverflowBar(
              alignment: MainAxisAlignment.center,
              children: [
                Obx(() => ElevatedButton(
                      onPressed: AirprintSettingController.to.isRunning.value
                          ? null
                          : () async {
                              await AirprintSettingController.to.startService();
                            },
                      child: Text(LocaleKeys.startAirprint.tr),
                    )),
                const SizedBox(width: 20),
                Obx(() => ElevatedButton(
                      onPressed: AirprintSettingController.to.isRunning.value
                          ? () {
                              AirprintSettingController.to.closeService();
                            }
                          : null,
                      child: Text(LocaleKeys.stopAirprint.tr),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
