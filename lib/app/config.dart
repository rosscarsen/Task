class Config {
  ///网络请求地址
  static String baseurl = "https://flutterpos.friendsclub.com/Task";

  //登录
  static String login = "/login";

  //获取数据
  static String getData = "/getTaskData";

  //获取所有IP
  static String getAllLocalIP = "/getAllLocalIP";

  //打印完成后把发票发送给后台
  static String sendInvoices = "/deleteInvoice";
  //退出登录
  static String logout = "/logout";

  ///本地存储key

  //本地登录信息
  static String localStorageLoginInfo = "localStorageLoginInfo";

  //登录标识
  static String localStorageHasLogin = "localStorageHasLogin";
  //本地语言
  static String localStorageLanguage = "localStorageLanguage";
  //本地启动任务
  static String localStorageStartTask = "localStorageStartTask";
}
