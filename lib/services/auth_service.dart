import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import '../core/values/api_constants.dart';

class AuthService extends GetxService {
  final ApiService _api = Get.find();
  final _storage = const FlutterSecureStorage();

  // Reactive variable untuk status login
  final isLoggedIn = false.obs;
  final userName = ''.obs;

  Future<AuthService> init() async {
    // Cek token saat aplikasi dimulai
    String? token = await _storage.read(key: 'auth_token');
    if (token != null) {
      isLoggedIn.value = true;
      // Opsional: Ambil data user profile di sini jika perlu
    }
    return this;
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _api.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        // ... simpan token ...
        return true;
      }
      return false;

    } on DioException catch (e) {
      // Cek jika status 403 (Blocked)
      if (e.response?.statusCode == 403) {
        // Ambil pesan dari backend: "Akun Anda telah dibekukan..."
        final msg = e.response?.data['message'] ?? "Akun diblokir";
        throw Exception(msg);
      }
      // Cek error 401 (Salah password)
      if (e.response?.statusCode == 401) {
        throw Exception("Invalid email or password");
      }

      rethrow;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await _api.post(ApiConstants.register, data: {
        'name': name,
        'email': email,
        'password': password,
      });

      return response.statusCode == 201;
    } catch (e) {
      rethrow; // <--- WAJIB ADA INI agar controller tau ada error
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    isLoggedIn.value = false;
    userName.value = '';
    Get.offAllNamed('/login');
  }
}