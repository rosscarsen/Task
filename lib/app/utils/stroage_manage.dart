import 'package:get_storage/get_storage.dart';

class StorageManage {
  // 定义一个_box变量，类型为GetStorage()，用于存储获取的存储实例
  final _box = GetStorage();

  // 定义一个_instance变量，类型为StorageManage，用于存储全局的StorageManage实例
  static final StorageManage _instance = StorageManage._internal();

  // 获取StorageManage实例，返回_instance
  static StorageManage get instance => _instance;

  // 创建StorageManage实例，返回_instance
  factory StorageManage() => _instance;

  // 私有构造函数，用于创建StorageManage实例
  StorageManage._internal();

  Future<void> save(String key, dynamic value) async {
    /// 存储数据
    await _box.write(key, value);
  }

  dynamic read(String key) {
    /// 读取指定键的数据
    return _box.read(key);
  }

  Future<void> delete(String key) async {
    /// 删除指定键的数据
    await _box.remove(key);
  }

  Future<void> clearAll() async {
    /// 清空存储的所有数据
    await _box.erase();
  }

  bool hasData(String key) {
    return _box.hasData(key);
  }
}
