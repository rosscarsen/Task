import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/routes/app_pages.dart';
import 'app/service/task_service.dart';
import 'app/translations/app_translations.dart';
import 'app/utils/stroage_manage.dart';

Future<Locale> getSavedLocale() async {
  final StorageManage storageManage = StorageManage();
  // 从存储中读取保存的语言
  String localeString = await storageManage.read("localeLang") ?? "zh_HK";

  List<String> localeParts = localeString.split('_');
  return Locale(localeParts[0], localeParts.length > 1 ? localeParts[1] : '');
}

Future<void> initService() async {
  // 初始化存储
  await GetStorage.init();
  // 初始化服务
  await Get.putAsync<TaskService>(() async => TaskService());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Locale initialLocale = await getSavedLocale();
  await initService();
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
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('zh', 'HK'),
        Locale('en', 'US'),
      ],
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
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child,
        );
        return child;
      },
    );
  }
}
