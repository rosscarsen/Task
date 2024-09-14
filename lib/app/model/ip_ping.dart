// ignore_for_file: public_member_api_docs, sort_constructors_first
// To parse this JSON data, do
//
//     final ipPing = ipPingFromJson(jsonString);

import 'dart:convert';

IpPing ipPingFromJson(String str) => IpPing.fromJson(json.decode(str));

String ipPingToJson(IpPing data) => json.encode(data.toJson());

class IpPing {
  int state;
  List<IpData> data;

  IpPing({
    required this.state,
    required this.data,
  });

  factory IpPing.fromJson(Map<String, dynamic> json) => IpPing(
        state: json["state"],
        data: List<IpData>.from(json["data"].map((x) => IpData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "state": state,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class IpData {
  String mName;
  String mLanIp;
  String mPrinterType;

  IpData({
    required this.mName,
    required this.mLanIp,
    required this.mPrinterType,
  });

  factory IpData.fromJson(Map<String, dynamic> json) => IpData(
        mName: json["mName"],
        mLanIp: json["mLanIP"],
        mPrinterType: json["mPrinterType"],
      );

  Map<String, dynamic> toJson() => {
        "mName": mName,
        "mLanIP": mLanIp,
        "mPrinterType": mPrinterType,
      };

  @override
  String toString() =>
      'IpData(mName: $mName, mLanIp: $mLanIp, mPrinterType: $mPrinterType)';
}
