import 'dart:io';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../config.dart';
import '../../../model/daily_report.dart';
import '../../../model/login_model.dart';
import '../../../model/sale_model.dart';
import '../../../routes/app_pages.dart';
import '../../../service/api_client.dart';
import '../../../service/win32_task_service.dart';
import '../../../translations/app_translations.dart';
import '../../../utils/easy_loading.dart';
import '../../../utils/esc_helper.dart';
import '../../../utils/storage_manage.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  static HomeController get to => Get.find();
  final GlobalKey webViewKey = GlobalKey();
  //存储类
  final StorageManage storageManage = StorageManage();

  final _service = FlutterBackgroundService();
  //late final WebViewController webViewController;
  late InAppWebViewController? webViewController;
  late InAppWebViewSettings? settings;
  PullToRefreshController? pullToRefreshController;
  RxBool isloading = true.obs;
  final ApiClient apiClient = ApiClient();
  late String initWebUrl;

  @override
  void onInit() {
    WidgetsBinding.instance.addObserver(this);
    initUrl();
    initWebview();
    startService();
    super.onInit();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.detached) {
      await closeService();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  //初始化网址
  void initUrl() {
    var loginUserJson = storageManage.read(Config.localStorageLoginInfo);
    String localeString = storageManage.read(Config.localStorageLanguage) ?? "zh_HK";

    String webLang = localeString == "zh_CN"
        ? "zh-cn"
        : localeString == "en_US"
        ? 'en-us'
        : 'zh-tw';

    final UserData? loginUser = loginUserJson != null ? UserData.fromJson(loginUserJson) : null;
    initWebUrl =
        "${ensureHttps(loginUser!.webSit!)}/?l=$webLang&cashier=${loginUser.station}&user=${loginUser.userCode}&pwd=${loginUser.pwd}";
  }

  /// 确保URL以https开头
  String ensureHttps(String url) {
    final uri = Uri.parse(url);
    final updatedUri = uri.scheme == 'http' ? uri.replace(scheme: 'https') : uri;
    return updatedUri.toString();
  }

  ///初始化weview
  void initWebview() {
    settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true,
      userAgent: "flutter",
      javaScriptEnabled: true,
    );
    pullToRefreshController = kIsWeb || ![TargetPlatform.iOS, TargetPlatform.android].contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(color: Colors.blue),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                webViewController?.loadUrl(urlRequest: URLRequest(url: await webViewController?.getUrl()));
              }
            },
          );
    super.onInit();
  }

  ///启动打印服务
  Future<void> startService() async {
    UserData? loginUser = getLoginInfo();
    String? station = loginUser?.station;
    String? airprintStation = loginUser?.airPrintStation;
    if (station != airprintStation) {
      return;
    }
    final bool hasTask = storageManage.read(Config.localStorageStartTask);
    if ((Platform.isAndroid || Platform.isIOS) && hasTask) {
      var ret = await _service.isRunning();
      if (!ret) {
        _service.startService();
      }
    }
    if (Platform.isWindows && hasTask) {
      await win32StartTask(Get.locale?.toString() ?? "zh_HK");
    }
  }

  /// 更改打印语言
  Future<void> updatePrintLang() async {
    if ((Platform.isAndroid || Platform.isIOS)) {
      final isRunning = await _service.isRunning();
      if (isRunning) {
        _service.invoke("updatePrintLang", {'lang': Get.locale?.toString() ?? "zh_HK"});
      }
    }
    if (Platform.isWindows) {
      final isRunning = win32TimerIsRunning();
      if (isRunning) {
        win32UpdatePrintLang(lang: Get.locale?.toString() ?? "zh_HK");
      }
    }
  }

  ///关闭打印服务
  Future closeService() async {
    if (Platform.isAndroid || Platform.isIOS) {
      var ret = await _service.isRunning();
      if (ret) {
        _service.invoke("stopService");
      }
    }
    if (Platform.isWindows) {
      await win32StopTask();
    }
  }

  ///添加airprint网页设置按钮
  Future<void> addAirPrintSettingButton({required InAppWebViewController controller}) async {
    var addAirprintDiv =
        '''
    function openAirprintSetting() {
        try { 
            window.flutter_inappwebview.callHandler('openAirprintSetting', "js打开airprint设置");
            document.querySelector('.setting_content').style.display = 'none';
            document.querySelector('.menu-bt').click();
        } catch (e) {
            document.querySelector('.setting_content').style.display = 'none';
            document.querySelector('.menu-bt').click();
        }
    }

    // Check if the AirPrint button already exists
    if (!document.querySelector('.airprint-setting-button')) {
        var newAnchor = document.createElement('a');
        newAnchor.href = "javascript:void(0);";
        newAnchor.onclick = openAirprintSetting;
        newAnchor.innerHTML = '${'airprintSetting'.tr}';
        newAnchor.className = 'i airprint-setting-button'; // Add a unique class for identification
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
    }
  ''';

    await controller.evaluateJavascript(source: addAirprintDiv);
  }

  ///退出登录
  Future<void> logout() async {
    Get.back();
    showLoading("${LocaleKeys.logout.tr}...");
    final UserData? loginUser = getLoginInfo();
    if (loginUser != null) {
      String? company = loginUser.company;
      String? station = loginUser.station;
      try {
        var response = await apiClient.post(Config.logout, data: {"company": company, "station": station});

        if (response.statusCode == 200) {
          dismissLoading();
          await closeService();
          storageManage.delete(Config.localStorageHasLogin);
          Get.offAllNamed(Routes.LOGIN);
        }
      } catch (e) {
        errorLoading(LocaleKeys.logoutFailed.tr);
      }
    } else {
      errorLoading(LocaleKeys.logoutFailed.tr);
    }
  }

  ///获取登录信息
  UserData? getLoginInfo() {
    var loginUserJson = storageManage.read(Config.localStorageLoginInfo);
    UserData? loginUser = loginUserJson != null ? UserData.fromJson(loginUserJson) : null;
    if (loginUser != null) {
      return loginUser;
    }
    return null;
  }

  //退出登录
  Future<void> windowLogout() async {
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
              },
            ),
          ],
        );
      },
    );
  }

  ///window设置语言
  Future<void> windowSetLanguage({required String localLangString}) async {
    Locale locale = localLangString.isNotEmpty
        ? localLangString == "zh-cn"
              ? const Locale("zh", "CN")
              : localLangString == "zh-tw"
              ? const Locale("zh", "HK")
              : const Locale("en", "US")
        : const Locale("zh", "HK");

    await storageManage.delete(Config.localStorageLanguage);
    await storageManage.save(Config.localStorageLanguage, locale.toString());
    Get.updateLocale(locale);
    updatePrintLang();
  }

  ///打印日结报表
  Future<void> printDayReport({required String dailyReportJson}) async {
    final UserData? loginUser = getLoginInfo();
    if (loginUser != null) {
      if (loginUser.invoicePrintIP == null && loginUser.invoicePrintIP == "") {
        errorLoading(LocaleKeys.printDoesNotExits.tr);
        return;
      }
    }

    final DailyReportModel dailyReportModel = dailyReportModelFromMap(dailyReportJson);
    await doPrintDayReport(
      printData: dailyReportModel,
      invoicePrintIP: loginUser!.invoicePrintIP!,
      invoicePrintType: loginUser.invoicePrintType!,
    );
  }

  //执行打印日结报表
  Future<void> doPrintDayReport({
    required DailyReportModel printData,
    required String invoicePrintIP,
    required String invoicePrintType,
  }) async {
    try {
      final printer = PrinterNetworkManager(invoicePrintIP);
      PosPrintResult connect = await printer.connect();
      if (connect == PosPrintResult.success) {
        List<int> bytes = [];
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm80, profile);
        bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
        bytes += generator.text(
          "${printData.dailyReport}",
          styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        bytes += generator.text(
          "${printData.shop}",
          styles: const PosStyles(height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        bytes += generator.text(
          "${printData.staff}",
          styles: const PosStyles(height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        bytes += generator.text(
          "${printData.date}",
          styles: const PosStyles(height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        bytes += generator.rawBytes(EscHelper.setAlign().codeUnits);
        bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
        bytes += generator.hr();
        //销售金額
        bytes += generator.text(
          "${printData.salesAmount}",
          styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2),
          containsChinese: true,
        );
        bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
        bytes += generator.hr();
        bytes += generator.feed(1);
        bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        final List<String>? salesAmountTotal = printData.salesAmountTotal;
        if (salesAmountTotal!.isNotEmpty) {
          bytes += generator.text(
            "${EscHelper.columnMaker(content: salesAmountTotal[0], width: 24)}${EscHelper.columnMaker(content: salesAmountTotal[1], width: 24, align: 2)}",
            containsChinese: true,
          );
        }
        final List<String>? service = printData.service;
        if (service!.isNotEmpty) {
          bytes += generator.text(
            "${EscHelper.columnMaker(content: service[0], width: 24)}${EscHelper.columnMaker(content: service[1], width: 24, align: 2)}",
            containsChinese: true,
          );
        }

        final List<String>? dis = printData.dis;
        if (dis!.isNotEmpty) {
          bytes += generator.text(
            "${EscHelper.columnMaker(content: dis[0], width: 24)}${EscHelper.columnMaker(content: dis[1], width: 24, align: 2)}",
            containsChinese: true,
          );
        }

        final List<String>? tips = printData.tips;
        if (tips!.isNotEmpty) {
          bytes += generator.text(
            "${EscHelper.columnMaker(content: tips[0], width: 24)}${EscHelper.columnMaker(content: tips[1], width: 24, align: 2)}",
            containsChinese: true,
          );
        }

        final List<String>? balance = printData.balance;
        if (balance!.isNotEmpty) {
          bytes += generator.text(
            "${EscHelper.columnMaker(content: balance[0], width: 24)}${EscHelper.columnMaker(content: balance[1], width: 24, align: 2)}",
            containsChinese: true,
          );
        }
        bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
        bytes += generator.hr();
        bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        final List<String>? netAmt = printData.netAmt;
        if (netAmt!.isNotEmpty) {
          bytes += generator.text(
            "${EscHelper.columnMaker(content: netAmt[0], width: 24)}${EscHelper.columnMaker(content: netAmt[1], width: 24, align: 2)}",
            containsChinese: true,
          );
        }
        bytes += generator.feed(1);
        //支付方式
        final List<String>? payTitle = printData.payTitle;
        if (payTitle!.isNotEmpty) {
          bytes += generator.text(
            "${EscHelper.setBold()}${EscHelper.columnMaker(content: payTitle[0], width: 20)}${EscHelper.columnMaker(content: payTitle[1], width: 16)}${EscHelper.columnMaker(content: payTitle[2], width: 12, align: 2)}",
            containsChinese: true,
          );
        }
        bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
        bytes += generator.hr();
        bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);

        final List<List<String>>? payList = printData.payList;
        bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits + EscHelper.setBold(bold: false).codeUnits);
        if (payList!.isNotEmpty) {
          for (var payItem in payList) {
            if (payItem.isNotEmpty) {
              bytes += generator.text(
                "${EscHelper.columnMaker(content: payItem[0], width: 16)}${EscHelper.columnMaker(content: payItem[1], width: 4)}${EscHelper.columnMaker(content: payItem[2], width: 16)}${EscHelper.columnMaker(content: payItem[3], width: 12, align: 2)}",
                containsChinese: true,
              );
            }
          }

          bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
          bytes += generator.hr();
          bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        }

        final List<String>? payTotalList = printData.payTotalList;
        if (payTotalList!.isNotEmpty) {
          bytes += generator.text(
            "${EscHelper.columnMaker(content: payTotalList[0], width: 16)}${EscHelper.columnMaker(content: payTotalList[1], width: 4)}${EscHelper.columnMaker(content: payTotalList[2], width: 16)}${EscHelper.columnMaker(content: payTotalList[3], width: 12, align: 2)}",
            containsChinese: true,
          );
        }
        bytes += generator.feed(1);
        //現金核算
        final String? cashAccounting = printData.cashAccounting;
        if (cashAccounting!.isNotEmpty) {
          bytes += generator.text(
            "${EscHelper.setBold()}${EscHelper.setSize(size: 3)}$cashAccounting",
            containsChinese: true,
          );

          bytes += generator.rawBytes(EscHelper.setBold(bold: false).codeUnits);
        }
        bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
        bytes += generator.hr();
        bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        final List<String>? cashSales = printData.cashSales;
        //现金销售
        if (cashSales!.isNotEmpty) {
          bytes += generator.text(
            "${EscHelper.columnMaker(content: cashSales[0], width: 20)}${EscHelper.columnMaker(content: cashSales[1], width: 16)}${EscHelper.columnMaker(content: cashSales[2], width: 12, align: 2)}",
            containsChinese: true,
          );

          bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
          bytes += generator.hr();
          bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        }
        final List<dynamic>? cashAccountingDetailPay = printData.cashAccountingDetailPay;
        //现金会计明细支付
        if (cashAccountingDetailPay!.isNotEmpty) {
          bytes += generator.text(
            "${EscHelper.columnMaker(content: cashAccountingDetailPay[0], width: 24)}${EscHelper.columnMaker(content: cashAccountingDetailPay[1], width: 24, align: 2)}",
            containsChinese: true,
          );

          bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
          bytes += generator.hr();
          bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        }
        final List<String>? cashOnHand = printData.cashOnHand;
        //收银柜现金
        if (cashOnHand!.isNotEmpty) {
          bytes += generator.text(
            "${EscHelper.columnMaker(content: cashOnHand[0], width: 24)}${EscHelper.columnMaker(content: cashOnHand[1], width: 24, align: 2)}",
            containsChinese: true,
          );
          bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
          bytes += generator.hr();
          bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        }

        //日結分析
        final String? auditTrail = printData.auditTrail;
        if (auditTrail!.isNotEmpty) {
          bytes += generator.text("${EscHelper.setSize(size: 3)}$auditTrail", containsChinese: true);

          bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
          bytes += generator.hr();
          bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        }
        //作废修改
        final List<String>? voidModify = printData.voidModify;
        if (voidModify!.isNotEmpty) {
          bytes += generator.text(
            "${EscHelper.columnMaker(content: voidModify[0], width: 20)}${EscHelper.columnMaker(content: voidModify[1], width: 16)}${EscHelper.columnMaker(content: voidModify[2], width: 12, align: 2)}",
            containsChinese: true,
          );
        }
        //退单
        final List<String>? refund = printData.refund;
        if (refund!.isNotEmpty) {
          bytes += generator.text(
            "${EscHelper.columnMaker(content: refund[0], width: 20)}${EscHelper.columnMaker(content: refund[1], width: 16)}${EscHelper.columnMaker(content: refund[2], width: 12, align: 2)}",
            containsChinese: true,
          );
        }
        //签送
        final List<String>? waive = printData.waive;
        if (waive!.isNotEmpty) {
          bytes += generator.text(
            "${EscHelper.columnMaker(content: waive[0], width: 20)}${EscHelper.columnMaker(content: waive[1], width: 16)}${EscHelper.columnMaker(content: waive[2], width: 12, align: 2)}",
            containsChinese: true,
          );
        }
        //平均金额
        final List<String>? averageBill = printData.averageBill;
        if (averageBill!.isNotEmpty) {
          bytes += generator.text(
            "${EscHelper.columnMaker(content: averageBill[0], width: 20)}${EscHelper.columnMaker(content: averageBill[1], width: 16)}${EscHelper.columnMaker(content: averageBill[2], width: 12, align: 2)}",
            containsChinese: true,
          );
        }
        //人均消费
        final List<String>? averageGuest = printData.averageGuest;
        if (averageGuest!.isNotEmpty) {
          bytes += generator.text(
            "${EscHelper.columnMaker(content: averageGuest[0], width: 20)}${EscHelper.columnMaker(content: averageGuest[1], width: 16)}${EscHelper.columnMaker(content: averageGuest[2], width: 12, align: 2)}",
            containsChinese: true,
          );
        }
        bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
        bytes += generator.hr();
        bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        bytes += generator.feed(1);
        bytes += generator.cut();
        PosPrintResult printing = await printer.printTicket(bytes);
        printer.disconnect();
        if (printing.msg == "Success") {
          successLoading(LocaleKeys.printSuccess.tr);
        }
      } else {
        errorLoading("打印機$invoicePrintIP連接失敗");
      }
    } catch (e) {
      errorLoading("打印过程中出现错误: $e");
    }
  }

  //打印销售报表
  Future<void> printSalesReport({required String salesReportJson}) async {
    final UserData? loginUser = getLoginInfo();
    if (loginUser != null) {
      if (loginUser.invoicePrintIP == null && loginUser.invoicePrintIP == "") {
        errorLoading(LocaleKeys.printDoesNotExits.tr);
        return;
      }
    }

    final SaleModel saleModel = saleModelFromMap(salesReportJson);
    await _printSalesReport(
      printData: saleModel,
      invoicePrintIP: loginUser!.invoicePrintIP!,
      invoicePrintType: loginUser.invoicePrintType!,
    );
  }

  //执行打印销售报表
  Future<void> _printSalesReport({
    required SaleModel printData,
    required String invoicePrintIP,
    required String invoicePrintType,
  }) async {
    try {
      final printer = PrinterNetworkManager(invoicePrintIP);
      PosPrintResult connect = await printer.connect();
      if (connect == PosPrintResult.success) {
        List<int> bytes = [];
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm80, profile);
        bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
        bytes += generator.text(
          "${printData.reportCompany}",
          styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        bytes += generator.text(
          LocaleKeys.foodSaleReport.tr,
          styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        bytes += generator.feed(1);
        bytes += generator.text(
          "${LocaleKeys.timeSolt.tr}：${printData.timerFrame}",
          styles: const PosStyles(height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        bytes += generator.text(
          "${LocaleKeys.printTime.tr}：${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}",
          styles: const PosStyles(height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );

        bytes += generator.text(
          "${LocaleKeys.station.tr}：${printData.station}",
          styles: const PosStyles(height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        bytes += generator.feed(1);
        bytes += generator.rawBytes(EscHelper.setAlign().codeUnits);
        //列表头
        bytes += generator.text(
          "${EscHelper.setBold()}${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: LocaleKeys.code.tr, width: 16)}${EscHelper.columnMaker(content: LocaleKeys.quantity.tr, width: 16, align: 1)}${EscHelper.columnMaker(content: LocaleKeys.amount.tr, width: 16, align: 2)}",
          containsChinese: true,
        );
        bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits + EscHelper.setBold(bold: false).codeUnits);
        //列表内容
        final List<SaleReportList> saleReportList = printData.saleReportList!;
        if (saleReportList.isNotEmpty) {
          double total = 0.0;
          for (var i = 0; i < saleReportList.length; i++) {
            total += double.tryParse(saleReportList[i].mAmount!) ?? 0.00;
            bytes += generator.rawBytes(EscHelper.setSize().codeUnits + EscHelper.setBold(bold: false).codeUnits);
            bytes += generator.hr();
            bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
            bytes += generator.text(
              "${EscHelper.columnMaker(content: "${saleReportList[i].mCode}", width: 16)}${EscHelper.columnMaker(content: "${double.parse(saleReportList[i].mQty!).toInt()}", width: 16, align: 1)}${EscHelper.columnMaker(content: "${double.tryParse(saleReportList[i].mAmount!)?.toStringAsFixed(2)}", width: 16, align: 2)}",
              containsChinese: true,
            );
            bytes += generator.text("${saleReportList[i].mDesc1}", containsChinese: true);
          }
          bytes += generator.rawBytes(EscHelper.setSize().codeUnits + EscHelper.setBold(bold: false).codeUnits);
          bytes += generator.hr();
          bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits + EscHelper.setBold().codeUnits);
          bytes += generator.text(
            EscHelper.columnMaker(content: "${LocaleKeys.total.tr}: ${total.toStringAsFixed(2)}", width: 48, align: 2),
            containsChinese: true,
          );
        }

        bytes += generator.feed(1);
        bytes += generator.cut();
        bytes += generator.reset();
        PosPrintResult printing = await printer.printTicket(bytes);
        printer.disconnect();
        if (printing.msg == "Success") {
          successLoading(LocaleKeys.printSuccess.tr);
        }
      } else {
        errorLoading("打印機$invoicePrintIP連接失敗");
      }
    } catch (e) {
      errorLoading("打印过程中出现错误: $e");
    }
  }

  /*  Future<void> testPrint() async {
    final profile = await CapabilityProfile.load(name: "TM-U220");
    final generator = Generator(PaperSize.mm72, profile);
    final printer = PrinterNetworkManager("192.168.1.235");
    PosPrintResult connect = await printer.connect();
    if (connect == PosPrintResult.success) {
      debugPrint("打印机连接成功");
      List<int> bytes = [];
      /*  bytes += generator.rawBytes(EscHelper.setBold().codeUnits +
          EscHelper.setAlign(align: 1).codeUnits +
          EscHelper.setPrinterColor(true).codeUnits +
          [0x1D, 0x21, 0x22]); */
      //bytes += generator.setGlobalCodeTable("CP437");
      bytes += generator.rawBytes([27, 33, 56]);
      bytes += generator.text(
        "TEST",
      );
      bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
      bytes += generator.rawBytes([27, 33, 56] + [27, 82, 15] + [29, 33, 17]);
      bytes += generator.text(
        "打印机连接成功",
        containsChinese: true,
      );
      // bytes += generator.reset();
      bytes += generator.rawBytes([27, 33, 0]);
      bytes += generator.hr();

      /* try {
        final String qrData = "https://www.google.com";
        const double qrSize = 300;
        final uiImg = await QrPainter(
          data: qrData,
          version: QrVersions.auto,
          gapless: false,
        ).toImageData(qrSize);
        final dir = await getTemporaryDirectory();
        final pathName = '${dir.path}/qr_tmp.png';
        final qrFile = File(pathName);
        final imgFile = await qrFile.writeAsBytes(uiImg!.buffer.asUint8List());
        final img = decodeImage(imgFile.readAsBytesSync());

        bytes += generator.image(img!);
      } catch (e) {
        debugPrint("二维码生成失败: $e");
      } */
      bytes += generator.cut();
      PosPrintResult printing = await printer.printTicket(bytes);
      if (printing.msg == "Success") {}
      printer.disconnect();
    } else {
      debugPrint("打印机连接失败");
    }
  }
 */
}
