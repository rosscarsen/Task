import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:image/image.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../config.dart';
import '../model/login_model.dart';
import '../model/printer_model.dart';
import '../translations/app_translations.dart';
import '../utils/esc_helper.dart';
import '../utils/stroage_manage.dart';
import 'service_globals.dart';

///发送已打印队列ids到后端
Future<bool> deleteQueue(Map<String, dynamic> queryData, List queueIDs) async {
  try {
    var res = await apiClient.post(
      Config.sendInvoices,
      data: {"loginUserInfo": jsonEncode(queryData), "queueIDs": jsonEncode(queueIDs)},
    );

    if (res.statusCode == 200) {
      if (res.data != null) {
        return true;
      }
    }
    return true;
  } catch (e) {
    return true;
  }
}

//获取本地语言信息
String printerLocale(String key) {
  return AppTranslations().keys[printlang]?[key] ?? "";
}

///获取本地存储信息
Future<UserData?> getLoginInfo() async {
  final StorageManage box = StorageManage();
  var loginUserJson = await box.read(Config.localStroageloginInfo);
  UserData? loginUser = loginUserJson != null ? UserData.fromJson(loginUserJson) : null;
  if (loginUser != null) {
    return loginUser;
  }
  return null;
}

///执行打印二维码
Future<List<String>> printQrCode({required List<QrCodeData> printData}) async {
  List<String> queueID = [];
  try {
    for (var element in printData) {
      final printer = PrinterNetworkManager(element.ip!);
      PosPrintResult connect = await printer.connect();
      if (connect == PosPrintResult.success) {
        debugPrint("打印机连接成功:${element.ip}");
        List<int> bytes = [];
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm80, profile);

        if (element.mNameChinese != null && element.mNameChinese!.isNotEmpty) {
          bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
          bytes += generator.text(
            "${element.mNameChinese}",
            styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),
            containsChinese: true,
          );
        }
        //英文名
        if (element.mNameEnglish != null && element.mNameEnglish!.isNotEmpty) {
          bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
          bytes += generator.text(
            "${element.mNameEnglish}",
            styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),
            containsChinese: true,
          );
        }
        //地址
        if (element.mAddress != null && element.mAddress!.isNotEmpty) {
          bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
          List<String> addressList = EscHelper.splitString(str: element.mAddress!, splitLength: 24);
          for (var address in addressList) {
            bytes += generator.text(
              address,
              styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),
              containsChinese: true,
            );
          }
        }

        bytes += generator.feed(1);
        bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
        //檯號/單號
        bytes += generator.text(
          "${printerLocale(LocaleKeys.tableNo)}/${printerLocale(LocaleKeys.orderNo)}: ${element.mTableNo} / ${element.mInvoiceNo!.substring(element.mInvoiceNo!.length - 4)}",
          styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),
          containsChinese: true,
        );
        bytes += generator.feed(1);
        //设置左边对齐
        bytes += generator.rawBytes(EscHelper.setAlign(align: 0).codeUnits);

        bytes += generator.text(
          "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.employee), width: 6)}:${EscHelper.columnMaker(content: "${element.mSalesmanCode}", width: 22)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.station), width: 8)}:${EscHelper.columnMaker(content: "${element.mSalesmanCode}", width: 10)}",
          containsChinese: true,
        );

        bytes += generator.text(
          "${EscHelper.columnMaker(content: printerLocale(LocaleKeys.date), width: 6)}:${EscHelper.columnMaker(content: "${element.mInvoiceDate}", width: 22)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.peopleNumber), width: 8)}:${EscHelper.columnMaker(content: "${element.mPnum}", width: 10)}",
          containsChinese: true,
        );

        bytes += generator.emptyLines(1);
        try {
          final String qrData = element.url!;
          const double qrSize = 300;
          final uiImg = await QrPainter(data: qrData, version: QrVersions.auto, gapless: false).toImageData(qrSize);
          final dir = await getTemporaryDirectory();
          final pathName = '${dir.path}/qr_tmp.png';
          final qrFile = File(pathName);
          final imgFile = await qrFile.writeAsBytes(uiImg!.buffer.asUint8List());
          final img = decodeImage(imgFile.readAsBytesSync());
          bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
          bytes += generator.image(img!);
        } catch (e) {
          debugPrint("二维码生成失败: $e");
        }
        bytes += generator.feed(1);
        bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
        bytes += generator.text(
          printerLocale(LocaleKeys.scanQrCode),
          styles: const PosStyles(
            bold: true,
            width: PosTextSize.size2,
            height: PosTextSize.size2,
            align: PosAlign.center,
          ),
          containsChinese: true,
        );
        if ((element.mTradingInvoiceTerms?.isNotEmpty) ?? false) {
          bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
          bytes += generator.text(
            element.mTradingInvoiceTerms!,
            styles: const PosStyles(
              bold: true,
              width: PosTextSize.size2,
              height: PosTextSize.size2,
              align: PosAlign.center,
            ),
            containsChinese: true,
          );
        }
        bytes += generator.feed(2);
        bytes += generator.cut();
        bytes += generator.reset();
        PosPrintResult printing = await printer.printTicket(bytes);
        if (printing.msg == "Success") {
          if (element.mInvoiceNo.toString() != "") {
            queueID.add("${element.queueID}");
          }
        }
        printer.disconnect();
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
Future<Map<String, List<String>>> printkichen(
  Map<String, Map<String, Map<int, List<Kitchen>>>> printData,
  int isPrintPrice,
) async {
  List<String> queueID = [];
  List<String> detailID = [];
  if (printKitchenErrorCount >= cacheBackupCheckCount) {
    printKitchenErrorCount = 0;
  }

  // 遍历第一级 Map，即 mLanIP
  for (var entry in printData.entries) {
    final ip = entry.key;
    final item = entry.value;
    if (ip.isNotEmpty) {
      final printer = PrinterNetworkManager(ip);
      PosPrintResult connect = await printer.connect();
      if (PosPrintResult.success == connect) {
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
                List<int> bytes = [];
                final profile = await CapabilityProfile.load();
                final generator = Generator(PaperSize.mm80, profile);

                //台号
                bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
                bytes += generator.text(
                  "${printerLocale(LocaleKeys.table)}:${kitchens[i].mTableNo}",
                  styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                  containsChinese: true,
                );
                bytes += generator.rawBytes(EscHelper.setAlign(align: 0).codeUnits);
                //单号
                bytes += generator.row([
                  PosColumn(
                    text: "${kitchens[i].mStationCode}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
                  ),
                  PosColumn(
                    text: "${printerLocale(LocaleKeys.orderNo)}：",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
                  ),
                  PosColumn(
                    text: kitchens[i].mInvoiceNo!.substring(kitchens[i].mInvoiceNo!.length - 4),
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
                  ),
                ]);

                //日期人数
                bytes += generator.row([
                  PosColumn(
                    text: "${kitchens[i].invoiceDate}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
                  ),
                  PosColumn(
                    text: "${kitchens[i].invoiceTime}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
                  ),
                  PosColumn(
                    text: "${printerLocale(LocaleKeys.peopleNumber)}：",
                    width: 3,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
                  ),
                  PosColumn(
                    text: "${kitchens[i].mPnum}",
                    width: 1,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, align: PosAlign.left),
                  ),
                ]);

                bytes += generator.feed(1);

                //名称
                var printName = EscHelper.splitString(str: kitchens[i].mBarcodeName ?? "", splitLength: 20);

                if (printName.isNotEmpty) {
                  for (int j = 0; j < printName.length; j++) {
                    if (j == 0) {
                      bytes += generator.text(
                        EscHelper.columnMaker(content: '${kitchens[i].mQty}', width: 4) +
                            EscHelper.columnMaker(content: printName[j], width: 20),
                        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                        containsChinese: true,
                      );
                    } else if (printName[j].isNotEmpty) {
                      bytes += generator.text(
                        EscHelper.columnMaker(content: '', width: 4) +
                            EscHelper.columnMaker(content: printName[j], width: 20),
                        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                        containsChinese: true,
                      );
                    }
                  }
                }
                //备注
                if (kitchens[i].mRemarks?.isNotEmpty ?? false) {
                  var printRemarks = EscHelper.splitString(str: kitchens[i].mRemarks ?? "", splitLength: 20);
                  if (printRemarks.isNotEmpty) {
                    for (int k = 0; k < printRemarks.length; k++) {
                      bytes += generator.text(
                        '${EscHelper.columnMaker(content: '', width: 4)}${EscHelper.columnMaker(content: printRemarks[k], width: 20)}',
                        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                        containsChinese: true,
                      );
                    }
                  }
                }

                //价格
                if (isPrintPrice == 0) {
                  bytes += generator.text(
                    EscHelper.columnMaker(content: "\$${kitchens[i].mPrice}", width: 24, align: 2),
                    styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
                  );
                }

                bytes += generator.feed(1);

                //台号
                bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
                bytes += generator.text(
                  "${printerLocale(LocaleKeys.table)}:${kitchens[i].mTableNo}",
                  styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                  containsChinese: true,
                );
                bytes += generator.rawBytes(EscHelper.setAlign(align: 0).codeUnits);
                bytes += generator.feed(1);

                bytes += generator.cut();
                bytes += generator.reset();
                PosPrintResult printing = await printer.printTicket(bytes);
                if (printing.msg == "Success") {
                  queueID.add("${kitchens[i].queueID}");
                  detailID.add("${kitchens[i].mInvoiceDetailID}");
                }
              }
            } else {
              ///连续打印

              List<int> bytes = [];
              final profile = await CapabilityProfile.load();
              final generator = Generator(PaperSize.mm80, profile);

              //台号
              bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
              bytes += generator.text(
                "${printerLocale(LocaleKeys.table)}:${kitchens[0].mTableNo}",
                styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                containsChinese: true,
              );
              bytes += generator.rawBytes(EscHelper.setAlign(align: 0).codeUnits);
              //单号
              bytes += generator.row([
                PosColumn(
                  text: "${kitchens.first.mStationCode}",
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
                ),
                PosColumn(
                  text: "${printerLocale(LocaleKeys.orderNo)}：",
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
                ),
                PosColumn(
                  text: kitchens.first.mInvoiceNo!.substring(kitchens.first.mInvoiceNo!.length - 4),
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
                ),
              ]);
              //日期人数
              bytes += generator.row([
                PosColumn(
                  text: "${kitchens.first.invoiceDate}",
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
                ),
                PosColumn(
                  text: "${kitchens.first.invoiceTime}",
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
                ),
                PosColumn(
                  text: "${printerLocale(LocaleKeys.peopleNumber)}：",
                  width: 3,
                  containsChinese: true,
                  styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
                ),
                PosColumn(
                  text: "${kitchens.first.mPnum}",
                  width: 1,
                  containsChinese: true,
                  styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, align: PosAlign.left),
                ),
              ]);

              bytes += generator.feed(1);

              for (int i = 0; i < kitchens.length; i++) {
                //名称
                var printName = EscHelper.splitString(str: kitchens[i].mBarcodeName ?? "", splitLength: 20);
                if (printName.isNotEmpty) {
                  for (int j = 0; j < printName.length; j++) {
                    print("===>${printName[j]}");
                    if (j == 0) {
                      bytes += generator.text(
                        EscHelper.columnMaker(content: "${kitchens[i].mQty}", width: 4) +
                            EscHelper.columnMaker(content: printName[j], width: 20),
                        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                        containsChinese: true,
                      );
                    } else if (printName[j].isNotEmpty) {
                      bytes += generator.text(
                        EscHelper.columnMaker(content: "", width: 4) +
                            EscHelper.columnMaker(content: printName[j], width: 20),
                        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                        containsChinese: true,
                      );
                    }
                  }
                }
                //备注
                if (kitchens[i].mRemarks?.isNotEmpty ?? false) {
                  var printRemarks = EscHelper.splitString(str: kitchens[i].mRemarks ?? "", splitLength: 20);
                  if (printRemarks.isNotEmpty) {
                    for (int k = 0; k < printRemarks.length; k++) {
                      bytes += generator.text(
                        '${EscHelper.columnMaker(content: '', width: 4)}${EscHelper.columnMaker(content: printRemarks[k], width: 20)}',
                        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                        containsChinese: true,
                      );
                    }
                  }
                }

                //价格
                if (isPrintPrice == 0) {
                  bytes += generator.text(
                    EscHelper.columnMaker(content: "\$${kitchens[i].mPrice}", width: 24, align: 2),
                    styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
                  );
                }

                bytes += generator.feed(1);
              }
              //台号
              bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
              bytes += generator.text(
                "${printerLocale(LocaleKeys.table)}:${kitchens.first.mTableNo}",
                styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                containsChinese: true,
              );
              bytes += generator.rawBytes(EscHelper.setAlign(align: 0).codeUnits);
              bytes += generator.cut();
              bytes += generator.reset();
              PosPrintResult printing = await printer.printTicket(bytes);
              if (printing.msg == "Success") {
                queueID.addAll(kitchens.map((kitchen) => kitchen.queueID.toString()).toList());
                detailID.addAll(kitchens.map((kitchen) => kitchen.mInvoiceDetailID.toString()).toList());
              }
            }
          }
        }

        printer.disconnect();
      } else {
        if (cacheBackupCheckCount != 0) {
          printKitchenErrorCount++;
        }
        debugPrint("打印機$ip連接失敗");
      }
    }
  }
  return {"queueID": queueID.toSet().toList(), "detailID": detailID.toSet().toList()};
}

