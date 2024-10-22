import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:win32/win32.dart';

import '../config.dart';
import '../model/login_model.dart';
import '../model/printer_model.dart';
import 'api_client.dart';
import 'print_method.dart';

Timer? _windowsTimer;
bool printStatus = true;
final ApiClient apiClient = ApiClient();
// 防止电脑进入睡眠状态
void preventSleep() {
  // 设置线程执行状态，防止电脑进入睡眠状态
  SetThreadExecutionState(
      EXECUTION_STATE.ES_CONTINUOUS | EXECUTION_STATE.ES_SYSTEM_REQUIRED | EXECUTION_STATE.ES_AWAYMODE_REQUIRED);
}

// 允许睡眠
void allowSleep() {
  // 设置线程执行状态为连续执行
  SetThreadExecutionState(EXECUTION_STATE.ES_CONTINUOUS);
}

// 定义一个函数，用于启动Windows任务
Future<void> win32StartTask() async {
  printStatus = true;
  final bool isRunning = win32TimerIsRunning();
  if (!isRunning) {
    // 阻止系统休眠
    preventSleep();
    //显示托盘图标
    await showIcon();
    // 创建一个定时器，每隔5秒运行一次任务
    _windowsTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      UserData? loginUser = await getLoginInfo();

      if (loginUser != null) {
        debugPrint("打印状态：$printStatus");
        if (printStatus) {
          getPrintData(queryData: loginUser.toJson());
        }
      } else {
        debugPrint("本地信息为空");
      }
    });
    /*  UserData? loginUser = await getLoginInfo();

    if (loginUser != null) {
      debugPrint("打印状态：$printStatus");
      if (printStatus) {
        getPrintData(queryData: loginUser.toJson());
      }
    } else {
      debugPrint("本地信息为空");
    } */
  }
}

