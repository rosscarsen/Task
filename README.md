# Dart 定时打印热敏票据

## 使用前准备（一个收银机只能在一个设备上登录）

### [window destop 使用说明](# windwos 使用说明)

### [关于 Get](#关于get)

[APK 下载](http://www.pericles.net/ftp1/APK/Task1008.apk)

1. 后台类目二打印机必须设置 IP 地址，并且 IP 地址与电脑在同一网段。
2. 系统维护->系统设置->发票打印机、上菜单打印机、外卖单打印机设置为 IP 打印机，云打印设置为"N"。
3. 除了外卖发票与外卖厨房单使用后台数据库，pos2.0 所有单据均使用前台数据库(即后台数据库改动后，要使用后台系统维护内的"更新前台数据功能"来同步到前台数据库)。

## 启动打印服务

1. 打开 pos2.0 大厅的设置按钮。
2. 选择"列印设置"
3. 点击"开始列印"按钮（启动右上角图标可查看与测试已经设置的 IP 打印机连接状况）
   - 启动条件：当前登录收银机必须和系统设置内的 airprint 一致
   - 终止打印：点击“停止打印”按钮或者退出 pos2.0 大厅

## 队列表 mOperateType 数值与获取打印数据条件说明

- 1：弹柜（使用系统设置内的发票打印机）

  - 数据获取条件：
    - 队列表 mOperateType = 1
  - 打印完成后：
    - 删除队列表 mOperateType = 1 的数据

- 2：打印发票（使用系统设置内的发票打印机）

  - 数据获取条件：
    - 队列表 mOperateType = 2
    - 发票表 mPrintInvoice = 1
    - 发票明细表 mIsPrint 不等于 D (P:正常 PF:追单 PM:改单 PD:删单 PT:转台单)
  - 打印完成后：
    - 发票表 mPrintInvoice 从 1 修改为 0
    - 删除队列表 mOperateType = 2 的数据

- 3：打印二维码（使用系统设置内的上菜单打印机）

  - 数据获取条件：
    - 队列表 mOperateType = 3
    - 发票表 mPrintInvoice = 2 mBTemp=1
  - 打印完成后：
    - 发票表 mPrintInvoice 从 2 修改为 0
    - 删除队列表 mOperateType = 3 的数据

- 4：打印客户记录（使用系统设置内的发票打印机）

  - 数据获取条件：
    - 队列表 mOperateType = 4
    - 发票表 mPrintInvoice = 3
    - 发票明细表 mIsPrint 不等于 D (P:正常 PF:追单 PM:改单 PD:删单 PT:转台单)
  - 打印完成后：
    - 发票表 mPrintInvoice 从 3 修改为 0
    - 删除队列表 mOperateType = 4 的数据

- 5：打印厨房单（使用食品所属类目二对应的打印机）
  - 数据获取条件：
    - 队列表 mOperateType = 5
    - 发票明细表 mIsPrint 不等于 D (P:正常 PF:追单 PM:改单 PD:删单 PT:转台单)
  - 打印完成后：
    - 发票明细表 mIsPrint PD 修改为 D 其它几种修改为 Y
    - 删除队列表 mOperateType = 5 的数据
- 6：打印上菜单（使用系统设置内的上菜单打印机）
  - 数据获取条件：
    - 队列表 mOperateType = 6
    - 发票表 mPrintBDL = 1
    - 发票明细表 mIsPrint 不等于 D (P:正常 PF:追单 PM:改单 PD:删单 PT:转台单)
  - 打印完成后：
    - 发票表 mPrintBDL 从 1 修改为 0
    - 删除队列表 mOperateType = 6 的数据
- 7：打印外卖单(使用后台数据库,类目 1'Kiosk 形式'为'是'时才在外卖上显示)
  - 数据获取条件：
    - 队列表 mOperateType = 7
    - 后台外卖发票表 TA_print = Y
  - 打印完成后：
    - 后台外卖发票表 TA_print = N
    - 删除队列表 mOperateType = 7 的数据
  - 打印外卖厨房需要到 pos2.0 手机外卖处进行转单
- 8：EFTPay 支付（待定）
- 9：void 退单（待定）

## 网页内系统设置

- 打印机：（食品銷售報表 、日結報表）使用后台系统设置内的发发票 IP 打印机，重印发票跟队列（和结账时收据一样使用发票 IP 打印机）
- 对于版本小于 1.0.5，先升级到 1.0.5，升级后如果之前登录过且未登出，一定要重新登出再登录，（登录时会再去拿一些信息储存在 app 内）

## 开发使用的包

- [x] characters
- [x] collection
- [x] device_info_plus
- [x] dio
- [x] flutter_esc_pos_utils
- [x] flutter_esc_pos_network
- [x] flutter_background_service
- [x] flutter_background_service_android
- [x] flutter_easyloading
- [x] flutter_inappwebview
- [x] get
- [x] get_storage
- [x] image
- [x] intl
- [x] logger
- [x] path_provider
- [x] qr_flutter
- [x] tray_manager
- [x] win32
- [x] flutter_staggered_animations

### 安装后 msix 程序后查看位置 Get-AppxPackage -AllUsers | Where-Object { $\_.Name -like "_com.example.myapp_" } | Select-Object PackageFamilyName, InstallLocation

# windwos 使用说明

# 关于 Get

    1. Get.put() 保存数据，Get.find() 获取数据
