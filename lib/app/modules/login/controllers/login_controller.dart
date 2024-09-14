import 'package:dio/dio.dart';
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
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController pwdController = TextEditingController();
  final ApiClient apiClient = ApiClient();
  RxBool isCheck = true.obs;
  Rx<Locale> locale = const Locale("zh", "HK").obs;
  final StorageManage storageManage = StorageManage();
  final count = 0.obs;
  @override
  void onInit() {
    getLoginInfo();
    getLanguage();
    super.onInit();
  }

  @override
  void onClose() {
    companyController.dispose();
    userController.dispose();
    pwdController.dispose();
    super.onClose();
  }

  void login() async {
    if (formKey.currentState!.validate()) {
      showLoding(LocaleKeys.loggingIn.tr);
      var loginForm = formKey.currentState;
      loginForm!.validate();
      Map<String, dynamic> loginData = {
        "company": companyController.text,
        'user': userController.text,
        'pwd': pwdController.text,
      };

      try {
        Response response = await apiClient.post(Config.login, data: loginData);

        if (response.statusCode == 200) {
          LoginModel ret = LoginModel.fromJson(response.data);

          if (ret.status == 200) {
            storageManage.delete("loginInfo");
            storageManage.delete("hasLogin");

            if (isCheck.value) {
              storageManage.save("loginInfo", ret.data!.toJson());
              storageManage.save("hasLogin", true);
            }

            Future.delayed(const Duration(milliseconds: 1000), () {
              Get.offAllNamed(Routes.HOME);
            });
            successLoding(LocaleKeys.loginSuccess.tr);
          } else {
            errorLoding('${ret.info}');
          }
        } else {
          errorLoding(LocaleKeys.loginFailed.tr);
        }
      } on DioException {
        errorLoding(LocaleKeys.requestFailed.tr);
      }
    }
  }

  void getLoginInfo() {
    var loginUserJson = storageManage.read("loginInfo");
    UserData? loginUser = loginUserJson != null ? UserData.fromJson(loginUserJson) : null;
    if (loginUser != null) {
      companyController.text = loginUser.company ?? '';
      userController.text = loginUser.userCode ?? '';
      pwdController.text = loginUser.pwd ?? '';
    }
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
