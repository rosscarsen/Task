import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_HK': {
          "company": "公司",
          "user": "用戶",
          "password": "密碼",
          "rememberMe": "記住我",
          "login": "登入",
          "loggingIn": "登入中...",
          "loginFailed": "登入失敗",
          "loginSuccess": "登入成功",
          "requestFailed": "請求失敗",
          "start": "開始",
          "stop": "停止",
          "logout": "登出",
          "serviceIsRunning": "服務正在運行",
          "serviceIsStopped": "服務已停止",
          "connectTest": "連接測試",
          "testConnect": "測試連接",
          "connectSuccess": "連接成功",
          "connectFailed": "連接失敗",
          "employee": "員工",
          "station": "收銀機",
          "date": "日期",
          "peopleNumber": "人數",
          "scanQrCode": "請掃描上面二維碼自助點餐",
          "tableNo": "檯號",
          "table": "檯",
          "orderNo": "單號",
          "customer": "客戶",
          "customerRecords": "顧客記錄",
          "seatingTime": "入座時間",
          "paymentTime": "結賬時間",
          "item": "項目",
          "quantity": "數量",
          "amount": "金額",
          "subtotal": "小計",
          "serviceFee": "服務費",
          "discount": "折扣",
          "total": "總計",
          "paymentAmount": "支付金額",
          "paymentMethod": "支付方式",
          "change": "找零",
          "tips": "小費",
          "recepipt": "收據",
          "takeawayOrder": "外賣訂單",
          "thisFieldIsRequired": "這個字段必填",
          "onTheMenu": "上菜單",
          "chaseOrder": "追單",
          "changeOrder": "改單",
          "deleteOrder": "刪單",
          "turntableOrder": "轉檯單",
          "customerSign": "客戶簽名",
          "mobileTakeaway": "手機外賣",
          "selfPickUp": "自取",
          "ASAP": "盡快",
          "foodDlivery": "送餐",
        },
        'en_US': {
          "company": "Company",
          "user": "User",
          "password": "Password",
          "rememberMe": "Remember me",
          "login": "Login",
          "loggingIn": "Logging in...",
          "loginFailed": "Login failed",
          "loginSuccess": "Login success",
          "requestFailed": "request failed",
          "start": "Start",
          "stop": "Stop",
          "logout": "Logout",
          "serviceIsRunning": "Service is running",
          "serviceIsStopped": "Service is stopped",
          "connectTest": "Connect test",
          "testConnect": "Test connect",
          "connectSuccess": "Connect success",
          "connectFailed": "Connect failed",
          "employee": "Employee",
          "station": "Station",
          "date": "Date",
          "peopleNumber": "People number",
          "scanQrCode": "Scan QR code",
          "tableNo": "Table number",
          "table": "Table",
          "orderNo": "Order number",
          "customer": "Customer",
          "customerRecords": "Customer records",
          "seatingTime": "Seating time",
          "paymentTime": "Payment time",
          "item": "Item",
          "quantity": "Quantity",
          "amount": "Amount",
          "subtotal": "Subtotal",
          "serviceFee": "Service fee",
          "discount": "Discount",
          "total": "Total",
          "paymentAmount": "Payment amount",
          "paymentMethod": "Payment method",
          "change": "Change",
          "tips": "Tips",
          "recepipt": "Receipt",
          "takeawayOrder": "Takeaway order",
          "thisFieldIsRequired": "This field is required",
          "onTheMenu": "On the menu",
          "chaseOrder": "Chase order",
          "changeOrder": "Change order",
          "deleteOrder": "Delete order",
          "turntableOrder": "Turntable order",
          "customerSign": "Customer sign",
          "mobileTakeaway": "Mobile takeaway",
          "selfPickUp": "Self pick up",
          "ASAP": "ASAP",
          "foodDlivery": "Food delivery",
        },
      };
}

abstract class LocaleKeys {
  LocaleKeys._();
  static String company = "company";
  static String user = "user";
  static String password = "password";
  static String rememberMe = "rememberMe";
  static String login = "login";
  static String loggingIn = "loggingIn";
  static String loginFailed = "loginFailed";
  static String loginSuccess = "loginSuccess";
  static String requestFailed = "requestFailed";
  static String start = "start";
  static String stop = "stop";
  static String logout = "logout";
  static String serviceIsRunning = "serviceIsRunning";
  static String serviceIsStopped = "serviceIsStopped";
  static String connectTest = "connectTest";
  static String testConnect = "testConnect";
  static String connectSuccess = "connectSuccess";
  static String connectFailed = "connectFailed";
  static String employee = "employee";
  static String station = "station";
  static String date = "date";
  static String peopleNumber = "peopleNumber";
  static String scanQrCode = "scanQrCode";
  static String tableNo = "tableNo";
  static String table = "table";
  static String orderNo = "orderNo";
  static String customer = "customer";
  static String customerRecords = "customerRecords";
  static String seatingTime = "seatingTime";
  static String paymentTime = "paymentTime";
  static String item = "item";
  static String quantity = "quantity";
  static String amount = "amount";
  static String subtotal = "subtotal";
  static String serviceFee = "serviceFee";
  static String discount = "discount";
  static String total = "total";
  static String paymentAmount = "paymentAmount";
  static String paymentMethod = "paymentMethod";
  static String change = "change";
  static String tips = "tips";
  static String recepipt = "recepipt";
  static String takeawayOrder = "takeawayOrder";
  static String thisFieldIsRequired = "thisFieldIsRequired";
  static String onTheMenu = "onTheMenu";
  static String chaseOrder = "chaseOrder";
  static String changeOrder = "changeOrder";
  static String deleteOrder = "deleteOrder";
  static String turntableOrder = "turntableOrder";
  static String customerSign = "customerSign";
  static String mobileTakeaway = "mobileTakeaway";
  static String selfPickUp = "selfPickUp";
  static String asap = "ASAP";
  static String foodDlivery = "foodDlivery";
}
