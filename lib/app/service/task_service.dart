import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:image/image.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../config.dart';
import '../model/login_model.dart';
import '../model/printer_model.dart';
import '../utils/esc_helper.dart';
import '../utils/stroage_manage.dart';
import 'api_client.dart';

Timer? timer;
RxBool isRunning = false.obs;
bool printStatus = true;
final ApiClient apiClient = ApiClient();
final StorageManage box = StorageManage();
final Logger logger = Logger();

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
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
  WidgetsFlutterBinding.ensureInitialized();
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

  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Printer Service running",
          content: "Updated at ${DateTime.now()}",
        );
      }
    }
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

        const PaperSize paper = PaperSize.mm80;
        final profile = await CapabilityProfile.load();
        final printer = NetworkPrinter(paper, profile);
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
          List<String> qrcodeIDs = await printQrCode(printer: printer, printData: ret.qrCodeData!);
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
            List<Map<String, dynamic>> tempOtherIDs = await printOtherkichen(printer, otherKitchen, ret.isPrintPrice!);
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
            List<String> tempKitchenInvoice = await printkichen(printer, kitchenData, ret.isPrintPrice!);
            if (tempKitchenInvoice.isNotEmpty) {
              kitchenInvocie.addAll(tempKitchenInvoice);
            }
          }

          ///打印班地尼
          if (bDLData.isNotEmpty) {
            List<String> tempBDLInvoice = await printBDL(printer, bDLData, ret.isPrintPrice!);
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
          List<String> tempIDs = await printOnTheMeun(printer: printer, printdata: ret.upperMenu!);
          if (tempIDs.isNotEmpty) {
            queueIDs.addAll([
              {"onTheMenu": tempIDs}
            ]);
          }
        }

        ///打印客户记录
        if (ret.customerRecord != null && ret.customerRecord!.isNotEmpty) {
          List<String> tempIDs = await printCustomerRecord(printer: printer, printdata: ret.customerRecord!);
          if (tempIDs.isNotEmpty) {
            queueIDs.addAll([
              {"customerRecord": tempIDs}
            ]);
          }
        }

        ///打印发票
        if (ret.receipt != null && ret.receipt!.isNotEmpty) {
          List<String> tempIDs = await printRecipt(printer: printer, printdata: ret.receipt!);
          if (tempIDs.isNotEmpty) {
            queueIDs.addAll([
              {"receipt": tempIDs}
            ]);
          }
        }

        if (ret.openDrawer != null && ret.openDrawer!.queueID!.isNotEmpty) {
          final bool openDrawerResult = await openDrawer(printer: printer, printData: ret.openDrawer!);
          if (openDrawerResult) {
            queueIDs.addAll([
              {"openDrawer": ret.openDrawer!.queueID!}
            ]);
          }
        }
        if (ret.takeaway != null && ret.takeaway!.isNotEmpty) {
          List<String> tempIDs = await printTakeaway(printer: printer, printdata: ret.takeaway!);
          if (tempIDs.isNotEmpty) {
            queueIDs.addAll([
              {"takeaway": tempIDs}
            ]);
          }
        }

        //logger.f(jsonEncode(queueIDs));

        ///发票号码发送给后端
        if (queueIDs.isNotEmpty) {
          await deleteQueue(queryData!, queueIDs);
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

///发送已打印队列ids到后端
Future<void> deleteQueue(Map<String, dynamic> queryData, List queueIDs) async {
  try {
    var res = await apiClient
        .post(Config.sendInvoices, data: {"loginUserInfo": jsonEncode(queryData), "queueIDs": jsonEncode(queueIDs)});
    if (res.statusCode == 200) {
      if (res.data != null) {
        printStatus = true;
      }
    } else {
      printStatus = true;
    }
  } catch (e) {
    printStatus = true;
  }
}

///获取本地存储信息
Future<UserData?> getLoginInfo() async {
  var loginUserJson = await box.read(Config.localStroageloginInfo);
  UserData? loginUser = loginUserJson != null ? UserData.fromJson(loginUserJson) : null;
  if (loginUser != null) {
    return loginUser;
  }
  return null;
}

///执行打印二维码
Future<List<String>> printQrCode({
  required NetworkPrinter printer,
  required List<QrCodeData> printData,
}) async {
  List<String> queueID = [];
  try {
    for (var element in printData) {
      final res = await printer.connect(element.ip!, port: 9100);
      if (res == PosPrintResult.success) {
        debugPrint("打印机连接成功:${element.ip}");

        //中文名
        if (element.mNameChinese != null && element.mNameChinese!.isNotEmpty) {
          printer.text(
            EscHelper.alignCenterPrint(width: 24, content: "${element.mNameChinese}"),
            styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),
            containsChinese: true,
          );
          printer.feed(element.mPrinterType == "EPSON" ? 3 : 1);
        }
        //英文名
        if (element.mNameEnglish != null && element.mNameEnglish!.isNotEmpty) {
          printer.text(
            EscHelper.alignCenterPrint(width: 24, content: "${element.mNameEnglish}"),
            styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),
            containsChinese: true,
          );
          printer.feed(element.mPrinterType == "EPSON" ? 3 : 1);
        }

        //地址
        if (element.mAddress != null && element.mAddress!.isNotEmpty) {
          List<String> addressList = EscHelper.strToList(str: element.mAddress!, splitLength: 24);
          for (var address in addressList) {
            printer.text(
              EscHelper.alignCenterPrint(width: 24, content: address),
              styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),
              containsChinese: true,
            );
            printer.feed(element.mPrinterType == "EPSON" ? 3 : 1);
          }
        }
        //台名单号
        printer.text(
          EscHelper.alignCenterPrint(
              width: 24,
              content: "檯號/單號: ${element.mTableNo} / ${element.mInvoiceNo!.substring(element.mInvoiceNo!.length - 4)}"),
          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),
          containsChinese: true,
        );
        printer.feed(element.mPrinterType == "EPSON" ? 3 : 1);

        printer.text(
          "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: "員工", width: 6)}:${EscHelper.columnMaker(content: "${element.mSalesmanCode}", width: 22)}${EscHelper.columnMaker(content: "收銀機", width: 6)}:${EscHelper.columnMaker(content: "${element.mSalesmanCode}", width: 12)}",
          containsChinese: true,
        );

        printer.text(
          "${EscHelper.columnMaker(content: "日期", width: 6)}:${EscHelper.columnMaker(content: "${element.mInvoiceDate}", width: 22)}${EscHelper.columnMaker(content: "人數", width: 6)}:${EscHelper.columnMaker(content: "${element.mPnum}", width: 12)}",
          containsChinese: true,
        );

        printer.feed(element.mPrinterType == "EPSON" ? 3 : 1);

        try {
          final String qrData = element.url!;
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

          printer.image(img!);
        } catch (e) {
          debugPrint("二维码生成失败: $e");
        }

        printer.feed(element.mPrinterType == "EPSON" ? 3 : 1);
        printer.text(
          EscHelper.alignCenterPrint(width: 24, content: "請掃描上面二維碼自助點餐"),
          styles: const PosStyles(
            bold: true,
            width: PosTextSize.size2,
            height: PosTextSize.size2,
          ),
          containsChinese: true,
        );
        printer.feed(element.mPrinterType == "EPSON" ? 25 : 2);
        printer.cut();
        printer.disconnect();
        if (element.mInvoiceNo.toString() != "") {
          queueID.add("${element.queueID}");
        }
      } else {
        debugPrint("打印机连接失败:${element.ip}");
      }
    }
  } catch (e) {
    debugPrint("打印过程中出现错误: $e");
  }
  return queueID.toSet().toList();
}

