import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find();

  final emailC = TextEditingController();
  final passC = TextEditingController();

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Untuk testing development agar tidak ngetik terus
    // emailC.text = "admin@investa.com";
    // passC.text = "admin123";
  }

  void login() async {
    if (emailC.text.isEmpty || passC.text.isEmpty) {
      Get.snackbar(
          "Gagal Masuk",
          "Email dan Password wajib diisi",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          maxWidth: 400,
          margin: const EdgeInsets.only(top: 20)
      );
      return;
    }

    isLoading.value = true;
    try {
      // Panggil service login
      bool success = await _authService.login(emailC.text, passC.text);

      if (success) {
        Get.snackbar(
            "Selamat Datang",
            "Login berhasil sebagai Admin",
            backgroundColor: Colors.green,
            colorText: Colors.white,
            maxWidth: 400,
            margin: const EdgeInsets.only(top: 20)
        );
        Get.offAllNamed('/home'); // Pindah ke Dashboard & Hapus history login
      } else {
        Get.snackbar(
            "Login Gagal",
            "Email atau password salah, atau Anda bukan Admin.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
            maxWidth: 400,
            margin: const EdgeInsets.only(top: 20)
        );
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan koneksi: $e", maxWidth: 400);
    } finally {
      isLoading.value = false;
    }
  }
}