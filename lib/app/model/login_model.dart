// To parse this JSON data, do
//
//     final loginModel = loginModelFromJson(jsonString);

import 'dart:convert';

LoginModel loginModelFromJson(String str) => LoginModel.fromJson(json.decode(str));

String loginModelToJson(LoginModel data) => json.encode(data.toJson());

class LoginModel {
  UserData? data;
  String? info;
  int? status;

  LoginModel({
    this.data,
    this.info,
    this.status,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) => LoginModel(
        data: json["data"] == null ? null : UserData.fromJson(json["data"]),
        info: json["info"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "data": data?.toJson(),
        "info": info,
        "status": status,
      };
}

class UserData {
  String? company;
  String? pwd;
  String? userCode;
  Dsn? frontDsn;
  Dsn? adminDsn;

  UserData({
    this.company,
    this.pwd,
    this.userCode,
    this.frontDsn,
    this.adminDsn,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
        company: json["company"],
        pwd: json["pwd"],
        userCode: json["userCode"],
        frontDsn: json["frontDsn"] == null ? null : Dsn.fromJson(json["frontDsn"]),
        adminDsn: json["adminDsn"] == null ? null : Dsn.fromJson(json["adminDsn"]),
      );

  Map<String, dynamic> toJson() => {
        "company": company,
        "pwd": pwd,
        "userCode": userCode,
        "frontDsn": frontDsn?.toJson(),
        "adminDsn": adminDsn?.toJson(),
      };
}

class Dsn {
  String? type;
  String? hostname;
  String? database;
  String? username;
  String? password;
  int? hostport;
  String? charset;
  String? prefix;

  Dsn({
    this.type,
    this.hostname,
    this.database,
    this.username,
    this.password,
    this.hostport,
    this.charset,
    this.prefix,
  });

  factory Dsn.fromJson(Map<String, dynamic> json) => Dsn(
        type: json["type"],
        hostname: json["hostname"],
        database: json["database"],
        username: json["username"],
        password: json["password"],
        hostport: json["hostport"],
        charset: json["charset"],
        prefix: json["prefix"],
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "hostname": hostname,
        "database": database,
        "username": username,
        "password": password,
        "hostport": hostport,
        "charset": charset,
        "prefix": prefix,
      };
}
