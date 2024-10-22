import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;

import '../../../config.dart';
import '../../../model/login_model.dart';
import '../../../routes/app_pages.dart';
import '../../../service/api_client.dart';
import '../../../translations/app_translations.dart';
import '../../../utils/easy_loding.dart';
import '../../../utils/stroage_manage.dart';

class LoginController extends GetxController {
  static LoginController get to => Get.find();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController stationController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController pwdController = TextEditingController();
  final ApiClient apiClient = ApiClient();
  final deviceInfoPlugin = DeviceInfoPlugin();
  RxBool isCheck = true.obs;
  Rx<Locale> locale = const Locale("zh", "HK").obs;
  final StorageManage storageManage = StorageManage();
  final count = 0.obs;
  RxBool visibility = false.obs;
  @override
  void onInit() {
    getLoginInfo();
    getLanguage();
    super.onInit();
  }

  @override
  void onClose() {
    companyController.dispose();
    stationController.dispose();
    userController.dispose();
    pwdController.dispose();
    super.onClose();
  }

  void login() async {
    String? currentDevice;
    if (Platform.isAndroid) {
      final AndroidDeviceInfo deviceInfo = await deviceInfoPlugin.androidInfo;
      currentDevice = "${deviceInfo.brand} ${deviceInfo.model}";
    } else if (Platform.isIOS) {
      final IosDeviceInfo deviceInfo = await deviceInfoPlugin.iosInfo;
      currentDevice = deviceInfo.utsname.machine;
    } else if (Platform.isWindows) {
      final WindowsDeviceInfo deviceInfo = await deviceInfoPlugin.windowsInfo;
      currentDevice = "${deviceInfo.productName} ${deviceInfo.computerName}";
    }

    if (formKey.currentState!.validate()) {
      showLoding(LocaleKeys.loggingIn.tr);
      var loginForm = formKey.currentState;
      loginForm!.validate();
      Map<String, dynamic> loginData = {
        "company": companyController.text,
        'station': stationController.text,
        'user': userController.text,
        'pwd': pwdController.text,
        "currentDevice": currentDevice,
      };

      try {
        Response response = await apiClient.post(Config.login, data: loginData);

        if (response.statusCode == 200) {
          final LoginModel ret = LoginModel.fromJson(response.data);

          if (ret.status == 200) {
            storageManage.delete(Config.localStroageloginInfo);
            storageManage.delete(Config.localStroagehasLogin);
            final String? mobileUrl = ret.data!.webSit;
            if (mobileUrl!.isEmpty || mobileUrl == "") {
              errorLoding('websiteNotExist'.tr);
              return;
            }

            if (!isCheck.value) {
              ret.data!.company = "";
              ret.data!.station = "";
              ret.data!.userCode = "";
              ret.data!.pwd = "";
            }
            storageManage.save(Config.localStroageloginInfo, ret.data!.toJson());
            storageManage.save(Config.localStroagehasLogin, true);
            successLoding(LocaleKeys.loginSuccess.tr);

            Future.delayed(const Duration(milliseconds: 1000), () {
              Get.offAllNamed(Routes.HOME);
            });
          } else if (ret.status == 201) {
            errorLoding(LocaleKeys.companyError.tr);
          } else if (ret.status == 202) {
            errorLoding(LocaleKeys.stationDoesNotExist.tr);
          } else if (ret.status == 203) {
            errorLoding(LocaleKeys.useOrPasswordError.tr);
          } else if (ret.status == 204) {
            dismissLoding();
            showCupertinoDialog(
              context: Get.context!,
              builder: (BuildContext context) {
                return CupertinoAlertDialog(
                  title: Text(
                    LocaleKeys.systemMessages.tr,
                    style: TextStyle(fontSize: 22, color: Theme.of(Get.context!).colorScheme.error),
                  ),
                  content: Text(
                    LocaleKeys.stationSiggedIn.trArgs([stationController.text, ret.info!]),
                    style: TextStyle(fontSize: 18, color: Theme.of(Get.context!).colorScheme.error),
                  ),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () {
                        Get.back();
                      },
                      child: Text(
                        LocaleKeys.confirm.tr,
                        style: TextStyle(color: Theme.of(Get.context!).colorScheme.error),
                      ),
                    )
                  ],
                );
              },
            );
          } else {
            errorLoding('${ret.info}');
          }
        } else {
          errorLoding(LocaleKeys.loginFailed.tr);
        }
      } on DioException {
        errorLoding(LocaleKeys.requestFailed.tr);
      } on Exception {
        errorLoding(LocaleKeys.requestFailed.tr);
      }
    }
  }

  void getLoginInfo() {
    var loginUserJson = storageManage.read(Config.localStroageloginInfo);
    UserData? loginUser = loginUserJson != null ? UserData.fromJson(loginUserJson) : null;
    if (loginUser != null) {
      companyController.text = loginUser.company ?? '';
      userController.text = loginUser.userCode ?? '';
      pwdController.text = loginUser.pwd ?? '';
      stationController.text = loginUser.station ?? '';
    }
  }

  ///获取语言
  void getLanguage() {
    var localeString = storageManage.read(Config.localStroagelanguage) ?? "zh_HK";
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
    storageManage.save(Config.localStroagelanguage, locale.toString());
  }
}