/// 获取打印数据
Future<void> getPrintData({Map<String, dynamic>? queryData}) async {
  //定义一个list接收已经打印的单号
  List queueIDs = [];
  printStatus = false;
  try {
    var response = await apiClient.post(Config.getData, data: {"loginUserInfo": jsonEncode(queryData)});
    //logger.d("打印数据：${response.data}");
    if (response.statusCode == 200) {
      if (response.data != null) {
        PrinterModel ret = PrinterModel.fromJson(response.data);
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm80, profile);
        if (ret.qrCodeData == null &&
            ret.kitchen == null &&
            ret.upperMenu == null &&
            ret.receipt == null &&
            ret.customerRecord == null &&
            ret.openDrawer == null &&
            ret.takeaway == null) {
          printStatus = true;
          return;
        }

        ///打印二维码
        if (ret.qrCodeData != null && ret.qrCodeData!.isNotEmpty) {
          List<String> qrcodeIDs = await printQrCode(generator: generator, printData: ret.qrCodeData!);
          //去重
          List<String> uniqueQrCodeIDs = qrcodeIDs.toSet().toList();
          if (uniqueQrCodeIDs.isNotEmpty) {
            queueIDs.addAll([
              {"qrcode": uniqueQrCodeIDs}
            ]);
          }
        }

        ///打印厨房、BDL小票
        if (ret.kitchen != null && ret.kitchen!.isNotEmpty) {
          final List<Kitchen> nomoralKitchen = ret.kitchen!.where((rows) => rows.mIsPrint == "P").toList();
          final List<Kitchen> otherKitchen =
              ret.kitchen!.where((rows) => rows.mIsPrint != "P" && rows.mLanIP != null).toList();
          //定义接收返回的已打印厨房单据
          List<Map<String, dynamic>> printedKitchen = [];

          ///打印不是正常单位的厨房单据
          if (otherKitchen.isNotEmpty) {
            List<Map<String, dynamic>> tempOtherIDs =
                await printOtherkichen(generator, otherKitchen, ret.isPrintPrice!);
            if (tempOtherIDs.isNotEmpty) {
              printedKitchen.addAll(tempOtherIDs);
            }
          }

          ///组装打印厨房数据
          final Map<String, Map<String, Map<int, List<Kitchen>>>> kitchenData = {};
          groupBy(
            nomoralKitchen.where((rows) => rows.mLanIP != null),
            (Kitchen rows) => rows.mLanIP,
          ).forEach((mLanIP, kitchens) {
            // 如果 mLanIP 不存在，先插入一个空的 Map
            if (!kitchenData.containsKey(mLanIP)) {
              kitchenData[mLanIP!] = {};
            }
            // 分组处理
            final invoiceGroup = groupBy(kitchens, (Kitchen rows) => rows.mInvoiceNo!);
            invoiceGroup.forEach((mInvoiceNo, kitchenList) {
              kitchenData[mLanIP]![mInvoiceNo] = groupBy(
                kitchenList,
                (Kitchen rows) => rows.mContinue!,
              );
            });
          });
          kitchenData.removeWhere((key, value) => key.isEmpty);

          ///组装打印班地尼数据
          final Map<String, Map<String, Map<int, List<Kitchen>>>> bDLData = {};

          groupBy(
            nomoralKitchen.where((rows) => rows.bDLLanIP != null),
            (Kitchen rows) => rows.bDLLanIP,
          ).forEach((bDLLanIP, kitchens) {
            // 如果 mLanIP 不存在，先插入一个空的 Map
            if (!bDLData.containsKey(bDLLanIP)) {
              bDLData[bDLLanIP!] = {};
            }
            // 分组处理
            final invoiceGroup = groupBy(kitchens, (Kitchen rows) => rows.mInvoiceNo!);
            invoiceGroup.forEach((mInvoiceNo, kitchenList) {
              bDLData[bDLLanIP]![mInvoiceNo] = groupBy(
                kitchenList,
                (Kitchen rows) => rows.mNonContinue!,
              );
            });
          });
          bDLData.removeWhere((key, value) => key.isEmpty);

          List<String> kitchenInvocie = [];

          ///打印厨房
          if (kitchenData.isNotEmpty) {
            List<String> tempKitchenInvoice = await printkichen(generator, kitchenData, ret.isPrintPrice!);
            if (tempKitchenInvoice.isNotEmpty) {
              kitchenInvocie.addAll(tempKitchenInvoice);
            }
          }

          ///打印班地尼
          if (bDLData.isNotEmpty) {
            List<String> tempBDLInvoice = await printBDL(generator, bDLData, ret.isPrintPrice!);
            if (tempBDLInvoice.isNotEmpty) {
              kitchenInvocie.addAll(tempBDLInvoice);
            }
          }

          List<String> uniqueKitchenInvoice = kitchenInvocie.toSet().toList();

          if (uniqueKitchenInvoice.isNotEmpty) {
            printedKitchen.add({"queueID": uniqueKitchenInvoice, "mIsPrint": "P"});
          }
          if (printedKitchen.isNotEmpty) {
            queueIDs.addAll([
              {"kitchen": printedKitchen}
            ]);
          }
        }

        ///打印上菜单
        if (ret.upperMenu != null && ret.upperMenu!.upperMenuData!.isNotEmpty) {
          List<String> tempIDs = await printOnTheMeun(generator: generator, printdata: ret.upperMenu!);
          if (tempIDs.isNotEmpty) {
            queueIDs.addAll([
              {"onTheMenu": tempIDs}
            ]);
          }
        }

        ///打印客户记录
        if (ret.customerRecord != null && ret.customerRecord!.isNotEmpty) {
          List<String> tempIDs = await printCustomerRecord(generator: generator, printdata: ret.customerRecord!);
          if (tempIDs.isNotEmpty) {
            queueIDs.addAll([
              {"customerRecord": tempIDs}
            ]);
          }
        }

        ///打印发票
        if (ret.receipt != null && ret.receipt!.isNotEmpty) {
          List<String> tempIDs = await printRecipt(generator: generator, printdata: ret.receipt!);
          if (tempIDs.isNotEmpty) {
            queueIDs.addAll([
              {"receipt": tempIDs}
            ]);
          }
        }

        if (ret.openDrawer != null && ret.openDrawer!.queueID!.isNotEmpty) {
          final bool openDrawerResult = await openDrawer(generator: generator, printData: ret.openDrawer!);
          if (openDrawerResult) {
            queueIDs.addAll([
              {"openDrawer": ret.openDrawer!.queueID!}
            ]);
          }
        }
        if (ret.takeaway != null && ret.takeaway!.isNotEmpty) {
          List<String> tempIDs = await printTakeaway(generator: generator, printdata: ret.takeaway!);
          if (tempIDs.isNotEmpty) {
            queueIDs.addAll([
              {"takeaway": tempIDs}
            ]);
          }
        }

        //logger.f(jsonEncode(queueIDs));

        ///发票号码发送给后端
        if (queueIDs.isNotEmpty) {
          bool delRet = await deleteQueue(queryData!, queueIDs);
          if (delRet) {
            printStatus = true;
          }
        } else {
          printStatus = true;
        }
      } else {
        printStatus = true;
      }
    } else {
      printStatus = true;
    }
  } catch (e) {
    printStatus = true;
    debugPrint(e.toString());
  }
}

Future<void> win32StopTask() async {
  printStatus = false;
  final bool isRunning = win32TimerIsRunning(); // 检查timer是否在运行
  if (isRunning) {
    // 允许系统休眠
    allowSleep();

    // 关闭托盘图标
    await closeIcon();

    // 停止定时器
    _windowsTimer?.cancel();
  }
}

//检测timer是否在运行
bool win32TimerIsRunning() {
  return _windowsTimer != null && _windowsTimer!.isActive;
}

// 异步函数，用于显示图标
Future<void> showIcon() async {
  // 设置托盘图标为leaf.ico
  await TrayManager.instance.setIcon('assets/print.ico');
  // 设置托盘提示信息为Task Airprint Running
  await TrayManager.instance.setToolTip("Task Airprint Running");
}

// 关闭托盘图标
Future<void> closeIcon() async {
  TrayManager.instance.destroy();
}
