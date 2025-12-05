import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import '../../core/values/api_constants.dart'; // Sesuaikan path ini jika merah

class AuthService extends GetxService {
  final ApiService _api = Get.find();
  final _storage = const FlutterSecureStorage();

  final isLoggedIn = false.obs;
  final userName = ''.obs;
  final userEmail = ''.obs;

  // --- TAMBAHAN PENTING (Agar bisa dibaca FinanceService) ---
  String? _token; 
  String? get token => _token; 
  // ----------------------------------------------------------

  Future<AuthService> init() async {
    // Cek token saat aplikasi dimulai
    _token = await _storage.read(key: 'auth_token'); // Simpan ke variabel memory
    
    if (_token != null) {
      isLoggedIn.value = true;
      await fetchProfile();
    }
    return this;
  }

  Future<void> fetchProfile() async {
    try {
      final response = await _api.get(ApiConstants.profile); 
      // Note: Pastikan ApiConstants.profile mengarah ke endpoint yang benar (misal '/auth/me' atau '/users/profile')
      // Jika belum ada endpoint profile, skip bagian ini dulu gapapa.
      
      if (response.statusCode == 200) {
        // Sesuaikan parsing JSON dengan struktur API kamu
        // Jika API return { data: { user: {...} } } atau { user: {...} }
        final data = response.data;
        final user = data['data'] ?? data['user'] ?? data; 
        
        userName.value = user['name'] ?? 'User Investa';
        userEmail.value = user['email'] ?? '';
      }
    } catch (e) {
      userName.value = 'User Investa';
      userEmail.value = '';
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      // Pastikan path ApiConstants.login benar
      final response = await _api.post('/auth/login', data: { 
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        // Sesuaikan dengan struktur JSON dari AuthController CI4 kamu
        // Controller kamu return: { status: true, message: '...', token: '...', user: {...} }
        // Jadi TIDAK ADA key ['data']. Langsung ambil dari root response.
        
        final data = response.data; 
        
        // Cek struktur response (kadang ada di dalam 'data', kadang langsung)
        final token = data['token'] ?? data['data']?['token'];
        final user = data['user'] ?? data['data']?['user'];

        if (token != null) {
          // Simpan ke Storage & Memory
          await _storage.write(key: 'auth_token', value: token);
          _token = token; // Update variabel memory

          if (user != null) {
            userName.value = user['name'] ?? 'User';
            userEmail.value = user['email'] ?? '';
          }
          
          isLoggedIn.value = true;
          return true;
        }
      }
      return false;
    } catch (e) {
      // print("Login Error: $e"); // Debugging
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _token = null; // Hapus dari memory
    userName.value = '';
    userEmail.value = '';
    isLoggedIn.value = false;
    Get.offAllNamed('/login'); 
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await _api.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }
}