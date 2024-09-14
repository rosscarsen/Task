import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../config.dart';

class ApiClient {
  static Logger logger = Logger();

  static final ApiClient _instance = ApiClient._internal();

  static ApiClient get internal => _instance;
  static late Dio _dio;

  factory ApiClient() {
    final BaseOptions baseOptions = BaseOptions(
      baseUrl: Config.baseurl,
      contentType: "application/x-www-form-urlencoded",
      responseType: ResponseType.json,
      validateStatus: (status) {
        return status != null;
      },
    );

    _dio = Dio(baseOptions);

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) {
        logger.d('API Error: ${e.message}');
        return handler.next(e);
      },
    ));

    return _instance;
  }

  ApiClient._internal();

  /// 发送POST请求
  ///
  /// [path]：API的相对路径
  /// [data]：请求参数
  Future<Response> post(String path,
      {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      Response response =
          await _dio.post(path, data: data, queryParameters: queryParameters);
      return response;
    } catch (e) {
      throw Exception(e);
    }
  }

  /// 发送GET请?
  ///
  /// [path]：API的相对路径
  /// [params]：查询参数
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      Response response =
          await _dio.get(path, queryParameters: queryParameters);
      return response;
    } catch (e) {
      throw Exception(e);
    }
  }

  /// 上传文件
  ///
  /// [path]：API的相对路径
  /// [file]：待上传的文件
  Future<dynamic> upload(String path, String filePath) async {
    try {
      final file = await MultipartFile.fromFile(filePath);
      final formData = FormData.fromMap({"file": file});
      final response = await _dio.post(path, data: formData);
      return response.data;
    } catch (e) {
      throw Exception(e);
    }
  }

  /// 下载文件
  ///
  /// [path]：要下载的文件路径
  /// [savePath]：保存文件的路径
  Future<bool> download(String path, String savePath) async {
    try {
      await _dio.download(path, savePath);
      return true;
    } catch (e) {
      // 异常处理
      throw Exception(e);
    }
  }
}