//打印BDL单
Future<Map<String, List<String>>> printBDL(
  Map<String, Map<String, Map<int, List<Kitchen>>>> printData,
  int isPrintPrice,
) async {
  List<String> queueID = [];
  List<String> detailID = [];
  if (printKitchenErrorCount >= cacheBackupCheckCount) {
    printKitchenErrorCount = 0;
  }
  // 遍历第一级 Map，即 mLanIP
  for (var entry in printData.entries) {
    final ip = entry.key;
    final item = entry.value;
    if (ip.isNotEmpty) {
      final printer = PrinterNetworkManager(ip);
      PosPrintResult connect = await printer.connect();
      if (PosPrintResult.success == connect) {
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
                List<int> bytes = [];
                final profile = await CapabilityProfile.load();
                final generator = Generator(PaperSize.mm80, profile);

                //上菜单
                bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
                bytes += generator.text(
                  printerLocale(LocaleKeys.pantry),
                  styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                  containsChinese: true,
                );
                bytes += generator.feed(1);
                //台号
                bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
                bytes += generator.text(
                  "${printerLocale(LocaleKeys.table)}:${kitchens[i].mTableNo}",
                  styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                  containsChinese: true,
                );
                bytes += generator.rawBytes(EscHelper.setAlign(align: 0).codeUnits);
                //单号
                bytes += generator.row([
                  PosColumn(
                    text: "${kitchens[i].mStationCode}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
                  ),
                  PosColumn(
                    text: "${printerLocale(LocaleKeys.orderNo)}：",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
                  ),
                  PosColumn(
                    text: kitchens[i].mInvoiceNo!.substring(kitchens[i].mInvoiceNo!.length - 4),
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
                  ),
                ]);

                //日期人数
                bytes += generator.row([
                  PosColumn(
                    text: "${kitchens[i].invoiceDate}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
                  ),
                  PosColumn(
                    text: "${kitchens[i].invoiceTime}",
                    width: 4,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
                  ),
                  PosColumn(
                    text: "${printerLocale(LocaleKeys.peopleNumber)}：",
                    width: 3,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
                  ),
                  PosColumn(
                    text: "${kitchens[i].mPnum}",
                    width: 1,
                    containsChinese: true,
                    styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, align: PosAlign.left),
                  ),
                ]);

                bytes += generator.feed(1);

                //名称
                var printName = EscHelper.splitString(str: kitchens[i].mBarcodeName!, splitLength: 20);

                if (printName.isNotEmpty) {
                  for (int j = 0; j < printName.length; j++) {
                    if (j == 0) {
                      bytes += generator.text(
                        EscHelper.columnMaker(content: '${kitchens[i].mQty}', width: 4) +
                            EscHelper.columnMaker(content: printName[j], width: 20),
                        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                        containsChinese: true,
                      );
                    } else if (printName[j].isNotEmpty) {
                      bytes += generator.text(
                        EscHelper.columnMaker(content: '', width: 4) +
                            EscHelper.columnMaker(content: printName[j], width: 20),
                        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                        containsChinese: true,
                      );
                    }
                  }
                }
                //备注
                if (kitchens[i].mRemarks?.isNotEmpty ?? false) {
                  var printRemarks = EscHelper.splitString(str: kitchens[i].mRemarks ?? "", splitLength: 20);
                  if (printRemarks.isNotEmpty) {
                    for (int k = 0; k < printRemarks.length; k++) {
                      bytes += generator.text(
                        '${EscHelper.columnMaker(content: '', width: 4)}${EscHelper.columnMaker(content: printRemarks[k], width: 20)}',
                        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                        containsChinese: true,
                      );
                    }
                  }
                }

                //价格
                if (isPrintPrice == 0) {
                  bytes += generator.text(
                    EscHelper.columnMaker(content: "\$${kitchens[i].mPrice}", width: 24, align: 2),
                    styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
                  );
                }

                bytes += generator.feed(1);

                //台号
                bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
                bytes += generator.text(
                  "${printerLocale(LocaleKeys.table)}:${kitchens[i].mTableNo}",
                  styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                  containsChinese: true,
                );

                bytes += generator.feed(1);

                bytes += generator.cut();
                bytes += generator.reset();
                PosPrintResult printing = await printer.printTicket(bytes);
                if (printing.msg == "Success") {
                  queueID.add("${kitchens[i].queueID}");
                  detailID.add("${kitchens[i].mInvoiceDetailID}");
                }
              }
            } else {
              ///连续打印
              List<int> bytes = [];
              final profile = await CapabilityProfile.load();
              final generator = Generator(PaperSize.mm80, profile);

              //上菜单
              bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
              bytes += generator.text(
                printerLocale(LocaleKeys.pantry),
                styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                containsChinese: true,
              );
              bytes += generator.feed(1);
              //台号
              bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
              bytes += generator.text(
                "檯:${kitchens[0].mTableNo}",
                styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                containsChinese: true,
              );
              bytes += generator.rawBytes(EscHelper.setAlign(align: 0).codeUnits);
              //单号
              bytes += generator.row([
                PosColumn(
                  text: "${kitchens.first.mStationCode}",
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
                ),
                PosColumn(
                  text: "${printerLocale(LocaleKeys.orderNo)}：",
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
                ),
                PosColumn(
                  text: kitchens.first.mInvoiceNo!.substring(kitchens.first.mInvoiceNo!.length - 4),
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
                ),
              ]);
              //日期人数
              bytes += generator.row([
                PosColumn(
                  text: "${kitchens.first.invoiceDate}",
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
                ),
                PosColumn(
                  text: "${kitchens.first.invoiceTime}",
                  width: 4,
                  containsChinese: true,
                  styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
                ),
                PosColumn(
                  text: "${printerLocale(LocaleKeys.peopleNumber)}：",
                  width: 3,
                  containsChinese: true,
                  styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
                ),
                PosColumn(
                  text: "${kitchens.first.mPnum}",
                  width: 1,
                  containsChinese: true,
                  styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, align: PosAlign.left),
                ),
              ]);

              bytes += generator.feed(1);

              for (int i = 0; i < kitchens.length; i++) {
                //名称
                var printName = EscHelper.splitString(str: kitchens[i].mBarcodeName ?? "", splitLength: 20);

                if (printName.isNotEmpty) {
                  for (int j = 0; j < printName.length; j++) {
                    if (j == 0) {
                      bytes += generator.text(
                        EscHelper.columnMaker(content: "${kitchens[i].mQty}", width: 4) +
                            EscHelper.columnMaker(content: printName[j], width: 20),
                        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                        containsChinese: true,
                      );
                    } else if (printName[j].isNotEmpty) {
                      bytes += generator.text(
                        EscHelper.columnMaker(content: "", width: 4) +
                            EscHelper.columnMaker(content: printName[j], width: 20),
                        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                        containsChinese: true,
                      );
                    }
                  }
                }
                //备注
                if (kitchens[i].mRemarks?.isNotEmpty ?? false) {
                  var printRemarks = EscHelper.splitString(str: kitchens[i].mRemarks ?? "", splitLength: 20);
                  if (printRemarks.isNotEmpty) {
                    for (int k = 0; k < printRemarks.length; k++) {
                      bytes += generator.text(
                        '${EscHelper.columnMaker(content: '', width: 4)}${EscHelper.columnMaker(content: printRemarks[k], width: 20)}',
                        styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
                        containsChinese: true,
                      );
                    }
                  }
                }

                //价格
                if (isPrintPrice == 0) {
                  bytes += generator.text(
                    EscHelper.columnMaker(content: "\$${kitchens[i].mPrice}", width: 24, align: 2),
                    styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
                  );
                }

                bytes += generator.feed(1);
              }
              //台号
              bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
              bytes += generator.text(
                "${printerLocale(LocaleKeys.table)}:${kitchens.first.mTableNo}",
                styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
                containsChinese: true,
              );
              bytes += generator.rawBytes(EscHelper.setAlign(align: 0).codeUnits);
              bytes += generator.cut();
              bytes += generator.reset();
              if (bytes.isNotEmpty) {
                PosPrintResult printing = await printer.printTicket(bytes);
                if (printing.msg == "Success") {
                  queueID.addAll(kitchens.map((kitchen) => kitchen.queueID.toString()).toList());
                  detailID.addAll(kitchens.map((kitchen) => kitchen.mInvoiceDetailID.toString()).toList());
                }
              }
            }
          }
        }

        printer.disconnect();
      } else {
        if (cacheBackupCheckCount != 0) {
          printKitchenErrorCount++;
        }
        debugPrint("打印機$ip連接失敗");
      }
    }
  }
  return {"queueID": queueID.toSet().toList(), "detailID": detailID.toSet().toList()};
}

