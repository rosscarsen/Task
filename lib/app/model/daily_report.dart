// ignore_for_file: public_member_api_docs, sort_constructors_first
// To parse this JSON data, do
//
//     final DailyReportModel = DailyReportModelFromMap(jsonString);

import 'dart:convert';

DailyReportModel dailyReportModelFromMap(String str) => DailyReportModel.fromMap(json.decode(str));

String dailyReportModelToMap(DailyReportModel data) => json.encode(data.toMap());

class DailyReportModel {
  String? dailyReport;
  String? shop;
  String? staff;
  String? date;
  String? salesAmount;
  List<String>? salesAmountTotal;
  List<String>? service;
  List<String>? dis;
  List<String>? tips;
  List<String>? balance;
  List<String>? netAmt;
  List<String>? payTitle;
  List<List<String>>? payList;
  List<String>? payTotalList;
  String? cashAccounting;
  List<String>? cashSales;
  List<dynamic>? cashAccountingDetailPay;
  List<String>? cashOnHand;
  String? auditTrail;
  List<String>? voidModify;
  List<String>? refund;
  List<String>? waive;
  List<String>? averageBill;
  List<String>? averageGuest;

  DailyReportModel({
    this.dailyReport,
    this.shop,
    this.staff,
    this.date,
    this.salesAmount,
    this.salesAmountTotal,
    this.service,
    this.dis,
    this.tips,
    this.balance,
    this.netAmt,
    this.payTitle,
    this.payList,
    this.payTotalList,
    this.cashAccounting,
    this.cashSales,
    this.cashAccountingDetailPay,
    this.cashOnHand,
    this.auditTrail,
    this.voidModify,
    this.refund,
    this.waive,
    this.averageBill,
    this.averageGuest,
  });

  factory DailyReportModel.fromMap(Map<String, dynamic> json) => DailyReportModel(
        dailyReport: json["dailyReport"],
        shop: json["shop"],
        staff: json["staff"],
        date: json["date"],
        salesAmount: json["salesAmount"],
        salesAmountTotal:
            json["salesAmountTotal"] == null ? [] : List<String>.from(json["salesAmountTotal"]!.map((x) => x)),
        service: json["service"] == null ? [] : List<String>.from(json["service"]!.map((x) => x)),
        dis: json["DIS"] == null ? [] : List<String>.from(json["DIS"]!.map((x) => x)),
        tips: json["Tips"] == null ? [] : List<String>.from(json["Tips"]!.map((x) => x)),
        balance: json["BALANCE"] == null ? [] : List<String>.from(json["BALANCE"]!.map((x) => x)),
        netAmt: json["NET_AMT"] == null ? [] : List<String>.from(json["NET_AMT"]!.map((x) => x)),
        payTitle: json["payTitle"] == null ? [] : List<String>.from(json["payTitle"]!.map((x) => x)),
        payList: json["payList"] == null
            ? []
            : List<List<String>>.from(json["payList"]!.map((x) => List<String>.from(x.map((x) => x)))),
        payTotalList: json["payTotalList"] == null ? [] : List<String>.from(json["payTotalList"]!.map((x) => x)),
        cashAccounting: json["Cash_accounting"],
        cashSales: json["Cash_sales"] == null ? [] : List<String>.from(json["Cash_sales"]!.map((x) => x)),
        cashAccountingDetailPay: json["Cash_accounting_detail_pay"] == null
            ? []
            : List<dynamic>.from(json["Cash_accounting_detail_pay"]!.map((x) => x)),
        cashOnHand: json["Cash_On_Hand"] == null ? [] : List<String>.from(json["Cash_On_Hand"]!.map((x) => x)),
        auditTrail: json["Audit_Trail"],
        voidModify: json["Void_Modify"] == null ? [] : List<String>.from(json["Void_Modify"]!.map((x) => x)),
        refund: json["Refund"] == null ? [] : List<String>.from(json["Refund"]!.map((x) => x)),
        waive: json["Waive"] == null ? [] : List<String>.from(json["Waive"]!.map((x) => x)),
        averageBill: json["Average_Bill"] == null ? [] : List<String>.from(json["Average_Bill"]!.map((x) => x)),
        averageGuest: json["Average_Guest"] == null ? [] : List<String>.from(json["Average_Guest"]!.map((x) => x)),
      );

  Map<String, dynamic> toMap() => {
        "dailyReport": dailyReport,
        "shop": shop,
        "staff": staff,
        "date": date,
        "salesAmount": salesAmount,
        "salesAmountTotal": salesAmountTotal == null ? [] : List<dynamic>.from(salesAmountTotal!.map((x) => x)),
        "service": service == null ? [] : List<dynamic>.from(service!.map((x) => x)),
        "DIS": dis == null ? [] : List<dynamic>.from(dis!.map((x) => x)),
        "Tips": tips == null ? [] : List<dynamic>.from(tips!.map((x) => x)),
        "BALANCE": balance == null ? [] : List<dynamic>.from(balance!.map((x) => x)),
        "NET_AMT": netAmt == null ? [] : List<dynamic>.from(netAmt!.map((x) => x)),
        "payTitle": payTitle == null ? [] : List<dynamic>.from(payTitle!.map((x) => x)),
        "payList": payList == null ? [] : List<dynamic>.from(payList!.map((x) => List<dynamic>.from(x.map((x) => x)))),
        "payTotalList": payTotalList == null ? [] : List<dynamic>.from(payTotalList!.map((x) => x)),
        "Cash_accounting": cashAccounting,
        "Cash_sales": cashSales == null ? [] : List<dynamic>.from(cashSales!.map((x) => x)),
        "Cash_accounting_detail_pay":
            cashAccountingDetailPay == null ? [] : List<dynamic>.from(cashAccountingDetailPay!.map((x) => x)),
        "Cash_On_Hand": cashOnHand == null ? [] : List<dynamic>.from(cashOnHand!.map((x) => x)),
        "Audit_Trail": auditTrail,
        "Void_Modify": voidModify == null ? [] : List<dynamic>.from(voidModify!.map((x) => x)),
        "Refund": refund == null ? [] : List<dynamic>.from(refund!.map((x) => x)),
        "Waive": waive == null ? [] : List<dynamic>.from(waive!.map((x) => x)),
        "Average_Bill": averageBill == null ? [] : List<dynamic>.from(averageBill!.map((x) => x)),
        "Average_Guest": averageGuest == null ? [] : List<dynamic>.from(averageGuest!.map((x) => x)),
      };

  @override
  String toString() {
    return 'DailyReportModel(dailyReport: $dailyReport, shop: $shop,staff:$staff, date: $date, salesAmount: $salesAmount, salesAmountTotal: $salesAmountTotal, service: $service, dis: $dis, tips: $tips, balance: $balance, netAmt: $netAmt, payTitle: $payTitle, payList: $payList, payTotalList: $payTotalList, cashAccounting: $cashAccounting, cashSales: $cashSales, cashAccountingDetailPay: $cashAccountingDetailPay, cashOnHand: $cashOnHand, auditTrail: $auditTrail, voidModify: $voidModify, refund: $refund, waive: $waive, averageBill: $averageBill, averageGuest: $averageGuest)';
  }
}
