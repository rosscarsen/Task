import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/config.dart';
import 'app/routes/app_pages.dart';
import 'app/service/mobile_task_service.dart';
import 'app/translations/app_translations.dart';
import 'app/utils/storage_manage.dart';

Future<Locale> getSavedLocale() async {
  final StorageManage storageManage = StorageManage();
  if (!storageManage.hasData(Config.localStorageStartTask)) {
    storageManage.save(Config.localStorageStartTask, true);
  }
  // 从存储中读取保存的语言
  String localeString = await storageManage.read(Config.localStorageLanguage) ?? "zh_HK";

  List<String> localeParts = localeString.split('_');
  return Locale(localeParts[0], localeParts.length > 1 ? localeParts[1] : '');
}

Future<void> initService() async {
  // 初始化存储
  await GetStorage.init("task");
  if (Platform.isAndroid || Platform.isIOS) {
    await initializeService();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
  await initService();
  final Locale initialLocale = await getSavedLocale();

  runApp(MyApp(initialLocale));
}

class MyApp extends StatelessWidget {
  final Locale initialLocale;
  const MyApp(this.initialLocale, {super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Task",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: initialLocale,
      // 设置支持的语言
      supportedLocales: const [Locale('zh', 'CN'), Locale('zh', 'HK'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (supportedLocales.contains(locale)) {
          return locale;
        } else {
          return initialLocale;
        }
      },
      builder: (context, child) {
        //加载框
        final easyLoading = EasyLoading.init();
        child = easyLoading(context, child);

        //设置文字大小不随系统设置改变
        child = MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child,
        );
        return child;
      },
    );
  }
}
