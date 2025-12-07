import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:shared_preferences/shared_preferences.dart'; // Untuk simpan token di web
import '../core/values/api_constants.dart';

class ApiService extends GetxService {
  late Dio _dio;

  Future<ApiService> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      responseType: ResponseType.json,
    ));

    // Interceptor untuk Token
    _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('admin_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (e, handler) {
          if (e.response?.statusCode == 401) {
            Get.offAllNamed('/login'); // Auto logout jika token expired
          }
          return handler.next(e);
        }
    ));
    return this;
  }

  // Wrapper Methods
  Future<Response> get(String path) async => await _dio.get(path);
  Future<Response> post(String path, {dynamic data}) async => await _dio.post(path, data: data);
  Future<Response> put(String path, {dynamic data}) async => await _dio.put(path, data: data);
  Future<Response> delete(String path) async => await _dio.delete(path);
}