///开始打印其它厨房单
///d.mIsPrint P正常 PF 追单 PM 改单 PD  删单 PT  转台单 (pd改为D,其它改为Y)
Future<List<Map<String, dynamic>>> printOtherkichen(List<Kitchen> printData, int isPrintPrice) async {
  List<Map<String, dynamic>> resultList = [];
  if (printKitchenErrorCount >= cacheBackupCheckCount) {
    printKitchenErrorCount = 0;
  }
  for (var kitchens in printData) {
    PrinterNetworkManager? printer;
    if (cacheBackupCheckCount != 0 &&
        printKitchenErrorCount >= cacheBackupCheckCount &&
        kitchens.kitchenBackupPrinterIP != null) {
      printer = PrinterNetworkManager(kitchens.kitchenBackupPrinterIP!);
    } else {
      printer = PrinterNetworkManager(kitchens.mLanIP!);
    }

    PosPrintResult connect = await printer.connect();

    if (connect == PosPrintResult.success) {
      List<int> bytes = [];
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);

      String content = "";
      switch (kitchens.mIsPrint) {
        case "PF":
          content = printerLocale(LocaleKeys.chaseOrder); //追單

        case "PM":
          content = printerLocale(LocaleKeys.changeOrder); //改單

        case "PD":
          content = printerLocale(LocaleKeys.deleteOrder); //刪單
        case "PT":
          content = printerLocale(LocaleKeys.turntableOrder); //轉檯單
        default:
          content = "";
      }
      bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
      bytes += generator.text(
        content,
        styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
        containsChinese: true,
      );

      //台号
      bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
      bytes += generator.text(
        "${printerLocale(LocaleKeys.table)}:${kitchens.mTableNo}",
        styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
        containsChinese: true,
      );
      bytes += generator.rawBytes(EscHelper.setAlign(align: 0).codeUnits);
      //单号
      bytes += generator.row([
        PosColumn(
          text: "${kitchens.mStationCode}",
          width: 4,
          containsChinese: true,
          styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
        ),
        PosColumn(
          text: "${printerLocale(LocaleKeys.orderNo)}：",
          width: 4,
          containsChinese: true,
          styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
        ),
        PosColumn(
          text: kitchens.mInvoiceNo!.substring(kitchens.mInvoiceNo!.length - 4),
          width: 4,
          containsChinese: true,
          styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
        ),
      ]);

      //日期人数
      bytes += generator.row([
        PosColumn(
          text: "${kitchens.invoiceDate}",
          width: 4,
          containsChinese: true,
          styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
        ),
        PosColumn(
          text: "${kitchens.invoiceTime}",
          width: 4,
          containsChinese: true,
          styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
        ),
        PosColumn(
          text: "${printerLocale(LocaleKeys.peopleNumber)}：",
          width: 3,
          containsChinese: true,
          styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
        ),
        PosColumn(
          text: "${kitchens.mPnum}",
          width: 1,
          containsChinese: true,
          styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, align: PosAlign.left),
        ),
      ]);

      bytes += generator.feed(1);

      //名称
      var printName = EscHelper.splitString(str: kitchens.mBarcodeName ?? "", splitLength: 20);

      if (printName.isNotEmpty) {
        for (int j = 0; j < printName.length; j++) {
          if (j == 0) {
            bytes += generator.text(
              EscHelper.columnMaker(content: '${kitchens.mQty}', width: 4) +
                  EscHelper.columnMaker(content: printName[j], width: 20),
              styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
              containsChinese: true,
            );
          } else if (printName[j].isNotEmpty) {
            bytes += generator.text(
              EscHelper.columnMaker(content: '', width: 4) + EscHelper.columnMaker(content: printName[j], width: 20),
              styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
              containsChinese: true,
            );
          }
        }
      }
      //备注
      if (kitchens.mRemarks?.isNotEmpty ?? false) {
        var printRemarks = EscHelper.splitString(str: kitchens.mRemarks ?? "", splitLength: 20);
        if (printRemarks.isNotEmpty) {
          for (int k = 0; k < printRemarks.length; k++) {
            bytes += generator.text(
              '${EscHelper.columnMaker(content: '', width: 4)}${EscHelper.columnMaker(content: printRemarks[k], width: 20)}',
              styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
              containsChinese: true,
            );
          }
        }
      }

      //价格
      if (isPrintPrice == 0) {
        bytes += generator.text(
          EscHelper.columnMaker(content: "\$${kitchens.mPrice}", width: 24, align: 2),
          styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
        );
      }

      bytes += generator.feed(1);

      //台号
      bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
      bytes += generator.text(
        "${printerLocale(LocaleKeys.table)}:${kitchens.mTableNo}",
        styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
        containsChinese: true,
      );

      bytes += generator.feed(1);

      bytes += generator.cut();
      bytes += generator.reset();
      PosPrintResult printing = await printer.printTicket(bytes);
      if (printing.msg == "Success") {
        String mIsPrint = kitchens.mIsPrint!;
        int queueID = kitchens.queueID!;
        int detailID = kitchens.mInvoiceDetailID!;
        resultList.add({
          "mIsPrint": mIsPrint,
          "queueID": [queueID],
          "detailID": [detailID],
        });
      }
      printer.disconnect();
    } else {
      if (cacheBackupCheckCount != 0) {
        printKitchenErrorCount++;
      }
    }
  }

  return resultList;
}

