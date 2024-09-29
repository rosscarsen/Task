// ignore_for_file: public_member_api_docs, sort_constructors_first
// To parse this JSON data, do
//
//     final SaleModel = SaleModelFromMap(jsonString);

import 'dart:convert';

SaleModel saleModelFromMap(String str) => SaleModel.fromMap(json.decode(str));

String saleModelToMap(SaleModel data) => json.encode(data.toMap());

class SaleModel {
  String? reportCompany;
  String? timerFrame;
  String? printTime;
  String? station;
  List<SaleReportList>? saleReportList;

  SaleModel({
    this.reportCompany,
    this.timerFrame,
    this.printTime,
    this.station,
    this.saleReportList,
  });

  factory SaleModel.fromMap(Map<String, dynamic> json) => SaleModel(
        reportCompany: json["reportCompany"],
        timerFrame: json["timerFrame"],
        printTime: json["printTime"],
        station: json["station"],
        saleReportList: json["saleReportList"] == null
            ? []
            : List<SaleReportList>.from(json["saleReportList"]!.map((x) => SaleReportList.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "reportCompany": reportCompany,
        "timerFrame": timerFrame,
        "printTime": printTime,
        "station": station,
        "saleReportList": saleReportList == null ? [] : List<dynamic>.from(saleReportList!.map((x) => x.toMap())),
      };

  @override
  String toString() {
    return 'SaleModel(reportCompany: $reportCompany, timerFrame: $timerFrame, printTime: $printTime, station: $station, saleReportList: $saleReportList)';
  }
}

class SaleReportList {
  String? mCode;
  String? mDesc1;
  String? mModel;
  String? mColor;
  String? mSize;
  String? mQty;
  String? mAmount;

  SaleReportList({
    this.mCode,
    this.mDesc1,
    this.mModel,
    this.mColor,
    this.mSize,
    this.mQty,
    this.mAmount,
  });

  factory SaleReportList.fromMap(Map<String, dynamic> json) => SaleReportList(
        mCode: json["mCode"],
        mDesc1: json["mDesc1"],
        mModel: json["mModel"],
        mColor: json["mColor"],
        mSize: json["mSize"],
        mQty: json["mQty"],
        mAmount: json["mAmount"],
      );

  Map<String, dynamic> toMap() => {
        "mCode": mCode,
        "mDesc1": mDesc1,
        "mModel": mModel,
        "mColor": mColor,
        "mSize": mSize,
        "mQty": mQty,
        "mAmount": mAmount,
      };

  @override
  String toString() {
    return 'SaleReportList(mCode: $mCode, mDesc1: $mDesc1, mModel: $mModel, mColor: $mColor, mSize: $mSize, mQty: $mQty, mAmount: $mAmount)';
  }
}
