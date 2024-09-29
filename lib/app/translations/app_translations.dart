import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_HK': {
          "foodSaleReport": "餐飲銷售報表",
          "timeSolt": "時段",
          "printTime": "列印時間",
          "code": "編號",
          "printSuccess": "列印成功",
          "print_does_not_exits": "列印機不存在",
          "reload": "重新加載",
          "close": "關閉",
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
          "foodSaleReport": "食品销售报表",
          "timeSolt": "时段",
          "printTime": "打印时间",
          "code": "编号",
          "printSuccess": "列印成功",
          "print_does_not_exits": "打印机不存在",
          "reload": "重新加载",
          "close": "关闭",
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
          "foodSaleReport": "Food Sale Report",
          "timeSolt": "Time Slot",
          "printTime": "Print Time",
          'code': "Code",
          "printSuccess": "Print success",
          "print_does_not_exits": "Printer does not exist",
          "reload": "Reload",
          "close": "Close",
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
  static const String foodSaleReport = 'foodSaleReport';
  static const String timeSolt = 'timeSolt';
  static const String printTime = "printTime";
  static const String code = 'code';
  static const String printSuccess = 'printSuccess';
  static const String printDoesNotExits = "print_does_not_exits";
  static const String reload = "reload";
  static const String close = "close";
  static const String logoutFailed = "logoutFailed";
  static const String currentStationCannotSetUpAirprintService = "currentStationCannotSetUpAirprintService";
  static const String airprintService = "airprintService";
  static const String loadException = 'loadException';
  static const String airprintSetting = 'airprintSetting';
  static const String startAirprint = "startAirprint";
  static const String stopAirprint = "stopAirprint";
  static const String confirmLoginOut = "confirmLoginOut";
  static const String websiteNotExist = "websiteNotExist";
  static const String company = "company";
  static const String user = "user";
  static const String password = "password";
  static const String rememberMe = "rememberMe";
  static const String login = "login";
  static const String loggingIn = "loggingIn";
  static const String loginFailed = "loginFailed";
  static const String loginSuccess = "loginSuccess";
  static const String requestFailed = "requestFailed";
  static const String startArirprintService = "startArirprintService";
  static const String logout = "logout";
  static const String airprintServiceIsRunning = "airprintServiceIsRunning";
  static const String airprintServiceIsStopped = "airprintServiceIsStopped";
  static const String connectTest = "connectTest";
  static const String testConnect = "testConnect";
  static const String connectSuccess = "connectSuccess";
  static const String connectFailed = "connectFailed";
  static const String employee = "employee";
  static const String station = "station";
  static const String date = "date";
  static const String peopleNumber = "peopleNumber";
  static const String scanQrCode = "scanQrCode";
  static const String tableNo = "tableNo";
  static const String table = "table";
  static const String orderNo = "orderNo";
  static const String customer = "customer";
  static const String customerRecords = "customerRecords";
  static const String seatingTime = "seatingTime";
  static const String paymentTime = "paymentTime";
  static const String item = "item";
  static const String quantity = "quantity";
  static const String amount = "amount";
  static const String subtotal = "subtotal";
  static const String serviceFee = "serviceFee";
  static const String discount = "discount";
  static const String total = "total";
  static const String paymentAmount = "paymentAmount";
  static const String paymentMethod = "paymentMethod";
  static const String change = "change";
  static const String tips = "tips";
  static const String recepipt = "recepipt";
  static const String takeawayOrder = "takeawayOrder";
  static const String thisFieldIsRequired = "thisFieldIsRequired";
  static const String onTheMenu = "onTheMenu";
  static const String chaseOrder = "chaseOrder";
  static const String changeOrder = "changeOrder";
  static const String deleteOrder = "deleteOrder";
  static const String turntableOrder = "turntableOrder";
  static const String customerSign = "customerSign";
  static const String mobileTakeaway = "mobileTakeaway";
  static const String selfPickUp = "selfPickUp";
  static const String asap = "ASAP";
  static const String foodDlivery = "foodDlivery";
  static const String companyError = "companyError";
  static const String stationDoesNotExist = "stationDoesNotExist";
  static const String useOrPasswordError = "useOrPasswordError";
  static const String stationSiggedIn = "stationSiggedIn";
  static const String systemMessages = "systemMessages";
  static const String confirm = "confirm";
  static const String cancel = "cancel";
}