///开始打印厨房单
Future<List<String>> printkichen(
    NetworkPrinter printer, Map<String, Map<String, Map<int, List<Kitchen>>>> printData, int isPrintPrice) async {
  List<String> queueIDs = [];
  // 遍历第一级 Map，即 mLanIP
  for (var entry in printData.entries) {
    final ip = entry.key;
    final item = entry.value;
    if (ip.isNotEmpty) {
      final PosPrintResult linkret = await printer.connect(ip, port: 9100);

      if (PosPrintResult.success == linkret) {
        debugPrint("打印机$ip连接成功");
        //遍历第二级 Map，即 mInvoiceNo
        for (var invoiceEntry in item.entries) {
          //final String invoiceNo = invoiceEntry.key;
          final Map<int, List<Kitchen>> continueMap = invoiceEntry.value;

          // 遍历第三级 Map，即 mContinue
          for (var continueEntry in continueMap.entries) {
            int iscontinue = continueEntry.key;
            List<Kitchen> kitchens = continueEntry.value;

            if (iscontinue == 0) {
              ///不连续打印
              for (int i = 0; i < kitchens.length; i++) {
                //台号
                printer.text(
                  EscHelper.alignCenterPrint(width: 16, content: "檯:${kitchens[i].mTableNo}"),
                  linesAfter: 1,
                  styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                  containsChinese: true,
                );

                if (kitchens[i].mPrinterType != "" && kitchens[i].mPrinterType == "EPSON") {
                  printer.feed(4);
                }
                //单号
                printer.row([
                  PosColumn(
                      text: "${kitchens[i].mStationCode}",
                      width: 4,
                      containsChinese: true,
                      styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true)),
                  PosColumn(
                      text: "單號：",
                      width: 4,
                      containsChinese: true,
                      styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true)),
                  PosColumn(
                      text: kitchens[i].mInvoiceNo!.substring(kitchens[i].mInvoiceNo!.length - 4),
                      width: 4,
                      containsChinese: true,
                      styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true))
                ]);

                //日期人数
                printer.row([
                  PosColumn(
                      text: "${kitchens[i].invoiceDate}",
                      width: 4,
                      containsChinese: true,
                      styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2)),
                  PosColumn(
                      text: "${kitchens[i].invoiceTime}",
                      width: 4,
                      containsChinese: true,
                      styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2)),
                  PosColumn(
                      text: "人數：",
                      width: 2,
                      containsChinese: true,
                      styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2)),
                  PosColumn(
                      text: "${kitchens[i].mPnum}",
                      width: 2,
                      containsChinese: true,
                      styles:
                          const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, align: PosAlign.left)),
                ]);
                if (kitchens[i].mPrinterType != "" && kitchens[i].mPrinterType == "EPSON") {
                  printer.feed(2);
                } else {
                  printer.feed(1);
                }
                //名称
                var printName = EscHelper.strToList(str: kitchens[i].mBarcodeName!, splitLength: 20);

                if (printName.isNotEmpty) {
                  for (int j = 0; j < printName.length; j++) {
                    if (j == 0) {
                      printer.text(
                          EscHelper.columnMaker(content: '${kitchens[i].mQty}', width: 4) +
                              EscHelper.columnMaker(content: printName[j], width: 20),
                          linesAfter: 0,
                          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                          containsChinese: true);
                    } else if (printName[j].isNotEmpty) {
                      printer.text(
                          EscHelper.columnMaker(content: '', width: 4) +
                              EscHelper.columnMaker(content: printName[j], width: 20),
                          linesAfter: 0,
                          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                          containsChinese: true);
                    }
                  }
                }
                //备注
                if (kitchens[i].mRemarks != '') {
                  var printRemarks = EscHelper.strToList(str: kitchens[i].mRemarks ?? "", splitLength: 20);
                  if (printRemarks.isNotEmpty) {
                    for (int k = 0; k < printRemarks.length; k++) {
                      printer.text(
                        '${EscHelper.columnMaker(content: '', width: 4)}${EscHelper.columnMaker(content: printRemarks[k], width: 20)}',
                        linesAfter: 0,
                        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                        containsChinese: true,
                      );
                    }
                  }
                }

                //价格
                if (isPrintPrice == 0) {
                  printer.text(
                    EscHelper.columnMaker(content: "\$${kitchens[i].mPrice}", width: 24, align: 2),
                    styles: const PosStyles(
                      width: PosTextSize.size2,
                      height: PosTextSize.size2,
                      bold: true,
                    ),
                  );
                }
                if (kitchens[i].mPrinterType != "" && kitchens[i].mPrinterType == "EPSON") {
                  printer.feed(5);
                } else {
                  printer.feed(1);
                }
                //台号
                printer.text(
                  EscHelper.alignCenterPrint(width: 16, content: "檯:${kitchens[i].mTableNo}"),
                  linesAfter: 0,
                  styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                  containsChinese: true,
                );
                if (kitchens[i].mPrinterType != "" && kitchens[i].mPrinterType == "EPSON") {
                  printer.feed(18);
                } else {
                  printer.feed(1);
                }
                queueIDs.add("${kitchens[i].queueID}");
                printer.cut();
              }
            } else {
              ///连续打印

              //台号
              printer.text(
                EscHelper.alignCenterPrint(width: 16, content: "檯:${kitchens[0].mTableNo}"),
                linesAfter: 1,
                styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                containsChinese: true,
              );

              if (kitchens.first.mPrinterType != "" && kitchens.first.mPrinterType == "EPSON") {
                printer.feed(4);
              }
              //单号
              printer.row([
                PosColumn(
                    text: "${kitchens.first.mStationCode}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true)),
                PosColumn(
                    text: "單號：",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true)),
                PosColumn(
                    text: kitchens.first.mInvoiceNo!.substring(kitchens.first.mInvoiceNo!.length - 4),
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true))
              ]);
              //日期人数
              printer.row([
                PosColumn(
                    text: "${kitchens.first.invoiceDate}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2)),
                PosColumn(
                    text: "${kitchens.first.invoiceTime}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2)),
                PosColumn(
                    text: "人數：",
                    width: 2,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2)),
                PosColumn(
                    text: "${kitchens.first.mPnum}",
                    width: 2,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, align: PosAlign.left)),
              ]);
              if (kitchens.first.mPrinterType != "" && kitchens.first.mPrinterType == "EPSON") {
                printer.feed(2);
              } else {
                printer.feed(1);
              }
              for (int i = 0; i < kitchens.length; i++) {
                queueIDs.add("${kitchens[i].queueID}");
                //名称
                var printName = EscHelper.strToList(str: kitchens[i].mBarcodeName ?? "", splitLength: 20);

                if (printName.isNotEmpty) {
                  for (int j = 0; j < printName.length; j++) {
                    if (j == 0) {
                      printer.text(
                          EscHelper.columnMaker(content: "${kitchens[i].mQty}", width: 4) +
                              EscHelper.columnMaker(content: printName[j], width: 20),
                          linesAfter: 0,
                          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                          containsChinese: true);
                    } else if (printName[j].isNotEmpty) {
                      printer.text(
                          EscHelper.columnMaker(content: "", width: 4) +
                              EscHelper.columnMaker(content: printName[j], width: 20),
                          linesAfter: 0,
                          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                          containsChinese: true);
                    }
                  }
                }
                //备注
                if (kitchens[i].mRemarks != '') {
                  var printRemarks = EscHelper.strToList(str: kitchens[i].mRemarks ?? "", splitLength: 20);
                  if (printRemarks.isNotEmpty) {
                    for (int k = 0; k < printRemarks.length; k++) {
                      printer.text(
                        '${EscHelper.columnMaker(content: '', width: 4)}${EscHelper.columnMaker(content: printRemarks[k], width: 20)}',
                        linesAfter: 0,
                        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                        containsChinese: true,
                      );
                    }
                  }
                }

                //价格
                if (isPrintPrice == 0) {
                  printer.text(
                    EscHelper.columnMaker(content: "\$${kitchens[i].mPrice}", width: 24, align: 2),
                    styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
                  );
                }
                if (kitchens[i].mPrinterType != "" && kitchens[i].mPrinterType == "EPSON") {
                  printer.feed(5);
                } else {
                  printer.feed(1);
                }
              }
              //台号
              printer.text(
                EscHelper.alignCenterPrint(width: 16, content: "檯:${kitchens.first.mTableNo}"),
                linesAfter: 1,
                styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                containsChinese: true,
              );

              if (kitchens.first.mPrinterType != "" && kitchens.first.mPrinterType == "EPSON") {
                printer.feed(18);
              }
              printer.cut();
            }
          }
        }

        printer.disconnect();
      } else {
        debugPrint("打印機$ip連接失敗");
      }
    }
  }
  return queueIDs.toSet().toList();
}