///执行打印上菜单
Future<List<String>> printOnTheMeun({required UpperMenu printdata}) async {
  Set<String> queueID = {};
  try {
    List<UpperMenuData> upperMenuData = printdata.upperMenuData!;
    Map<String?, List<UpperMenuData>> upperGroup = groupBy(upperMenuData, (UpperMenuData rows) => rows.invoiceNo);
    if (upperGroup.isNotEmpty) {
      final printer = PrinterNetworkManager(printdata.ip!);
      PosPrintResult connect = await printer.connect();

      if (connect == PosPrintResult.success) {
        for (var item in upperGroup.entries) {
          List<int> bytes = [];
          final profile = await CapabilityProfile.load();
          final generator = Generator(PaperSize.mm80, profile);

          List<UpperMenuData> upperGroupValue = item.value;
          //上菜单
          bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
          bytes += generator.text(
            printerLocale(LocaleKeys.onTheMenu),
            styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
            containsChinese: true,
          );
          bytes += generator.feed(1);
          //台号
          bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
          bytes += generator.text(
            "${printerLocale(LocaleKeys.table)}:${upperGroupValue.first.mTableNo}",
            styles: const PosStyles(width: PosTextSize.size3, height: PosTextSize.size3, bold: true),
            containsChinese: true,
          );

          bytes += generator.feed(1);
          bytes += generator.rawBytes(EscHelper.setAlign(align: 0).codeUnits);
          //员工行
          bytes += generator.text(
            "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.employee), width: 8)}${EscHelper.columnMaker(content: ":${upperGroupValue.first.mSalesmanCode}", width: 16)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.orderNo), width: 8)}${EscHelper.columnMaker(content: ":${EscHelper.setSize(size: 3)}${upperGroupValue.first.mInvoiceNo}", width: 8)}",
            containsChinese: true,
          );

          //日期行
          bytes += generator.text(
            "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.date), width: 8)}${EscHelper.columnMaker(content: ":${upperGroupValue.first.invoiceDate}", width: 16)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.station), width: 8)}${EscHelper.columnMaker(content: ":${upperGroupValue.first.mStationCode}", width: 16)}",
            containsChinese: true,
          );

          //时间行
          bytes += generator.text(
            "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.seatingTime), width: 8)}${EscHelper.columnMaker(content: ":${upperGroupValue.first.invoiceTime}", width: 16)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.peopleNumber), width: 8)}${EscHelper.columnMaker(content: ":${upperGroupValue.first.mPnum}", width: 16)}",
            containsChinese: true,
          );

          //结账时间
          bytes += generator.text(
            "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.paymentTime), width: 8)}${EscHelper.columnMaker(content: ":", width: 16)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.table), width: 8)}${EscHelper.columnMaker(content: ":${upperGroupValue.first.mTableNo}", width: 16)}",
            containsChinese: true,
          );
          bytes += generator.rawBytes(EscHelper.setSize().codeUnits);

          bytes += generator.hr();
          for (var upper in upperGroupValue) {
            //名稱
            final printName = EscHelper.splitString(str: upper.mBarcodeName ?? "", splitLength: 30);
            if (printName.isNotEmpty) {
              for (int i = 0; i < printName.length; i++) {
                bytes += generator.text(
                  "${EscHelper.columnMaker(content: i == 0 ? "${upper.invoiceTime}" : "", width: 8)}${EscHelper.columnMaker(content: printName[i].isNotEmpty ? printName[i] : "", width: 30)}${EscHelper.columnMaker(content: i == 0 ? upper.mQty ?? "" : "", width: 4)}${EscHelper.columnMaker(content: i == 0 ? upper.mPrice ?? "0.0" : "", width: 6, align: 2)}",
                  containsChinese: true,
                  styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
                );
              }
            }
            //備註
            final printRemaks = EscHelper.splitString(str: upper.mRemarks ?? "", splitLength: 29);
            for (int k = 0; k < printRemaks.length; k++) {
              bytes += generator.text(
                "${EscHelper.columnMaker(content: "", width: 10)}${EscHelper.columnMaker(content: printRemaks[k], width: 38)}",
                containsChinese: true,
                styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2),
              );
            }
            if (upper.queueID != null) {
              queueID.add(upper.queueID.toString());
            }
          }

          bytes += generator.hr();
          if (upperGroupValue.first.queueID != null) {
            bytes += generator.text(
              EscHelper.columnMaker(content: upperGroupValue.first.mAmount ?? "0.0", width: 48, align: 2),
              styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
              containsChinese: true,
            );
          } else {
            if (upperGroupValue.first.hasFirstPrint != null && upperGroupValue.first.hasFirstPrint == "Y") {
              bytes += generator.text(
                EscHelper.columnMaker(content: upperGroupValue.first.mAmount ?? "0.0", width: 48, align: 2),
                styles: const PosStyles(width: PosTextSize.size1, height: PosTextSize.size2, bold: true),
                containsChinese: true,
              );
            }
          }

          bytes += generator.feed(2);

          bytes += generator.barcode(Barcode.code39("${upperGroupValue.first.mInvoiceNo}".split("")), height: 60);

          bytes += generator.feed(1);
          bytes += generator.cut();
          bytes += generator.reset();
          await printer.printTicket(bytes);
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
Future<List<String>> printCustomerRecord({required List<Receipt> printdata}) async {
  Set<String> queueID = {};

  try {
    final printer = PrinterNetworkManager(printdata.first.mLanIP!);
    PosPrintResult connect = await printer.connect();

    if (connect == PosPrintResult.success) {
      for (var item in printdata) {
        List<int> bytes = [];
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm80, profile);

        //中文名称
        if (item.mNameChinese != null && item.mNameChinese!.isNotEmpty) {
          bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
          bytes += generator.text(
            "${item.mNameChinese}",
            styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
            containsChinese: true,
          );
          bytes += generator.feed(1);
        }
        //英文名称
        if (item.mNameEnglish != null && item.mNameEnglish!.isNotEmpty) {
          bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
          bytes += generator.text(
            "${item.mNameEnglish}",
            styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
            containsChinese: true,
          );
          bytes += generator.feed(1);
        }
        //地址
        if (item.mAddress != null && item.mAddress!.isNotEmpty) {
          List<String> addressList = EscHelper.splitString(str: item.mAddress ?? "", splitLength: 24);
          for (var address in addressList) {
            bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
            bytes += generator.text(
              address,
              styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),
              containsChinese: true,
            );
            bytes += generator.feed(1);
          }
        }
        bytes += generator.rawBytes(EscHelper.setAlign(align: 0).codeUnits);
        bytes += generator.feed(1);
        bytes += generator.hr();
        bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
        bytes += generator.text(
          printerLocale(LocaleKeys.customerRecords),
          styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        bytes += generator.rawBytes(EscHelper.setAlign().codeUnits);
        //台/单号
        bytes += generator.text(
          "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: "${printerLocale(LocaleKeys.table)}/${printerLocale(LocaleKeys.orderNo)}", width: 16)}${EscHelper.columnMaker(content: "${item.mTableNo}", width: 16)}${EscHelper.columnMaker(content: EscHelper.setSize(size: 3) + item.mInvoiceNo!.substring(item.mInvoiceNo!.length - 4), width: 8)}",
          containsChinese: true,
        );
        bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        //人数行
        bytes += generator.text(
          "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.peopleNumber), width: 8)}${EscHelper.columnMaker(content: ":${item.mPnum}", width: 20)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.customer), width: 8)}${EscHelper.columnMaker(content: ":${item.mCustomerCode}", width: 12)}",
          containsChinese: true,
        );
        //入坐时间行
        bytes += generator.text(
          "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.seatingTime), width: 8)}${EscHelper.columnMaker(content: ":${item.mInvoiceDate}", width: 20)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.station), width: 8)}${EscHelper.columnMaker(content: ":${item.mStationCode}", width: 12)}",
          containsChinese: true,
        );
        //结账时间行
        bytes += generator.text(
          "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.paymentTime), width: 8)}${EscHelper.columnMaker(content: ":${item.payTime}", width: 20)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.employee), width: 8)}${EscHelper.columnMaker(content: ":${item.mSalesmanCode}", width: 12)}",
          containsChinese: true,
        );
        bytes += generator.feed(1);
        //明细表头
        bytes += generator.text(
          "${EscHelper.columnMaker(content: printerLocale(LocaleKeys.item), width: 34)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.quantity), width: 6)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.amount), width: 8, align: 2)}",
          containsChinese: true,
        );

        //分割線
        bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
        bytes += generator.hr();
        //明细内容
        final List<Detail>? detail = item.detail;
        if (detail != null && detail.isNotEmpty) {
          bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
          for (int i = 0; i < detail.length; i++) {
            var printName = EscHelper.splitString(str: detail[i].mPrintName ?? "", splitLength: 34);
            for (int j = 0; j < printName.length; j++) {
              if (j == 0) {
                bytes += generator.text(
                  "${EscHelper.columnMaker(content: printName[j], width: 34)}${EscHelper.columnMaker(content: j == 0 ? "${detail[i].mQty}" : "", width: 6)}${EscHelper.columnMaker(content: j == 0 ? "${detail[i].mAmount}" : "", width: 8, align: 2)}",
                  containsChinese: true,
                );
              }
            }
          }
        }
        //分割線
        bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
        bytes += generator.hr();
        bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        //小计
        bytes += generator.text(
          "${EscHelper.columnMaker(content: printerLocale(LocaleKeys.subtotal), width: 24)}${EscHelper.columnMaker(content: "${item.mNetAmt}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //服务费
        bytes += generator.text(
          "${EscHelper.columnMaker(content: printerLocale(LocaleKeys.serviceFee), width: 24)}${EscHelper.columnMaker(content: "${item.mCharge}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //折扣
        bytes += generator.text(
          "${EscHelper.columnMaker(content: printerLocale(LocaleKeys.discount), width: 24)}${EscHelper.columnMaker(content: "${item.mDiscRate}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //折扣(\$)
        bytes += generator.text(
          "${EscHelper.columnMaker(content: "${printerLocale(LocaleKeys.discount)}(\$)", width: 24)}${EscHelper.columnMaker(content: "${item.mDiscAmt}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //合計
        bytes += generator.text(
          "${EscHelper.columnMaker(content: printerLocale(LocaleKeys.total), width: 24)}${EscHelper.columnMaker(content: "${item.mAmount}", width: 24, align: 2)}",
          containsChinese: true,
        );

        //分割線
        bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
        bytes += generator.hr();
        bytes += generator.rawBytes(EscHelper.setAlign().codeUnits);
        bytes += generator.text(
          printerLocale(LocaleKeys.signature),
          containsChinese: true,
          styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: false),
        );

        bytes += generator.feed(2);

        bytes += generator.barcode(
          Barcode.code39(item.mInvoiceNo!.substring(item.mInvoiceNo!.length - 4).split("")),
          height: 60,
        );

        bytes += generator.feed(1);
        bytes += generator.cut();
        bytes += generator.reset();
        PosPrintResult printing = await printer.printTicket(bytes);
        if (printing.msg == "Success") {
          queueID.add("${item.queueID}");
        }
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
Future<List<String>> printRecipt({required List<Receipt> printdata}) async {
  Set<String> queueID = {};

  try {
    final printer = PrinterNetworkManager(printdata.first.mLanIP!);
    PosPrintResult connect = await printer.connect();

    if (connect == PosPrintResult.success) {
      for (var item in printdata) {
        List<int> bytes = [];
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm80, profile);

        //中文名称
        if (item.mNameChinese != null && item.mNameChinese!.isNotEmpty) {
          bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
          bytes += generator.text(
            "${item.mNameChinese}",
            styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
            containsChinese: true,
          );
          bytes += generator.feed(1);
        }
        //英文名称
        if (item.mNameEnglish != null && item.mNameEnglish!.isNotEmpty) {
          bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
          bytes += generator.text(
            "${item.mNameEnglish}",
            styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
            containsChinese: true,
          );
          bytes += generator.feed(1);
        }
        //地址
        if (item.mAddress != null && item.mAddress!.isNotEmpty) {
          bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
          List<String> addressList = EscHelper.splitString(str: item.mAddress!, splitLength: 24);
          for (var address in addressList) {
            bytes += generator.text(
              address,
              styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size2),
              containsChinese: true,
            );
            bytes += generator.feed(1);
          }
        }

        bytes += generator.feed(1);
        bytes += generator.hr();
        bytes += generator.text(
          printerLocale(LocaleKeys.recepipt),
          styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        bytes += generator.rawBytes(EscHelper.setAlign().codeUnits);
        //台/单号
        bytes += generator.text(
          "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: "${printerLocale(LocaleKeys.table)}/${printerLocale(LocaleKeys.orderNo)}", width: 16)}${EscHelper.columnMaker(content: "${item.mTableNo}", width: 16)}${EscHelper.columnMaker(content: EscHelper.setSize(size: 3) + item.mInvoiceNo!.substring(item.mInvoiceNo!.length - 4), width: 8)}",
          containsChinese: true,
        );
        bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        //人数行
        bytes += generator.text(
          "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.peopleNumber), width: 8)}${EscHelper.columnMaker(content: ":${item.mPnum}", width: 20)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.customer), width: 8)}${EscHelper.columnMaker(content: ":${item.mCustomerCode}", width: 12)}",
          containsChinese: true,
        );
        //入坐时间行
        bytes += generator.text(
          "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.seatingTime), width: 8)}${EscHelper.columnMaker(content: ":${item.mInvoiceDate}", width: 20)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.station), width: 8)}${EscHelper.columnMaker(content: ":${item.mStationCode}", width: 12)}",
          containsChinese: true,
        );
        //结账时间行
        bytes += generator.text(
          "${EscHelper.setSize(size: 1)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.paymentTime), width: 8)}${EscHelper.columnMaker(content: ":${item.payTime}", width: 20)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.employee), width: 8)}${EscHelper.columnMaker(content: ":${item.mSalesmanCode}", width: 12)}",
          containsChinese: true,
        );
        bytes += generator.feed(1);
        //明细表头
        bytes += generator.text(
          "${EscHelper.columnMaker(content: printerLocale(LocaleKeys.item), width: 34)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.quantity), width: 6)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.amount), width: 8, align: 2)}",
          containsChinese: true,
        );

        //分割線
        bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
        bytes += generator.hr();
        //明细内容
        final List<Detail>? detail = item.detail;
        if (detail != null && detail.isNotEmpty) {
          bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
          for (int i = 0; i < detail.length; i++) {
            var printName = EscHelper.splitString(str: detail[i].mPrintName ?? "", splitLength: 34);
            for (int j = 0; j < printName.length; j++) {
              if (j == 0) {
                bytes += generator.text(
                  "${EscHelper.columnMaker(content: printName[j], width: 34)}${EscHelper.columnMaker(content: j == 0 ? "${detail[i].mQty}" : "", width: 6)}${EscHelper.columnMaker(content: j == 0 ? "${detail[i].mAmount}" : "", width: 8, align: 2)}",
                  containsChinese: true,
                );
              }
            }
          }
        }
        //分割線
        bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
        bytes += generator.hr();
        bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        //小计
        bytes += generator.text(
          "${EscHelper.columnMaker(content: printerLocale(LocaleKeys.subtotal), width: 24)}${EscHelper.columnMaker(content: "${item.mNetAmt}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //服务费
        bytes += generator.text(
          "${EscHelper.columnMaker(content: printerLocale(LocaleKeys.serviceFee), width: 24)}${EscHelper.columnMaker(content: "${item.mCharge}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //折扣
        bytes += generator.text(
          "${EscHelper.columnMaker(content: printerLocale(LocaleKeys.discount), width: 24)}${EscHelper.columnMaker(content: "${item.mDiscRate}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //折扣(\$)
        bytes += generator.text(
          "${EscHelper.columnMaker(content: "${printerLocale(LocaleKeys.discount)}(\$)", width: 24)}${EscHelper.columnMaker(content: "${item.mDiscAmt}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //合計
        bytes += generator.text(
          "${EscHelper.columnMaker(content: printerLocale(LocaleKeys.total), width: 24)}${EscHelper.columnMaker(content: "${item.mAmount}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //付款金额
        bytes += generator.text(
          "${EscHelper.columnMaker(content: printerLocale(LocaleKeys.paymentAmount), width: 24)}${EscHelper.columnMaker(content: "${item.mPayAmount}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //找零
        bytes += generator.text(
          "${EscHelper.columnMaker(content: printerLocale(LocaleKeys.change), width: 24)}${EscHelper.columnMaker(content: "${item.mChange}", width: 24, align: 2)}",
          containsChinese: true,
        );
        //分割線
        bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
        bytes += generator.hr();

        //支付方式
        bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        bytes += generator.text(
          "${EscHelper.columnMaker(content: printerLocale(LocaleKeys.paymentMethod), width: 30)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.amount), width: 10)}${EscHelper.columnMaker(content: printerLocale(LocaleKeys.tips), width: 8, align: 2)}",
          containsChinese: true,
        );
        //分割線
        bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
        bytes += generator.hr();
        final List<PayType>? payType = item.payType;
        if (payType != null && payType.isNotEmpty) {
          for (int i = 0; i < payType.length; i++) {
            bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
            bytes += generator.text(
              "${EscHelper.columnMaker(content: "${payType[i].mPaytype}", width: 30)}${EscHelper.columnMaker(content: "${payType[i].mAmount}", width: 10)}${EscHelper.columnMaker(content: "${payType[i].mTips}", width: 8, align: 2)}",
              containsChinese: true,
            );
          }
        }
        //分割線
        bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
        bytes += generator.hr();

        bytes += generator.feed(2);

        bytes += generator.barcode(
          Barcode.code39(item.mInvoiceNo!.substring(item.mInvoiceNo!.length - 4).split("")),
          height: 60,
        );

        bytes += generator.feed(1);
        bytes += generator.cut();
        bytes += generator.reset();
        PosPrintResult printing = await printer.printTicket(bytes);
        if (printing.msg == "Success") {
          queueID.add("${item.queueID}");
        }
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
Future<bool> openDrawer({required OpenDrawer printData}) async {
  try {
    final printer = PrinterNetworkManager(printData.iP!);
    PosPrintResult connect = await printer.connect();

    if (connect == PosPrintResult.success) {
      final List<int> queueID = printData.queueID!;
      debugPrint("打印机${printData.iP}连接成功");

      if (queueID.isNotEmpty) {
        List<int> bytes = [];
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm80, profile);

        bytes += generator.rawBytes(EscHelper.openCashDrawer().codeUnits);
        bytes += generator.reset();
        await printer.printTicket(bytes);
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
Future<List<String>> printTakeaway({required List<Takeaway> printdata}) async {
  Set<String> queueID = {};

  try {
    final printer = PrinterNetworkManager(printdata.first.mLanIp!);
    PosPrintResult connect = await printer.connect();

    if (connect == PosPrintResult.success) {
      for (var item in printdata) {
        logger.i("打印开始:${item.toJson()}");
        List<int> bytes = [];
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm80, profile);
        bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
        //手机外卖
        bytes += generator.text(
          printerLocale(LocaleKeys.takeawayOrder),
          styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        bytes += generator.feed(1);

        //单号

        bytes += generator.text(
          "#${item.mInvoiceNo!.substring(item.mInvoiceNo!.length - 4, item.mInvoiceNo!.length)}",
          styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        bytes += generator.feed(1);

        //mCustTel(0自取1送餐) mCustFax(0儘快1預約時間)
        String method = "";
        String address = "";

        if (item.mCustTel.toString() == "0") {
          method += "${printerLocale(LocaleKeys.selfPickUp)}:"; //自取
          if (item.mCustFax.toString() == "0") {
            method += printerLocale(LocaleKeys.asap); //儘快
          } else {
            method += DateFormat('HH:mm').format(DateTime.parse(item.mCustDelTime.toString()));
          }
        } else if (item.mCustTel.toString() == "1") {
          method += "${printerLocale(LocaleKeys.foodDlivery)}:"; //送餐

          if (item.mCustFax.toString() == "0") {
            method += printerLocale(LocaleKeys.asap); //儘快
          } else {
            var mCustDelTime = item.mCustDelTime;
            method += DateFormat('HH:mm').format(DateTime.parse(mCustDelTime.toString()));
          }

          if (item.mCustAttn != null || item.mCustAttn!.isNotEmpty) {
            address = item.mCustAttn!;
          }
        }

        if (method != "" && method.isNotEmpty) {
          bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
          bytes += generator.text(
            method,
            styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
            containsChinese: true,
          );
        }

        //地址
        if (address != "" && address.isNotEmpty) {
          bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
          bytes += generator.feed(1);
          List<String> addressList = EscHelper.splitString(str: address, splitLength: 48);
          logger.i("打印地址:$addressList");
          for (var addressItem in addressList) {
            bytes += generator.text(
              addressItem,
              styles: const PosStyles(height: PosTextSize.size2, width: PosTextSize.size1),
              containsChinese: true,
            );
          }
          bytes += generator.feed(1);
        }
        bytes += generator.rawBytes(EscHelper.setAlign(align: 1).codeUnits);
        //时间
        bytes += generator.text(
          DateFormat('yyyy-MM-dd HH:mm:ss').format(item.mInvoiceDate ?? DateTime.now()),
          styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
          containsChinese: true,
        );
        //电话
        if (item.mCustomerCode?.isNotEmpty ?? false) {
          bytes += generator.text(
            item.mCustomerCode!.replaceFirst("+852", "+852 "),
            styles: const PosStyles(width: PosTextSize.size2, height: PosTextSize.size2, bold: true),
            containsChinese: true,
          );
        }

        bytes += generator.feed(1);

        bytes += generator.hr();
        bytes += generator.rawBytes(EscHelper.setAlign().codeUnits + EscHelper.setSize(size: 1).codeUnits);
        final List<Map<String, InvoiceDetail>>? details = item.invoiceDetails;
        if (details != null && details.isNotEmpty) {
          for (var detail in details) {
            for (var li in detail.entries) {
              //父商品名称
              final List mPrintNameList = EscHelper.splitString(str: li.value.mBarcodeName ?? "", splitLength: 32);
              if (mPrintNameList.isNotEmpty) {
                for (var i = 0; i < mPrintNameList.length; i++) {
                  bytes += generator.text(
                    "${EscHelper.columnMaker(content: i == 0 ? "${li.value.mTime}" : "", width: 6)}${EscHelper.columnMaker(content: "${mPrintNameList[i]}", width: 32)}${EscHelper.columnMaker(content: "${li.value.mQty}", width: 4)}${EscHelper.columnMaker(content: i == 0 ? "${li.value.mPrice}" : "", width: 6, align: 2)}",
                    containsChinese: true,
                  );
                }
              }
              //套餐
              List<InvoiceDetail>? child = li.value.children;
              if (child != null && child.isNotEmpty) {
                for (var childItem in child) {
                  final List mPrintNameList = EscHelper.splitString(str: childItem.mBarcodeName ?? "", splitLength: 32);
                  if (mPrintNameList.isNotEmpty) {
                    for (var i = 0; i < mPrintNameList.length; i++) {
                      //套餐商品名称
                      bytes += generator.text(
                        "${EscHelper.columnMaker(content: i == 0 ? "${childItem.mTime}" : "", width: 6)}${EscHelper.columnMaker(content: "${mPrintNameList[i]}", width: 32)}${EscHelper.columnMaker(content: "${childItem.mQty}", width: 4)}${EscHelper.columnMaker(content: i == 0 ? "${childItem.mPrice}" : "", width: 6, align: 2)}",
                        containsChinese: true,
                      );
                      //套餐商品备注
                      final mRemarks = childItem.mRemarks;
                      if (mRemarks != null && mRemarks.isNotEmpty) {
                        final List mPrintRemarksList = EscHelper.splitString(str: childItem.mRemarks!, splitLength: 36);
                        for (var remarksItem in mPrintRemarksList) {
                          bytes += generator.text(
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
        bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
        bytes += generator.hr();
        bytes += generator.rawBytes(EscHelper.setSize(size: 1).codeUnits);
        bytes += generator.text(EscHelper.columnMaker(content: "${item.mAmount}", width: 48, align: 2));
        bytes += generator.rawBytes(EscHelper.setSize().codeUnits);
        bytes += generator.barcode(
          Barcode.code39(item.mInvoiceNo!.substring(item.mInvoiceNo!.length - 4).split("")),
          height: 60,
        );
        bytes += generator.feed(1);
        bytes += generator.cut();
        bytes += generator.reset();
        PosPrintResult printing = await printer.printTicket(bytes);
        if (printing.msg == "Success") {
          queueID.add("${item.queueId}");
        }
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
