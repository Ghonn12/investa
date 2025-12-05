import 'package:dio/dio.dart';
// FIX: Hide 'Response' and 'MultipartFile' from Get to avoid conflict with Dio
import 'package:get/get.dart' hide Response, MultipartFile;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/values/api_constants.dart';

class ApiService extends GetxService {
  late Dio _dio;
  final _storage = const FlutterSecureStorage();

  Future<ApiService> init() async {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        // Increase timeout to 30 seconds
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json,
      ),
    );

    // Add Interceptors
    _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          // FIX: Ambil token dengan key 'auth_token'
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // FIX: Logic Logout jika 401
          if (e.response?.statusCode == 401) {
            // Hanya tampilkan snackbar jika bukan sedang di halaman Login
            if (Get.currentRoute != '/login') {
              Get.snackbar("Sesi Berakhir", "Silakan login kembali.");
            }
            // Biarkan intereceptor di Auth Service yang handle redirect
          }
          return handler.next(e);
        }
    ));
    return this;
  }

  // Wrapper Methods
  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    return await _dio.get(path, queryParameters: params);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}