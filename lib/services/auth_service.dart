import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../core/values/api_constants.dart';

class AuthService extends GetxService {
  final ApiService _api = Get.find();
  Future<AuthService> init() async {
    // Di sini Anda bisa menambahkan logika pengecekan token awal di SharedPreferences
    // Misalnya,
    // final prefs = await SharedPreferences.getInstance();
    // if (prefs.getString('admin_token') != null) { ... }
    return this;
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _api.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final token = data['token'];

        // Simpan token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_token', token);

        // Cek Role
        final user = data['user'];
        if (user != null && user['role'] == 'ADMIN') {
          return true;
        } else {
          // Jika bukan admin, hapus token lagi
          await prefs.remove('admin_token');
          return false;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
    Get.offAllNamed('/login');
  }
}
