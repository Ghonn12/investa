import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/auth_service.dart';
import '../../../../routes/app_pages.dart';

class LoginController extends GetxController {
  final AuthService _authService = Get.find();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;

  void login() async {
    // ... validasi input ...

    isLoading.value = true;
    try {
      final success = await _authService.login(
          emailController.text,
          passwordController.text
      );

      if (success) {
        Get.offAllNamed(Routes.DASHBOARD);
      }
    } catch (e) {
      // Tangkap pesan error spesifik
      String message = "Terjadi kesalahan koneksi";

      // Jika errornya dari Auth Service (yang melempar string pesan error)
      if (e.toString().contains("dibekukan") || e.toString().contains("BLOCKED")) {
        message = "Akun Anda telah dibekukan. Hubungi Admin.";
      } else if (e.toString().contains("Invalid")) {
        message = "Email atau Password salah";
      }

      Get.snackbar(
        "Login Gagal",
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.block, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }
}