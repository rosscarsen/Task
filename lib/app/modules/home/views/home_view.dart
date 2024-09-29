import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../utils/progresshub.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /* appBar: AppBar(
        leading: IconButton(
          onPressed: () async {
            HomeController.to.initUrl();
          },
          icon: const Icon(Icons.import_contacts),
        ),
      ), */
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Color.fromARGB(255, 63, 32, 245),
          statusBarIconBrightness: Brightness.light,
        ),
        child: Padding(
          padding: EdgeInsets.only(top: context.mediaQuery.padding.top),
          child: Obx(
            () => ProgressHUD(
              inAsyncCall: controller.isloading.value,
              opacity: 0.7,
              /* child: WebViewWidget(
                controller: HomeController.to.webViewController,
              ), */
              child: InAppWebView(
                key: HomeController.to.webViewKey,
                initialUrlRequest: URLRequest(url: WebUri(HomeController.to.initWebUrl)),
                initialUserScripts: UnmodifiableListView<UserScript>([
                  UserScript(source: "flutterAirprint='1'", injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END)
                ]),
                initialSettings: HomeController.to.settings,
                pullToRefreshController: HomeController.to.pullToRefreshController,
                onWebViewCreated: (controller) async {
                  HomeController.to.webViewController = controller;
                  //html打开Airprint设置
                  controller.addJavaScriptHandler(
                      handlerName: "openAirprintSetting",
                      callback: (args) {
                        /* ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(args[0])));
                        debugPrint("jsCallFlutter:$args");
                        return "flutter app已经收到，并且处理完成"; */
                        Future.delayed(Duration.zero, () {
                          Get.offAndToNamed(Routes.AIRPRINT_SETTING);
                        });
                      });
                  //window退出登录
                  controller.addJavaScriptHandler(
                      handlerName: "logout",
                      callback: (args) async {
                        await HomeController.to.windowLogout();
                      });
                  //window设置语言
                  controller.addJavaScriptHandler(
                      handlerName: "setLang",
                      callback: (args) async {
                        await HomeController.to.windowSetLanguage(localLangString: args[0].toString());
                      });
                  //日结报表
                  controller.addJavaScriptHandler(
                      handlerName: "printDailyReport",
                      callback: (args) async {
                        final String dailyReportJson = args[0];
                        await HomeController.to.printDayReport(dailyReportJson: dailyReportJson);
                      });
                  //食品銷售報表
                  controller.addJavaScriptHandler(
                      handlerName: "printSalesReport",
                      callback: (args) async {
                        final String salesReportJson = args[0];
                        await HomeController.to.printSalesReport(salesReportJson: salesReportJson);
                      });
                },
                onLoadStart: (controller, url) async {
                  HomeController.to.isloading.value = true;
                  debugPrint("开始加载$url");
                },
                onPermissionRequest: (controller, request) async {
                  return PermissionResponse(resources: request.resources, action: PermissionResponseAction.GRANT);
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  return NavigationActionPolicy.ALLOW;
                },
                onLoadStop: (controller, url) async {
                  HomeController.to.isloading.value = false;
                  HomeController.to.pullToRefreshController?.endRefreshing();
                  await HomeController.to.addAirPrintSettingButton(controller: controller);
                  // await controller.evaluateJavascript(source: "flutterCallJs('我是flutter传过来的数据')");
                },
                onReceivedError: (controller, request, error) {
                  HomeController.to.isloading.value = false;
                  HomeController.to.pullToRefreshController?.endRefreshing();
                },
                onProgressChanged: (controller, progress) {},
                onUpdateVisitedHistory: (controller, url, isReload) {},
                onConsoleMessage: (controller, consoleMessage) {
                  debugPrint("consoleMessage:${consoleMessage.message}");
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/*

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:openhiit_background_service/openhiit_background_service.dart';
import 'package:openhiit_background_service_android/openhiit_background_service_android.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(const MyApp());
}

Future<void> initializeService() async {
  final service = OpenhiitBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // bring to foreground
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // if you don't using custom notification, uncomment this
        service.setForegroundNotificationInfo(
          title: "My App Service",
          content: "Updated at ${DateTime.now()}",
        );
      }
    }

    /// you can see this log in logcat
    print('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');

    // test using external plugin

    service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
      },
    );
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final service = OpenhiitBackgroundService();
  bool isRunning = false;
  String currentDate = "";

  @override
  void initState() {
    super.initState();
    checkServiceStatus();
    service.on('update').listen((event) {
      setState(() {
        currentDate = event!["current_date"];
      });
    });
  }

  void checkServiceStatus() async {
    bool? isRunning = await service.isRunning();
    setState(() {
      this.isRunning = isRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Service App'),
        ),
        body: Container(
          color: Colors.red,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(currentDate.toString()),
              ElevatedButton(
                child: Text(isRunning ? "stop service" : "start service"),
                onPressed: () {
                  if (isRunning) {
                    service.invoke("stopService");
                  } else {
                    service.startService();
                  }
                  setState(() {
                    isRunning = !isRunning;
                  });
                },
              ),
            ],
          ),
        ),
        /* body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(currentDate.toString()),
              ElevatedButton(
                child: Text(isRunning ? "stop service" : "start service"),
                onPressed: () {
                  if (isRunning) {
                    service.invoke("stopService");
                  } else {
                    service.startService();
                  }
                  setState(() {
                    isRunning = !isRunning;
                  });
                },
              ),
            ],
          ),
        ), */
      ),
    );
  }
}

 */