//打印BDL单
Future<List<String>> printBDL(
    NetworkPrinter printer, Map<String, Map<String, Map<int, List<Kitchen>>>> printData, int isPrintPrice) async {
  List<String> queueIDs = [];
  // 遍历第一级 Map，即 mLanIP
  for (var entry in printData.entries) {
    final ip = entry.key;
    final item = entry.value;
    if (ip.isNotEmpty) {
      final PosPrintResult linkret = await printer.connect(ip, port: 9100);

      if (PosPrintResult.success == linkret) {
        debugPrint("打印机$ip连接成功");
        //遍历第二级 Map，即 mInvoiceNo
        for (var invoiceEntry in item.entries) {
          //final String invoiceNo = invoiceEntry.key;
          final Map<int, List<Kitchen>> continueMap = invoiceEntry.value;

          // 遍历第三级 Map，即 mContinue
          for (var continueEntry in continueMap.entries) {
            int iscontinue = continueEntry.key;
            List<Kitchen> kitchens = continueEntry.value;

            if (iscontinue == 0) {
              ///不连续打印
              for (int i = 0; i < kitchens.length; i++) {
                //上菜单
                printer.text(
                  EscHelper.alignCenterPrint(width: 16, content: "上菜單"),
                  linesAfter: 1,
                  styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                  containsChinese: true,
                );
                printer.feed(kitchens.first.bDLPrinterType == "EPSON" ? 3 : 1);
                //台号
                printer.text(
                  EscHelper.alignCenterPrint(width: 16, content: "檯:${kitchens[i].mTableNo}"),
                  linesAfter: 1,
                  styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                  containsChinese: true,
                );

                if (kitchens[i].mPrinterType != "" && kitchens[i].mPrinterType == "EPSON") {
                  printer.feed(4);
                }
                //单号
                printer.row([
                  PosColumn(
                      text: "${kitchens[i].mStationCode}",
                      width: 4,
                      containsChinese: true,
                      styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true)),
                  PosColumn(
                      text: "單號：",
                      width: 4,
                      containsChinese: true,
                      styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true)),
                  PosColumn(
                      text: kitchens[i].mInvoiceNo!.substring(kitchens[i].mInvoiceNo!.length - 4),
                      width: 4,
                      containsChinese: true,
                      styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true))
                ]);

                //日期人数
                printer.row([
                  PosColumn(
                      text: "${kitchens[i].invoiceDate}",
                      width: 4,
                      containsChinese: true,
                      styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2)),
                  PosColumn(
                      text: "${kitchens[i].invoiceTime}",
                      width: 4,
                      containsChinese: true,
                      styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2)),
                  PosColumn(
                      text: "人數：",
                      width: 2,
                      containsChinese: true,
                      styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2)),
                  PosColumn(
                      text: "${kitchens[i].mPnum}",
                      width: 2,
                      containsChinese: true,
                      styles:
                          const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, align: PosAlign.left)),
                ]);
                if (kitchens[i].mPrinterType != "" && kitchens[i].mPrinterType == "EPSON") {
                  printer.feed(2);
                } else {
                  printer.feed(1);
                }
                //名称
                var printName = EscHelper.strToList(str: kitchens[i].mBarcodeName!, splitLength: 20);

                if (printName.isNotEmpty) {
                  for (int j = 0; j < printName.length; j++) {
                    if (j == 0) {
                      printer.text(
                          EscHelper.columnMaker(content: '${kitchens[i].mQty}', width: 4) +
                              EscHelper.columnMaker(content: printName[j], width: 20),
                          linesAfter: 0,
                          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                          containsChinese: true);
                    } else if (printName[j].isNotEmpty) {
                      printer.text(
                          EscHelper.columnMaker(content: '', width: 4) +
                              EscHelper.columnMaker(content: printName[j], width: 20),
                          linesAfter: 0,
                          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                          containsChinese: true);
                    }
                  }
                }
                //备注
                if (kitchens[i].mRemarks != '') {
                  var printRemarks = EscHelper.strToList(str: kitchens[i].mRemarks ?? "", splitLength: 20);
                  if (printRemarks.isNotEmpty) {
                    for (int k = 0; k < printRemarks.length; k++) {
                      printer.text(
                        '${EscHelper.columnMaker(content: '', width: 4)}${EscHelper.columnMaker(content: printRemarks[k], width: 20)}',
                        linesAfter: 0,
                        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                        containsChinese: true,
                      );
                    }
                  }
                }

                //价格
                if (isPrintPrice == 0) {
                  printer.text(
                    EscHelper.columnMaker(content: "\$${kitchens[i].mPrice}", width: 24, align: 2),
                    styles: const PosStyles(
                      width: PosTextSize.size2,
                      height: PosTextSize.size2,
                      bold: true,
                    ),
                  );
                }
                if (kitchens[i].mPrinterType != "" && kitchens[i].mPrinterType == "EPSON") {
                  printer.feed(5);
                } else {
                  printer.feed(1);
                }
                //台号
                printer.text(
                  EscHelper.alignCenterPrint(width: 16, content: "檯:${kitchens[i].mTableNo}"),
                  linesAfter: 0,
                  styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                  containsChinese: true,
                );
                if (kitchens[i].mPrinterType != "" && kitchens[i].mPrinterType == "EPSON") {
                  printer.feed(18);
                } else {
                  printer.feed(1);
                }
                queueIDs.add("${kitchens[i].queueID}");
                printer.cut();
              }
            } else {
              ///连续打印

              //上菜单
              printer.text(
                EscHelper.alignCenterPrint(width: 16, content: "上菜單"),
                linesAfter: 1,
                styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                containsChinese: true,
              );
              printer.feed(kitchens.first.bDLPrinterType == "EPSON" ? 3 : 1);
              //台号
              printer.text(
                EscHelper.alignCenterPrint(width: 16, content: "檯:${kitchens[0].mTableNo}"),
                linesAfter: 1,
                styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                containsChinese: true,
              );

              if (kitchens.first.mPrinterType != "" && kitchens.first.mPrinterType == "EPSON") {
                printer.feed(4);
              }
              //单号
              printer.row([
                PosColumn(
                    text: "${kitchens.first.mStationCode}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true)),
                PosColumn(
                    text: "單號：",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true)),
                PosColumn(
                    text: kitchens.first.mInvoiceNo!.substring(kitchens.first.mInvoiceNo!.length - 4),
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true))
              ]);
              //日期人数
              printer.row([
                PosColumn(
                    text: "${kitchens.first.invoiceDate}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2)),
                PosColumn(
                    text: "${kitchens.first.invoiceTime}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2)),
                PosColumn(
                    text: "人數：",
                    width: 2,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2)),
                PosColumn(
                    text: "${kitchens.first.mPnum}",
                    width: 2,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, align: PosAlign.left)),
              ]);
              if (kitchens.first.mPrinterType != "" && kitchens.first.mPrinterType == "EPSON") {
                printer.feed(2);
              } else {
                printer.feed(1);
              }
              for (int i = 0; i < kitchens.length; i++) {
                queueIDs.add("${kitchens[i].queueID}");
                //名称
                var printName = EscHelper.strToList(str: kitchens[i].mBarcodeName ?? "", splitLength: 20);

                if (printName.isNotEmpty) {
                  for (int j = 0; j < printName.length; j++) {
                    if (j == 0) {
                      printer.text(
                          EscHelper.columnMaker(content: "${kitchens[i].mQty}", width: 4) +
                              EscHelper.columnMaker(content: printName[j], width: 20),
                          linesAfter: 0,
                          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                          containsChinese: true);
                    } else if (printName[j].isNotEmpty) {
                      printer.text(
                          EscHelper.columnMaker(content: "", width: 4) +
                              EscHelper.columnMaker(content: printName[j], width: 20),
                          linesAfter: 0,
                          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                          containsChinese: true);
                    }
                  }
                }
                //备注
                if (kitchens[i].mRemarks != '') {
                  var printRemarks = EscHelper.strToList(str: kitchens[i].mRemarks ?? "", splitLength: 20);
                  if (printRemarks.isNotEmpty) {
                    for (int k = 0; k < printRemarks.length; k++) {
                      printer.text(
                        '${EscHelper.columnMaker(content: '', width: 4)}${EscHelper.columnMaker(content: printRemarks[k], width: 20)}',
                        linesAfter: 0,
                        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                        containsChinese: true,
                      );
                    }
                  }
                }

                //价格
                if (isPrintPrice == 0) {
                  printer.text(
                    EscHelper.columnMaker(content: "\$${kitchens[i].mPrice}", width: 24, align: 2),
                    styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
                  );
                }
                if (kitchens[i].mPrinterType != "" && kitchens[i].mPrinterType == "EPSON") {
                  printer.feed(5);
                } else {
                  printer.feed(1);
                }
              }
              //台号
              printer.text(
                EscHelper.alignCenterPrint(width: 16, content: "檯:${kitchens.first.mTableNo}"),
                linesAfter: 1,
                styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                containsChinese: true,
              );

              if (kitchens.first.mPrinterType != "" && kitchens.first.mPrinterType == "EPSON") {
                printer.feed(18);
              }
              printer.cut();
            }
          }
        }

        printer.disconnect();
      } else {
        debugPrint("打印機$ip連接失敗");
      }
    }
  }
  return queueIDs.toSet().toList();
}

