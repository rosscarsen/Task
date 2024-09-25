import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:task/app/translations/app_translations.dart';

import '../../../config.dart';
import '../../../model/ip_ping.dart';
import '../../../model/login_model.dart';
import '../../../service/api_client.dart';
import '../../../utils/easy_loding.dart';

class IpPingController extends GetxController {
  static IpPingController get to => Get.find();
  final apiCli = ApiClient();
  GetStorage box = GetStorage();
  RxList<IpData> allIp = <IpData>[].obs;
  RxBool loadding = false.obs;

  ///获取所有ip
  Future<void> getAllIP() async {
    UserData? loginUser = getLoginInfo();

    if (loginUser != null) {
      try {
        loadding(true);
        var response = await apiCli.post(Config.getAllLocalIP, data: {"loginUserInfo": jsonEncode(loginUser)});
        if (response.statusCode == 200) {
          final ipPing = ipPingFromJson(json.encode(response.data));
          if (ipPing.state == 200) {
            allIp.value = ipPing.data;
          }
        }
      } catch (e) {
        debugPrint(e.toString());
      } finally {
        loadding(false);
      }
    }
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

  /// ping测试
  Future<void> testConnection(String host, {int port = 9100}) async {
    showLoding("$host ${LocaleKeys.testConnect.tr}...");
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      socket.destroy();
      successLoding("$host ${LocaleKeys.connectSuccess.tr}");
    } catch (e) {
      errorLoding("$host ${LocaleKeys.connectFailed.tr}");
    }
  }
}
