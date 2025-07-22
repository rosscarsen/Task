import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/app/translations/app_translations.dart';

import '../../../config.dart';
import '../../../model/ip_ping.dart';
import '../../../model/login_model.dart';
import '../../../service/api_client.dart';
import '../../../utils/easy_loading.dart';
import '../../../utils/storage_manage.dart';

class IpPingController extends GetxController {
  static IpPingController get to => Get.find();
  final apiCli = ApiClient();
  final StorageManage box = StorageManage();
  RxList<IpData> allIp = <IpData>[].obs;
  RxBool loading = false.obs;

  ///获取所有ip
  Future<void> getAllIP() async {
    UserData? loginUser = getLoginInfo();
    print(loginUser);
    if (loginUser != null) {
      try {
        loading(true);
        var response = await apiCli.post(Config.getAllLocalIP, data: {"loginUserInfo": jsonEncode(loginUser)});
        print(response.data);
        if (response.statusCode == 200) {
          final ipPing = ipPingFromJson(json.encode(response.data));
          if (ipPing.state == 200) {
            allIp.value = ipPing.data;
          }
        }
      } catch (e) {
        debugPrint(e.toString());
      } finally {
        loading(false);
      }
    }
  }

  ///获取登录信息
  UserData? getLoginInfo() {
    var loginUserJson = box.read(Config.localStorageLoginInfo);
    UserData? loginUser = loginUserJson != null ? UserData.fromJson(loginUserJson) : null;
    if (loginUser != null) {
      return loginUser;
    }
    return null;
  }

  /// ping测试
  Future<void> testConnection(String host, {int port = 9100}) async {
    showLoading("$host ${LocaleKeys.testConnect.tr}...");
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      socket.destroy();
      successLoading("$host ${LocaleKeys.connectSuccess.tr}");
    } catch (e) {
      errorLoading("$host ${LocaleKeys.connectFailed.tr}");
    }
  }
}