///开始打印其它厨房单
///d.mIsPrint P正常 PF 追单 PM 改单 PD  删单 PT  转台单 (pd改为D,其它改为Y)
Future<List<Map<String, dynamic>>> printOtherkichen(
    NetworkPrinter printer, List<Kitchen> printData, int isPrintPrice) async {
  List<Map<String, dynamic>> resultList = [];
  Map<String, Set<int>> resultMap = {};
  for (var kitchens in printData) {
    final PosPrintResult linkret = await printer.connect(kitchens.mLanIP!, port: 9100);
    if (linkret == PosPrintResult.success) {
      String content = "";
      switch (kitchens.mIsPrint) {
        case "PF":
          content = "追單";

        case "PM":
          content = "改單";

        case "PD":
          content = "刪單";
        case "PT":
          content = "轉檯單";
        default:
          content = "";
      }
      printer.text(
        EscHelper.alignCenterPrint(width: 16, content: content),
        linesAfter: 1,
        styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
        containsChinese: true,
      );

      //台号
      printer.text(
        EscHelper.alignCenterPrint(width: 16, content: "檯:${kitchens.mTableNo}"),
        linesAfter: 1,
        styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
        containsChinese: true,
      );

      if (kitchens.mPrinterType != "" && kitchens.mPrinterType == "EPSON") {
        printer.feed(4);
      }
      //单号
      printer.row([
        PosColumn(
            text: "${kitchens.mStationCode}",
            width: 4,
            containsChinese: true,
            styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true)),
        PosColumn(
            text: "單號：",
            width: 4,
            containsChinese: true,
            styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true)),
        PosColumn(
            text: kitchens.mInvoiceNo!.substring(kitchens.mInvoiceNo!.length - 4),
            width: 4,
            containsChinese: true,
            styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true))
      ]);

      //日期人数
      printer.row([
        PosColumn(
            text: "${kitchens.invoiceDate}",
            width: 4,
            containsChinese: true,
            styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2)),
        PosColumn(
            text: "${kitchens.invoiceTime}",
            width: 4,
            containsChinese: true,
            styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2)),
        PosColumn(
            text: "人數：",
            width: 2,
            containsChinese: true,
            styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2)),
        PosColumn(
            text: "${kitchens.mPnum}",
            width: 2,
            containsChinese: true,
            styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, align: PosAlign.left)),
      ]);
      if (kitchens.mPrinterType != "" && kitchens.mPrinterType == "EPSON") {
        printer.feed(2);
      } else {
        printer.feed(1);
      }
      //名称
      var printName = EscHelper.strToList(str: kitchens.mBarcodeName!, splitLength: 20);

      if (printName.isNotEmpty) {
        for (int j = 0; j < printName.length; j++) {
          if (j == 0) {
            printer.text(
                EscHelper.columnMaker(content: '${kitchens.mQty}', width: 4) +
                    EscHelper.columnMaker(content: printName[j], width: 20),
                linesAfter: 0,
                styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                containsChinese: true);
          } else if (printName[j].isNotEmpty) {
            printer.text(
                EscHelper.columnMaker(content: '', width: 4) + EscHelper.columnMaker(content: printName[j], width: 20),
                linesAfter: 0,
                styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                containsChinese: true);
          }
        }
      }
      //备注
      if (kitchens.mRemarks != '') {
        var printRemarks = EscHelper.strToList(str: kitchens.mRemarks ?? "", splitLength: 20);
        if (printRemarks.isNotEmpty) {
          for (int k = 0; k < printRemarks.length; k++) {
            printer.text(
              '${EscHelper.columnMaker(content: '', width: 4)}${EscHelper.columnMaker(content: printRemarks[k], width: 20)}',
              linesAfter: 0,
              styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
              containsChinese: true,
            );
          }
        }
      }

      //价格
      if (isPrintPrice == 0) {
        printer.text(
          EscHelper.columnMaker(content: "\$${kitchens.mPrice}", width: 24, align: 2),
          styles: const PosStyles(
            width: PosTextSize.size2,
            height: PosTextSize.size2,
            bold: true,
          ),
        );
      }
      if (kitchens.mPrinterType != "" && kitchens.mPrinterType == "EPSON") {
        printer.feed(5);
      } else {
        printer.feed(1);
      }
      //台号
      printer.text(
        EscHelper.alignCenterPrint(width: 16, content: "檯:${kitchens.mTableNo}"),
        linesAfter: 0,
        styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
        containsChinese: true,
      );
      if (kitchens.mPrinterType != "" && kitchens.mPrinterType == "EPSON") {
        printer.feed(18);
      } else {
        printer.feed(1);
      }

      printer.cut();
      String mIsPrint = kitchens.mIsPrint!;
      int queueID = kitchens.queueID!;

      if (!resultMap.containsKey(mIsPrint)) {
        resultMap[mIsPrint] = {};
      }
      if (resultMap.containsKey(mIsPrint)) {
        resultMap[mIsPrint]!.add(queueID);
      } else {
        resultMap[mIsPrint] = {queueID};
      }
      printer.disconnect();
    }
  }

  for (var entry in resultMap.entries) {
    resultList.add({
      "mIsPrint": entry.key, // entry.key 是 mIsPrint
      "queueID": entry.value.toList() // entry.value 是 Set<int>，转换为 List<int>
    });
  }
  return resultList;
}

