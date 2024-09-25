import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
              child: WebViewWidget(
                controller: HomeController.to.webViewController,
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