import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../config.dart';
import '../../../model/login_model.dart';
import '../../../routes/app_pages.dart';
import '../../../utils/stroage_manage.dart';

class HomeController extends GetxController {
  static HomeController get to => Get.find();
  //打印服务是否运行
  RxBool isRunning = false.obs;
  //存储类
  final StorageManage storageManage = StorageManage();

  final _service = FlutterBackgroundService();
  late final WebViewController webViewController;
  RxBool isloading = true.obs;
  final box = StorageManage();

  @override
  void onInit() {
    initUrl();
    initWebview();
    super.onInit();
  }

  @override
  void onClose() {
    closeService();

    super.onClose();
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

  void initWebview() {
    final url = initUrl();
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
          onPageFinished: (String url) {
            isloading.value = false;

            webViewController.runJavaScriptReturningResult('typeof flutterCallJs === "function"').then((value) {
              bool? result = value as bool;
              if (result == true) {
                webViewController.runJavaScript("flutterCallJs('flutter调用JS')");
              }
            });
          },
          onWebResourceError: (WebResourceError error) {
            isloading.value = false;
            isloading.value = false;
            showCupertinoDialog(
                context: Get.context!,
                builder: (context) {
                  return CupertinoAlertDialog(
                    title: Text('systemMessages'.tr),
                    content: Text('loading error'.tr),
                    actions: <Widget>[
                      CupertinoDialogAction(
                        child: Text('close'.tr),
                        onPressed: () {
                          Get.back();
                          box.delete(Config.localStroagehasLogin);
                          Get.toNamed(Routes.LOGIN);
                        },
                      ),
                    ],
                  );
                });
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
                  onPressed: () {
                    box.delete(Config.localStroagehasLogin);
                    Get.offAllNamed(Routes.LOGIN);
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
        print("===>${locale.toString()}");
        box.delete(Config.localStroagelanguage);
        box.save(Config.localStroagelanguage, locale.toString());
        Get.updateLocale(locale);
      })
      ..setOnConsoleMessage((message) {
        log("控制台消息: ${message.message}");
      })
      ..loadRequest(Uri.parse(url));
  }

  Future closeService() async {
    var ret = await _service.isRunning();
    if (ret) {
      _service.invoke("stopService");
      isRunning.value = false;
    }
  }

  Future startService() async {
    var ret = await _service.isRunning();
    if (!ret) {
      _service.startService();
      isRunning.value = true;
    }
  }

  Future<void> checkServicRuning() async {
    isRunning.value = await _service.isRunning();
  }
}
