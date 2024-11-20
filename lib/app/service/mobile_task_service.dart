import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';

import '../config.dart';
import '../model/login_model.dart';
import '../model/printer_model.dart';
import 'print_method.dart';
import 'service_globals.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      autoStartOnBoot: false,
    ),
    iosConfiguration: IosConfiguration(),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  printStatus = true;
  debugPrint("开始服务:$printStatus");
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  UserData? cachedLoginUser;

  Future<void> updateCachedData() async {
    try {
      cachedLoginUser = await getLoginInfo();
      debugPrint("缓存数据更新完成: ${cachedLoginUser?.toJson()}");
    } catch (e) {
      debugPrint("更新缓存数据失败: $e");
    }
  }

  // 初始化缓存数据
  await updateCachedData();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      debugPrint("设置前台服务");
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      debugPrint("设置后台服务");
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    printStatus = false;
    debugPrint("停止服务:$printStatus");
    if (timer?.isActive == true) {
      timer!.cancel();
    }
    service.stopSelf();
  });

  timer = Timer.periodic(const Duration(seconds: 5), (_) async {
    try {
      // 如果缓存数据为空，尝试重新获取
      if (cachedLoginUser == null) {
        await updateCachedData();
        if (cachedLoginUser == null) {
          debugPrint("无法获取登录信息，跳过本次任务");
          return;
        }
      }

      final station = cachedLoginUser?.station;
      final airprintStation = cachedLoginUser?.airPrintStation;

      // 检查数据一致性
      if (station == null || airprintStation == null || station != airprintStation) {
        debugPrint("本地信息为空或打印机信息不一致");
        return;
      }

      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: "Printer Service running",
            content: "Updated at ${DateTime.now()}",
          );
        }
      }

      debugPrint("打印状态：$printStatus");
      if (printStatus) {
        printStatus = false;
        getPrintData(queryData: cachedLoginUser!.toJson());
      }
    } catch (e) {
      debugPrint("后台任务异常: $e");
    }
  });

  // 定期刷新缓存数据
  Timer.periodic(const Duration(minutes: 1), (_) async {
    await updateCachedData();
  });
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
        generator.setGlobalCodeTable('CP1252');
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
