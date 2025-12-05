import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import '../core/values/api_constants.dart';

class AuthService extends GetxService {
  final ApiService _api = Get.find();
  final _storage = const FlutterSecureStorage();

  final isLoggedIn = false.obs;
  final userName = ''.obs;
  final userEmail = ''.obs;

  Future<AuthService> init() async {
    // Cek token saat aplikasi dimulai
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      isLoggedIn.value = true;
      // Ambil profile user dari API supaya nama/email tidak kosong
      await fetchProfile();
    }
    return this;
  }

  Future<void> fetchProfile() async {
    try {
      final response = await _api.get(ApiConstants.profile);
      if (response.statusCode == 200) {
        final user = response.data['data'];
        userName.value = user['name'] ?? 'User Investa';
        userEmail.value = user['email'] ?? '';
      }
    } catch (e) {
      // kalau gagal, tetap fallback
      userName.value = 'User Investa';
      userEmail.value = '';
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _api.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final token = data['token'];

        await _storage.write(key: 'auth_token', value: token);
        userName.value = data['user']['name'] ?? 'User Investa';
        userEmail.value = data['user']['email'] ?? '';
        isLoggedIn.value = true;

        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    userName.value = '';
    userEmail.value = '';
    isLoggedIn.value = false;
    Get.offAllNamed('/login'); // gunakan constant route
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await _api.post(ApiConstants.register, data: {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201) {
        // langsung isi data user agar tidak kosong
        userName.value = name;
        userEmail.value = email;
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }
}