///执行打印上菜单
Future<List<String>> printOnTheMeun({
  required NetworkPrinter printer,
  required UpperMenu printdata,
}) async {
  Set<String> queueID = {};
  try {
    List<UpperMenuData> upperMenuData = printdata.upperMenuData!;
    Map<String?, List<UpperMenuData>> upperGroup = groupBy(upperMenuData, (UpperMenuData rows) => rows.invoiceNo);
    if (upperGroup.isNotEmpty) {
      final PosPrintResult linkret = await printer.connect(printdata.ip!, port: 9100);
      if (linkret == PosPrintResult.success) {
        for (var item in upperGroup.entries) {
          List<UpperMenuData> upperGroupValue = item.value;
          //上菜单
          printer.text(
            EscHelper.alignCenterPrint(width: 16, content: "上菜單"),
            styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
            containsChinese: true,
          );
          printer.feed(1);
          //台号
          printer.text(
            EscHelper.alignCenterPrint(width: 16, content: "檯:${upperGroupValue.first.mTableNo}"),
            styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
            containsChinese: true,
            linesAfter: 0,
          );

          printer.feed(1);
          //员工行
          printer.text(
            "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: "員工", width: 8)}${EscHelper.columnMaker(content: ":${upperGroupValue.first.mSalesmanCode}", width: 16)}${EscHelper.columnMaker(content: "單號", width: 8)}${EscHelper.columnMaker(content: ":${EscHelper.setSize(size: 3)}${upperGroupValue.first.mInvoiceNo}", width: 8)}",
            containsChinese: true,
          );

          //日期行
          printer.text(
            "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: "日期", width: 8)}${EscHelper.columnMaker(content: ":${upperGroupValue.first.invoiceDate}", width: 16)}${EscHelper.columnMaker(content: "收銀機", width: 8)}${EscHelper.columnMaker(content: ":${upperGroupValue.first.mStationCode}", width: 16)}",
            containsChinese: true,
          );

          //时间行
          printer.text(
            "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: "入座時間", width: 8)}${EscHelper.columnMaker(content: ":${upperGroupValue.first.invoiceTime}", width: 16)}${EscHelper.columnMaker(content: "人數", width: 8)}${EscHelper.columnMaker(content: ":${upperGroupValue.first.mPnum}", width: 16)}",
            containsChinese: true,
          );

          //结账时间
          printer.text(
            "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: "結賬時間", width: 8)}${EscHelper.columnMaker(content: ":", width: 16)}${EscHelper.columnMaker(content: "檯", width: 8)}${EscHelper.columnMaker(content: ":${upperGroupValue.first.mTableNo}", width: 16)}",
            containsChinese: true,
          );
          printer.rawBytes(EscHelper.setSize().codeUnits);

          printer.hr();
          for (var upper in upperGroupValue) {
            //名稱
            final printName = EscHelper.strToList(str: upper.mBarcodeName ?? "", splitLength: 30);
            if (printName.isNotEmpty) {
              for (int i = 0; i < printName.length; i++) {
                printer.text(
                  "${EscHelper.columnMaker(content: i == 0 ? "${upper.invoiceTime}" : "", width: 8)}${EscHelper.columnMaker(content: printName[i].isNotEmpty ? printName[i] : "", width: 30)}${EscHelper.columnMaker(content: i == 0 ? upper.mQty ?? "" : "", width: 4)}${EscHelper.columnMaker(content: i == 0 ? upper.mPrice ?? "0.0" : "", width: 6, align: 2)}",
                  containsChinese: true,
                  styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
                );
              }
            }
            //備註
            final printRemaks = EscHelper.strToList(str: upper.mRemarks ?? "", splitLength: 29);
            for (int k = 0; k < printRemaks.length; k++) {
              printer.text(
                "${EscHelper.columnMaker(content: "", width: 10)}${EscHelper.columnMaker(content: printRemaks[k], width: 38)}",
                containsChinese: true,
                styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
              );
            }

            queueID.add(upper.queueID.toString());
          }

          printer.hr();
          printer.text(
            EscHelper.columnMaker(content: upperGroupValue.first.mAmount ?? "0.0", width: 48, align: 2),
            styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
            containsChinese: true,
          );
          printer.feed(2);

          printer.barcode(
              Barcode.code39(
                "${upperGroupValue.first.mInvoiceNo}".split(""),
              ),
              height: printdata.mPrinterType == "EPSON" ? 220 : 60);

          printer.feed(printdata.mPrinterType == "EPSON" ? 20 : 1);
          printer.cut();
        }
        printer.disconnect();
      } else {
        debugPrint("打印機${printdata.ip}連接失敗");
      }
    }
  } catch (e) {
    debugPrint("打印过程中出现错误: $e");
  }
  return queueID.toList();
}

