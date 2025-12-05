import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/auth_service.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find();

  // Data User Reactive
  final userName = ''.obs;
  final userEmail = ''.obs;

  // State Settings
  final isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Panggil loadUserProfile di onReady agar UI sempat di-render
  }

  @override
  void onReady() {
    super.onReady();
    // Sinkronisasi status dark mode awal
    isDarkMode.value = Get.isDarkMode;
    // Panggil loadUserProfile setelah semua service siap
    loadUserProfile();
  }


  void loadUserProfile() {
    // Ambil nama dari AuthService (yang menyimpan nama setelah login sukses)
    String retrievedName = _authService.userName.value;
    String retrievedEmail = _authService.userEmail.value; // Jika userEmail disimpan

    // 1. Tentukan Nama Akhir
    userName.value = retrievedName.isNotEmpty ? retrievedName : "User Investa";

    // 2. Tentukan Email
    userEmail.value = retrievedEmail.isNotEmpty
        ? retrievedEmail
        : "${userName.value.replaceAll(' ', '.').toLowerCase()}@investa.com";
  }

  void toggleTheme(bool isDark) {
    isDarkMode.value = isDark;
    // ThemeMode.dark dan ThemeMode.light berasal dari material.dart
    Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  void logout() {
    _authService.logout();
  }
}