/* import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';

import '../../../config.dart';
import '../../../model/login_model.dart';
import '../../../routes/app_pages.dart';
import '../../../service/api_client.dart';
import '../../../translations/app_translations.dart';
import '../../../utils/easy_loding.dart';
import '../../../utils/stroage_manage.dart';

class HomeController extends GetxController {
  static HomeController get to => Get.find();

  //存储类
  final StorageManage storageManage = StorageManage();

  final _service = FlutterBackgroundService();
  RxBool isloading = true.obs;
  final box = StorageManage();
  final ApiClient apiClient = ApiClient();

  @override
  void onInit() {
    initUrl();
    initWebview();
    startService();
    super.onInit();
  }

  //初始化网址
  String initUrl() {
    var loginUserJson = storageManage.read(Config.localStroageloginInfo);
    String localeString = storageManage.read(Config.localStroagelanguage) ?? "zh_HK";
    String webLang = localeString == "zh_CN"
        ? "zh-cn"
        : localeString == "en_US"
            ? 'en-us'
            : 'zh-tw';

    final UserData? loginUser = loginUserJson != null ? UserData.fromJson(loginUserJson) : null;
    final String loadUrl =
        "${loginUser!.webSit}/?l=$webLang&cashier=${loginUser.station}&user=${loginUser.userCode}&pwd=${loginUser.pwd}";

    return loadUrl;
  }

  ///初始化weview
  void initWebview() {
    final String initWebUrl = initUrl();

    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("flutter")
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {
            isloading.value = true;
          },
          onPageFinished: (String url) async {
            isloading.value = false;
            await addAirPrintSettingButton(controller: webViewController);
          },
          onWebResourceError: (WebResourceError error) async {
            isloading.value = false;
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..getScrollPosition().then((value) {
        log("滚动位置: ${value.dx}//${value.dy}");
      })
      ..addJavaScriptChannel("FLUTTER_CHANNEL", onMessageReceived: (JavaScriptMessage message) {
        showCupertinoDialog(
          context: Get.context!,
          builder: (context) {
            return CupertinoAlertDialog(
              title: Text('systemMessages'.tr),
              content: Text('confirmLoginOut'.tr),
              actions: <Widget>[
                CupertinoDialogAction(
                  child: Text('cancel'.tr),
                  onPressed: () {
                    Get.back();
                  },
                ),
                CupertinoDialogAction(
                  child: Text('confirm'.tr),
                  onPressed: () async {
                    await logout();
                    /* box.delete(Config.localStroagehasLogin);
                    Get.offAllNamed(Routes.LOGIN); */
                  },
                ),
              ],
            );
          },
        );
      })
      ..addJavaScriptChannel("setLang", onMessageReceived: (JavaScriptMessage message) {
        String localLangString = message.message.toString();

        Locale locale = localLangString.isNotEmpty
            ? localLangString == "zh-cn"
                ? const Locale("zh", "CN")
                : localLangString == "zh-tw"
                    ? const Locale("zh", "HK")
                    : const Locale("en", "US")
            : const Locale("zh", "HK");

        box.delete(Config.localStroagelanguage);
        box.save(Config.localStroagelanguage, locale.toString());
        Get.updateLocale(locale);
      })
      ..addJavaScriptChannel("flutterAirprintSetting", onMessageReceived: (JavaScriptMessage message) {
        Get.offAndToNamed(Routes.AIRPRINT_SETTING);
      })
      ..setOnConsoleMessage((message) {
        log("控制台消息: ${message.message}");
      })
      ..clearCache()
      ..loadRequest(Uri.parse(initWebUrl.trim()), headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
        'Access-Control-Allow-Credentials': 'true'
      });
  }

  ///关闭打印服务
  Future closeService() async {
    var ret = await _service.isRunning();
    if (ret) {
      _service.invoke("stopService");
    }
  }

  ///启动打印服务
  Future startService() async {
    UserData? loginUser = getLoginInfo();
    String? station = loginUser?.station;
    String? airprintStation = loginUser?.airPrintStation;
    if (station != airprintStation) {
      return;
    }

    var ret = await _service.isRunning();
    if (!ret) {
      _service.startService();
    }
  }

  ///添加airprint网页设置按钮
  Future<void> addAirPrintSettingButton({required WebViewController controller}) async {
    var addAirprintDiv = '''
        function openAirprintSetting() {
            try { 
                window.flutterAirprintSetting.postMessage("js打开app设置页面"); 
                document.querySelector('.setting_content').style.display = 'none';
                document.querySelector('.menu-bt').click();
            } catch (e) {
                document.querySelector('.setting_content').style.display = 'none';
                document.querySelector('.menu-bt').click();
            }
        }
        var newAnchor = document.createElement('a');
        newAnchor.href = "javascript:void(0);";
        newAnchor.onclick = openAirprintSetting;
        newAnchor.innerHTML = '${'airprintSetting'.tr}';
        newAnchor.className = 'i';
        newAnchor.style.border = 'none';
        newAnchor.style.background = '#3575f0';
        newAnchor.style.color = '#fff';
        newAnchor.style.lineHeight = '26px';
        newAnchor.style.borderRadius = '4px';
        newAnchor.style.margin = '20px';
        newAnchor.style.padding = '5px 20px';
        newAnchor.style.textAlign = 'center';
        var parentDiv = document.getElementById('setting');
        if (parentDiv) {
            parentDiv.appendChild(newAnchor);
        } 
    ''';
    await controller.runJavaScript(addAirprintDiv);
  }

  ///退出登录
  Future<void> logout() async {
    Get.back();
    showLoding("${LocaleKeys.logout.tr}...");
    final UserData? loginUser = getLoginInfo();
    if (loginUser != null) {
      String? company = loginUser.company;
      String? station = loginUser.station;
      try {
        var response = await apiClient.post(Config.logout, data: {"company": company, "station": station});

        if (response.statusCode == 200) {
          dismissLoding();
          await closeService();
          box.delete(Config.localStroagehasLogin);
          Get.offAllNamed(Routes.LOGIN);
        }
      } catch (e) {
        errorLoding(LocaleKeys.logoutFailed.tr);
      }
    } else {
      errorLoding(LocaleKeys.logoutFailed.tr);
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
}
 */