///执行打印客户记录
Future<List<String>> printCustomerRecord({
  required NetworkPrinter printer,
  required List<Receipt> printdata,
}) async {
  Set<String> queueID = {};

  try {
    final PosPrintResult linkret = await printer.connect(printdata.first.mLanIP!, port: 9100);
    if (linkret == PosPrintResult.success) {
      for (var item in printdata) {
        //中文名称
        if (item.mNameChinese != null && item.mNameChinese!.isNotEmpty) {
          printer.text(
            EscHelper.alignCenterPrint(width: 24, content: "${item.mNameChinese}"),
            styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
            containsChinese: true,
          );
          printer.feed(item.mPrinterType == "EPSON" ? 3 : 1);
        }
        //英文名称
        if (item.mNameEnglish != null && item.mNameEnglish!.isNotEmpty) {
          printer.text(
            EscHelper.alignCenterPrint(width: 24, content: "${item.mNameEnglish}"),
            styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
            containsChinese: true,
          );
          printer.feed(item.mPrinterType == "EPSON" ? 3 : 1);
        }
        //地址
        if (item.mAddress != null && item.mAddress!.isNotEmpty) {
          List<String> addressList = EscHelper.strToList(str: item.mAddress!, splitLength: 24);
          for (var address in addressList) {
            printer.text(
              EscHelper.alignCenterPrint(width: 24, content: address),
              styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),
              containsChinese: true,
            );
            printer.feed(item.mPrinterType == "EPSON" ? 3 : 1);
          }
        }

        printer.feed(1);
        printer.hr();
        printer.text(
          EscHelper.alignCenterPrint(width: 24, content: "顧客記錄"),
          styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        printer.rawBytes(EscHelper.setAlign().codeUnits);
        //台/单号
        printer.text(
          "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: "檯/單號", width: 16)}${EscHelper.columnMaker(content: "${item.mTableNo}", width: 16)}${EscHelper.columnMaker(content: EscHelper.setSize(size: 3) + item.mInvoiceNo!.substring(item.mInvoiceNo!.length - 4), width: 8)}",
          containsChinese: true,
        );
        printer.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        //人数行
        printer.text(
          "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: "人數", width: 8)}${EscHelper.columnMaker(content: ":${item.mPnum}", width: 20)}${EscHelper.columnMaker(content: "客戶", width: 6)}${EscHelper.columnMaker(content: ":${item.mCustomerCode}", width: 14)}",
          containsChinese: true,
        );
        //入坐时间行
        printer.text(
          "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: "入座時間", width: 8)}${EscHelper.columnMaker(content: ":${item.mInvoiceDate}", width: 20)}${EscHelper.columnMaker(content: "收銀機", width: 6)}${EscHelper.columnMaker(content: ":${item.mStationCode}", width: 14)}",
          containsChinese: true,
        );
        //结账时间行
        printer.text(
          "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: "結賬時間", width: 8)}${EscHelper.columnMaker(content: ":${item.payTime}", width: 20)}${EscHelper.columnMaker(content: "員工", width: 6)}${EscHelper.columnMaker(content: ":${item.mSalesmanCode}", width: 14)}",
          containsChinese: true,
        );
        printer.feed(2);
        //明细表头
        printer.text(
          "${EscHelper.columnMaker(content: "項目", width: 34)}${EscHelper.columnMaker(content: "數量", width: 6)}${EscHelper.columnMaker(content: "金額", width: 8, align: 2)}",
          containsChinese: true,
        );

        //分割線
        printer.rawBytes(EscHelper.setSize().codeUnits);
        printer.hr();
        //明细内容
        final List<Detail> detail = item.detail!;
        if (detail.isNotEmpty) {
          printer.rawBytes(EscHelper.setSize(size: 1).codeUnits);
          for (int i = 0; i < detail.length; i++) {
            var printName = EscHelper.strToList(str: detail[i].mPrintName ?? "", splitLength: 34);
            for (int j = 0; j < printName.length; j++) {
              if (j == 0) {
                printer.text(
                  "${EscHelper.columnMaker(content: printName[j], width: 34)}${EscHelper.columnMaker(content: j == 0 ? "${detail[i].mQty}" : "", width: 6)}${EscHelper.columnMaker(content: j == 0 ? "${detail[i].mAmount}" : "", width: 8, align: 2)}",
                  containsChinese: true,
                );
              }
            }
          }
        }
        //分割線
        printer.rawBytes(EscHelper.setSize().codeUnits);
        printer.hr();
        printer.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        //小计
        printer.text(
          "${EscHelper.columnMaker(content: "小計", width: 24)}${EscHelper.columnMaker(content: "${item.mNetAmt}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //服务费
        printer.text(
          "${EscHelper.columnMaker(content: "服務費", width: 24)}${EscHelper.columnMaker(content: "${item.mCharge}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //折扣
        printer.text(
          "${EscHelper.columnMaker(content: "折扣", width: 24)}${EscHelper.columnMaker(content: "${item.mDiscRate}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //折扣(\$)
        printer.text(
          "${EscHelper.columnMaker(content: "${"折扣"}(\$)", width: 24)}${EscHelper.columnMaker(content: "${item.mDiscAmt}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //合計
        printer.text(
          "${EscHelper.columnMaker(content: "總計", width: 24)}${EscHelper.columnMaker(content: "${item.mAmount}", width: 24, align: 2)}",
          containsChinese: true,
        );

        //分割線
        printer.rawBytes(EscHelper.setSize().codeUnits);
        printer.hr();
        printer.rawBytes(EscHelper.setAlign().codeUnits);
        printer.text("客戶簽名",
            containsChinese: true,
            styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: false));

        printer.feed(2);

        printer.barcode(
            Barcode.code39(
              item.mInvoiceNo!.substring(item.mInvoiceNo!.length - 4).split(""),
            ),
            height: item.mPrinterType == "EPSON" ? 220 : 60);

        printer.feed(item.mPrinterType == "EPSON" ? 20 : 1);
        printer.cut();
        queueID.add("${item.queueID}");
      }
      printer.disconnect();
    } else {
      debugPrint("打印機${printdata.first.mLanIP!}連接失敗");
    }
  } catch (e) {
    debugPrint("打印过程中出现错误: $e");
  }
  return queueID.toList();
}

///执行打印收据记录
Future<List<String>> printRecipt({
  required NetworkPrinter printer,
  required List<Receipt> printdata,
}) async {
  Set<String> queueID = {};

  try {
    final PosPrintResult linkret = await printer.connect(printdata.first.mLanIP!, port: 9100);
    if (linkret == PosPrintResult.success) {
      for (var item in printdata) {
        //中文名称
        if (item.mNameChinese != null && item.mNameChinese!.isNotEmpty) {
          printer.text(
            EscHelper.alignCenterPrint(width: 24, content: "${item.mNameChinese}"),
            styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
            containsChinese: true,
          );
          printer.feed(item.mPrinterType == "EPSON" ? 3 : 1);
        }
        //英文名称
        if (item.mNameEnglish != null && item.mNameEnglish!.isNotEmpty) {
          printer.text(
            EscHelper.alignCenterPrint(width: 24, content: "${item.mNameEnglish}"),
            styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
            containsChinese: true,
          );
          printer.feed(item.mPrinterType == "EPSON" ? 3 : 1);
        }
        //地址
        if (item.mAddress != null && item.mAddress!.isNotEmpty) {
          List<String> addressList = EscHelper.strToList(str: item.mAddress!, splitLength: 24);
          for (var address in addressList) {
            printer.text(
              EscHelper.alignCenterPrint(width: 24, content: address),
              styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),
              containsChinese: true,
            );
            printer.feed(item.mPrinterType == "EPSON" ? 3 : 1);
          }
        }

        printer.feed(1);
        printer.hr();
        printer.text(
          EscHelper.alignCenterPrint(width: 24, content: "收據"),
          styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        printer.rawBytes(EscHelper.setAlign().codeUnits);
        //台/单号
        printer.text(
          "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: "檯/單號", width: 16)}${EscHelper.columnMaker(content: "${item.mTableNo}", width: 16)}${EscHelper.columnMaker(content: EscHelper.setSize(size: 3) + item.mInvoiceNo!.substring(item.mInvoiceNo!.length - 4), width: 8)}",
          containsChinese: true,
        );
        printer.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        //人数行
        printer.text(
          "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: "人數", width: 8)}${EscHelper.columnMaker(content: ":${item.mPnum}", width: 20)}${EscHelper.columnMaker(content: "客戶", width: 6)}${EscHelper.columnMaker(content: ":${item.mCustomerCode}", width: 14)}",
          containsChinese: true,
        );
        //入坐时间行
        printer.text(
          "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: "入座時間", width: 8)}${EscHelper.columnMaker(content: ":${item.mInvoiceDate}", width: 20)}${EscHelper.columnMaker(content: "收銀機", width: 6)}${EscHelper.columnMaker(content: ":${item.mStationCode}", width: 14)}",
          containsChinese: true,
        );
        //结账时间行
        printer.text(
          "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: "結賬時間", width: 8)}${EscHelper.columnMaker(content: ":${item.payTime}", width: 20)}${EscHelper.columnMaker(content: "員工", width: 6)}${EscHelper.columnMaker(content: ":${item.mSalesmanCode}", width: 14)}",
          containsChinese: true,
        );
        printer.feed(2);
        //明细表头
        printer.text(
          "${EscHelper.columnMaker(content: "項目", width: 34)}${EscHelper.columnMaker(content: "數量", width: 6)}${EscHelper.columnMaker(content: "金額", width: 8, align: 2)}",
          containsChinese: true,
        );

        //分割線
        printer.rawBytes(EscHelper.setSize().codeUnits);
        printer.hr();
        //明细内容
        final List<Detail> detail = item.detail!;
        if (detail.isNotEmpty) {
          printer.rawBytes(EscHelper.setSize(size: 1).codeUnits);
          for (int i = 0; i < detail.length; i++) {
            var printName = EscHelper.strToList(str: detail[i].mPrintName ?? "", splitLength: 34);
            for (int j = 0; j < printName.length; j++) {
              if (j == 0) {
                printer.text(
                  "${EscHelper.columnMaker(content: printName[j], width: 34)}${EscHelper.columnMaker(content: j == 0 ? "${detail[i].mQty}" : "", width: 6)}${EscHelper.columnMaker(content: j == 0 ? "${detail[i].mAmount}" : "", width: 8, align: 2)}",
                  containsChinese: true,
                );
              }
            }
          }
        }
        //分割線
        printer.rawBytes(EscHelper.setSize().codeUnits);
        printer.hr();
        printer.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        //小计
        printer.text(
          "${EscHelper.columnMaker(content: "小計", width: 24)}${EscHelper.columnMaker(content: "${item.mNetAmt}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //服务费
        printer.text(
          "${EscHelper.columnMaker(content: "服務費", width: 24)}${EscHelper.columnMaker(content: "${item.mCharge}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //折扣
        printer.text(
          "${EscHelper.columnMaker(content: "折扣", width: 24)}${EscHelper.columnMaker(content: "${item.mDiscRate}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //折扣(\$)
        printer.text(
          "${EscHelper.columnMaker(content: "${"折扣"}(\$)", width: 24)}${EscHelper.columnMaker(content: "${item.mDiscAmt}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //合計
        printer.text(
          "${EscHelper.columnMaker(content: "總計", width: 24)}${EscHelper.columnMaker(content: "${item.mAmount}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //付款金额
        printer.text(
          "${EscHelper.columnMaker(content: "支付金額", width: 24)}${EscHelper.columnMaker(content: "${item.mPayAmount}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //找零
        printer.text(
          "${EscHelper.columnMaker(content: "找零", width: 24)}${EscHelper.columnMaker(content: "${item.mChange}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //分割線
        printer.rawBytes(EscHelper.setSize().codeUnits);
        printer.hr();

        //支付方式
        printer.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        printer.text(
          "${EscHelper.columnMaker(content: "支付方式", width: 34)}${EscHelper.columnMaker(content: "金額", width: 6)}${EscHelper.columnMaker(content: "小費", width: 8, align: 2)}",
          containsChinese: true,
        );
        //分割線
        printer.rawBytes(EscHelper.setSize().codeUnits);
        printer.hr();
        final List<PayType> payType = item.payType!;
        if (payType.isNotEmpty) {
          for (int i = 0; i < payType.length; i++) {
            printer.rawBytes(EscHelper.setSize(size: 1).codeUnits);
            printer.text(
              "${EscHelper.columnMaker(content: "${payType[i].mPaytype}", width: 34)}${EscHelper.columnMaker(content: "${payType[i].mAmount}", width: 6)}${EscHelper.columnMaker(content: "${payType[i].mTips}", width: 8, align: 2)}",
              containsChinese: true,
            );
          }
        }
        //分割線
        printer.rawBytes(EscHelper.setSize().codeUnits);
        printer.hr();

        printer.feed(2);

        printer.barcode(
            Barcode.code39(
              item.mInvoiceNo!.substring(item.mInvoiceNo!.length - 4).split(""),
            ),
            height: item.mPrinterType == "EPSON" ? 220 : 60);

        printer.feed(item.mPrinterType == "EPSON" ? 20 : 1);
        printer.cut();
        queueID.add("${item.queueID}");
      }
      printer.disconnect();
    } else {
      debugPrint("打印機${printdata.first.mLanIP!}連接失敗");
    }
  } catch (e) {
    debugPrint("打印过程中出现错误: $e");
  }
  return queueID.toList();
}

///执行弹框
Future<bool> openDrawer({
  required NetworkPrinter printer,
  required OpenDrawer printData,
}) async {
  try {
    final PosPrintResult linkret = await printer.connect(printData.iP!, port: 9100);
    if (linkret == PosPrintResult.success) {
      final List<int> queueID = printData.queueID!;
      debugPrint("打印机${printData.iP}连接成功");
      if (queueID.isNotEmpty) {
        printer.rawBytes(EscHelper.openCashDrawer().codeUnits);
      }
      printer.disconnect();
      return queueID.isNotEmpty ? true : false;
    } else {
      debugPrint("打印機${printData.iP!}連接失敗");
      return false;
    }
  } catch (e) {
    debugPrint("打印过程中出现错误: $e");
    return false;
  }
}

///执行打印外卖
Future<List<String>> printTakeaway({
  required NetworkPrinter printer,
  required List<Takeaway> printdata,
}) async {
  Set<String> queueID = {};

  try {
    final PosPrintResult linkret = await printer.connect(printdata.first.mLanIp!, port: 9100);
    if (linkret == PosPrintResult.success) {
      for (var item in printdata) {
        logger.i("打印开始:${item.toJson()}");

        //手机外卖
        printer.text(
          EscHelper.alignCenterPrint(width: 24, content: "外賣訂單"),
          styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        printer.feed(item.mPrinterType == "EPSON" ? 3 : 1);

        //单号

        printer.text(
          EscHelper.alignCenterPrint(
              width: 24,
              content: "#${item.mInvoiceNo!.substring(item.mInvoiceNo!.length - 4, item.mInvoiceNo!.length)}"),
          styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        printer.feed(item.mPrinterType == "EPSON" ? 3 : 1);

        //mCustTel(0自取1送餐) mCustFax(0儘快1預約時間)
        String method = "";
        String address = "";

        if (item.mCustTel.toString() == "0") {
          method += "自取:"; //自取
          if (item.mCustFax.toString() == "0") {
            method += "儘快"; //儘快
          } else {
            method += DateFormat('HH:mm').format(DateTime.parse(item.mCustDelTime.toString()));
          }
        } else if (item.mCustTel.toString() == "1") {
          method += "送餐:"; //送餐

          if (item.mCustFax.toString() == "0") {
            method += "儘快"; //儘快
          } else {
            var mCustDelTime = item.mCustDelTime;
            method += DateFormat('HH:mm').format(DateTime.parse(mCustDelTime.toString()));
          }

          if (item.mCustAttn != null || item.mCustAttn!.isNotEmpty) {
            address = item.mCustAttn!;
          }
        }

        if (method != "" && method.isNotEmpty) {
          printer.text(
            EscHelper.alignCenterPrint(width: 24, content: method),
            styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
            containsChinese: true,
          );
        }

        //地址
        if (address != "" && address.isNotEmpty) {
          printer.feed(item.mPrinterType == "EPSON" ? 3 : 1);
          List<String> addressList = EscHelper.strToList2(str: address, splitLength: 48);
          logger.i("打印地址:$addressList");
          for (var addressItem in addressList) {
            printer.text(
              EscHelper.alignCenterPrint(width: 48, content: addressItem),
              styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size1),
              containsChinese: true,
            );
          }
          printer.feed(item.mPrinterType == "EPSON" ? 3 : 1);
        }
        //时间
        printer.text(
          EscHelper.alignCenterPrint(width: 24, content: DateFormat('yyyy-MM-dd HH:mm:ss').format(item.mInvoiceDate!)),
          styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        //电话
        printer.text(
          EscHelper.alignCenterPrint(width: 24, content: item.mCustomerCode!.replaceFirst("+852", "+852 ")),
          styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );

        printer.feed(1);

        printer.hr();
        printer.rawBytes(EscHelper.setAlign().codeUnits + EscHelper.setSize(size: 1).codeUnits);
        final List<Map<String, InvoiceDetail>> details = item.invoiceDetails!;
        if (details.isNotEmpty) {
          for (var detail in details) {
            for (var li in detail.entries) {
              //父商品名称
              final List mPrintNameList = EscHelper.strToList(str: li.value.mBarcodeName ?? "", splitLength: 32);
              if (mPrintNameList.isNotEmpty) {
                for (var i = 0; i < mPrintNameList.length; i++) {
                  printer.text(
                    "${EscHelper.columnMaker(content: i == 0 ? "${li.value.mTime}" : "", width: 6)}${EscHelper.columnMaker(content: "${mPrintNameList[i]}", width: 32)}${EscHelper.columnMaker(content: "${li.value.mQty}", width: 4)}${EscHelper.columnMaker(content: i == 0 ? "${li.value.mPrice}" : "", width: 6, align: 2)}",
                    containsChinese: true,
                  );
                }
              }
              //套餐
              List<InvoiceDetail>? child = li.value.children;
              if (child != null && child.isNotEmpty) {
                for (var childItem in child) {
                  final List mPrintNameList = EscHelper.strToList(str: childItem.mBarcodeName ?? "", splitLength: 32);
                  if (mPrintNameList.isNotEmpty) {
                    for (var i = 0; i < mPrintNameList.length; i++) {
                      //套餐商品名称
                      printer.text(
                        "${EscHelper.columnMaker(content: i == 0 ? "${childItem.mTime}" : "", width: 6)}${EscHelper.columnMaker(content: "${mPrintNameList[i]}", width: 32)}${EscHelper.columnMaker(content: "${childItem.mQty}", width: 4)}${EscHelper.columnMaker(content: i == 0 ? "${childItem.mPrice}" : "", width: 6, align: 2)}",
                        containsChinese: true,
                      );
                      //套餐商品备注
                      final mRemarks = childItem.mRemarks;
                      if (mRemarks != null && mRemarks.isNotEmpty) {
                        final List mPrintRemarksList = EscHelper.strToList(str: childItem.mRemarks!, splitLength: 36);
                        for (var remarksItem in mPrintRemarksList) {
                          printer.text(
                            "${EscHelper.columnMaker(content: "", width: 6)}${EscHelper.columnMaker(content: "$remarksItem", width: 36)}${EscHelper.columnMaker(content: "", width: 6, align: 2)}",
                            containsChinese: true,
                          );
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        printer.rawBytes(EscHelper.setSize().codeUnits);
        printer.hr();
        printer.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        printer.text(EscHelper.columnMaker(content: "${item.mAmount}", width: 48, align: 2));
        printer.rawBytes(EscHelper.setSize().codeUnits);
        printer.barcode(
            Barcode.code39(
              item.mInvoiceNo!.substring(item.mInvoiceNo!.length - 4).split(""),
            ),
            height: item.mPrinterType == "EPSON" ? 220 : 60);
        printer.feed(item.mPrinterType == "EPSON" ? 20 : 1);
        printer.cut();

        queueID.add("${item.queueId}");
      }
      printer.disconnect();
    } else {
      debugPrint("打印機${printdata.first.mLanIp!}連接失敗");
    }
  } catch (e) {
    debugPrint("打印过程中出现错误: $e");
  }
  return queueID.toList();
}
