import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_HK': {
          "logoutFailed": "登出失敗",
          "currentStationCannotSetUpAirprintService": "當前收銀機(%s)無法設置列印服務",
          "airprintService": "列印服務",
          "loadException": "加載異常",
          "airprintSetting": "列印設置",
          "startAirprint": "開始列印",
          "stopAirprint": "停止列印",
          "confirmLoginOut": "確定要登出嗎？",
          "company": "公司",
          "user": "用戶",
          "password": "密碼",
          "rememberMe": "記住我",
          "login": "登入",
          "loggingIn": "登入中...",
          "loginFailed": "登入失敗",
          "loginSuccess": "登入成功",
          "requestFailed": "請求失敗",
          "startArirprintService": "開始列印服務",
          "stopAirprintService": "停止列印服務",
          "logout": "登出",
          "airprintServiceIsRunning": "列印服務正在運行",
          "airprintServiceIsStopped": "列印服務已停止",
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
          "companyError": "公司錯誤",
          "stationDoesNotExist": "收銀機不存在",
          "useOrPasswordError": "用戶或密碼錯誤",
          "stationSiggedIn": "收銀機%s已在%s登入",
          "systemMessages": "系統消息",
          "confirm": "確認",
          "cancel": "取消",
          'websiteNotExist': "未設置手機網站",
        },
        'zh_CN': {
          "logoutFailed": "登出失败",
          "currentStationCannotSetUpAirprintService": "当前收银机(%s)无法设置打印服务",
          "airprintService": "打印服务",
          "loadException": "加载异常",
          "airprintSetting": "列印设置",
          "startAirprint": "开始列印",
          "stopAirprint": "停止列印",
          "confirmLoginOut": "确认登出吗?",
          "company": "公司",
          "user": "用户",
          "password": "密码",
          "rememberMe": "记住我",
          "login": "登录",
          "loggingIn": "登录中...",
          "loginFailed": "登录失败",
          "loginSuccess": "登录成功",
          "requestFailed": "请求失败",
          "startArirprintService": "开始打印服务",
          "stopAirprintService": "停止打印服务",
          "logout": "登出",
          "airprintServiceIsRunning": "打印服务正在运行",
          "airprintServiceIsStopped": "打印服务已停止",
          "connectTest": "连接测试",
          "testConnect": "测试连接",
          "connectSuccess": "连接成功",
          "connectFailed": "连接失败",
          "employee": "员工",
          "station": "收银机",
          "date": "日期",
          "peopleNumber": "人數",
          "scanQrCode": "请扫描上面二维码自助点餐",
          "tableNo": "桌号",
          "table": "桌",
          "orderNo": "单号",
          "customer": "客户",
          "customerRecords": "客户记录",
          "seatingTime": "入座时间",
          "paymentTime": "结账时间",
          "item": "项目",
          "quantity": "数量",
          "amount": "金额",
          "subtotal": "小计",
          "serviceFee": "服务费",
          "discount": "折扣",
          "total": "总计",
          "paymentAmount": "支付金额",
          "paymentMethod": "支付方式",
          "change": "找零",
          "tips": "小费",
          "recepipt": "收據",
          "takeawayOrder": "外卖订单",
          "thisFieldIsRequired": "这个字段必填",
          "onTheMenu": "上菜单",
          "chaseOrder": "追单",
          "changeOrder": "改单",
          "deleteOrder": "刪单",
          "turntableOrder": "转台单",
          "customerSign": "客戶签名",
          "mobileTakeaway": "手机外卖",
          "selfPickUp": "自取",
          "ASAP": "尽快",
          "foodDlivery": "送餐",
          "companyError": "公司错误",
          "stationDoesNotExist": "收银机不存在",
          "useOrPasswordError": "用户或密码错误",
          "stationSiggedIn": "收银机%s已在%s登入",
          "systemMessages": "系统消息",
          "confirm": "确认",
          "cancel": "取消",
          'websiteNotExist': "未设置手机网站",
        },
        'en_US': {
          "logoutFailed": "Logout failed",
          "currentStationCannotSetUpAirprintService": "Current station (%s) cannot set up airprint service",
          "airprintService": "Airprint service",
          "loadException": "Load exception",
          "airprintSetting": "Airprint setting",
          "startAirprint": "Start airprint",
          "stopAirprint": "Stop airprint",
          "confirmLoginOut": "Are you sure you want to log out?",
          "companyError": "Company error",
          "stationDoesNotExist": "Station does not exist",
          "useOrPasswordError": "User or password error",
          "company": "Company",
          "user": "User",
          "password": "Password",
          "rememberMe": "Remember me",
          "login": "Login",
          "loggingIn": "Logging in...",
          "loginFailed": "Login failed",
          "loginSuccess": "Login success",
          "requestFailed": "request failed",
          "startAirprintService": "Start airprint service",
          "stopAirprintService": "Stop airprint service",
          "logout": "Logout",
          "airprintServiceIsRunning": "Airprint service is running",
          "airprintServiceIsStopped": "Airprint service is stopped",
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
          "stationSiggedIn": "The station %s register has been logged in at %s",
          "systemMessages": "System messages",
          "confirm": "Confirm",
          "cancel": "Cancel",
          'websiteNotExist': "No mobile network station is set up",
        },
      };
}

abstract class LocaleKeys {
  LocaleKeys._();
  static String logoutFailed = "logoutFailed";
  static String currentStationCannotSetUpAirprintService = "currentStationCannotSetUpAirprintService";
  static String airprintService = "airprintService";
  static String loadException = 'loadException';
  static String airprintSetting = 'airprintSetting';
  static String startAirprint = "startAirprint";
  static String stopAirprint = "stopAirprint";
  static String confirmLoginOut = "confirmLoginOut";
  static String websiteNotExist = "websiteNotExist";
  static String company = "company";
  static String user = "user";
  static String password = "password";
  static String rememberMe = "rememberMe";
  static String login = "login";
  static String loggingIn = "loggingIn";
  static String loginFailed = "loginFailed";
  static String loginSuccess = "loginSuccess";
  static String requestFailed = "requestFailed";
  static String startArirprintService = "startArirprintService";
  static String logout = "logout";
  static String airprintServiceIsRunning = "airprintServiceIsRunning";
  static String airprintServiceIsStopped = "airprintServiceIsStopped";
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
  static String companyError = "companyError";
  static String stationDoesNotExist = "stationDoesNotExist";
  static String useOrPasswordError = "useOrPasswordError";
  static String stationSiggedIn = "stationSiggedIn";
  static String systemMessages = "systemMessages";
  static String confirm = "confirm";
  static String cancel = "cancel";
}
