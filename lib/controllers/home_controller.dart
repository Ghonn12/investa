import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../core/values/api_constants.dart';

class HomeController extends GetxController {
  final ApiService _api = Get.find();
  final AuthService _auth = Get.find();

  var activeTab = 0.obs; // 0 = Dashboard, 1 = Users, 2 = Transactions
  var isLoading = false.obs;

  var stats = <String, dynamic>{}.obs;
  var users = <dynamic>[].obs;

  var userGrowthData = <double>[].obs;
  var labels = <String>[].obs;

  var transactions = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardStats();
  }

  void changeTab(int index) {
    activeTab.value = index;
    if (index == 0) fetchDashboardStats();
    if (index == 1) fetchUsers();
    if (index == 2) fetchTransactions();
  }

  // --- FITUR 1: DASHBOARD ---
  void fetchDashboardStats() async {
    isLoading.value = true;
    try {
      // 1. Fetch Statistik
      final responseStats = await _api.get(ApiConstants.adminDashboard);
      if (responseStats.statusCode == 200 && responseStats.data['data'] != null) {
        stats.value = responseStats.data['data'];
      }

      // 2. Fetch Data Grafik (DATA ASLI)
      // PERBAIKAN: Menggunakan konstanta yang benar
      final responseGrowth = await _api.get(ApiConstants.adminUserGrowth);

      if (responseGrowth.statusCode == 200 && responseGrowth.data['data'] != null) {
        final data = responseGrowth.data['data'];

        userGrowthData.value = List<double>.from(data['growth_data'].map((x) => double.tryParse(x.toString()) ?? 0.0));
        labels.value = List<String>.from(data['labels']);
      }

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat statistik dashboard: $e",
          maxWidth: 400, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // --- FITUR 2: USER MANAGEMENT ---

  // Ambil semua user
  void fetchUsers() async {
    isLoading.value = true;
    try {
      final response = await _api.get(ApiConstants.adminUsers);
      if (response.statusCode == 200 && response.data['data'] != null) {
        users.value = response.data['data'];
      } else {
        users.clear();
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data user: $e",
          maxWidth: 400, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Tambah User Baru (Create)
  void addUser(String name, String email, String password) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Semua kolom wajib diisi", maxWidth: 400, backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    Get.back();
    isLoading.value = true;

    try {
      final response = await _api.post(ApiConstants.adminUsers, data: {
        'name': name,
        'email': email,
        'password': password
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar("Sukses", "User baru berhasil ditambahkan",
            maxWidth: 400, backgroundColor: Colors.green, colorText: Colors.white);
        fetchUsers();
      } else {
        String errorMsg = response.data['messages']?.toString() ?? "Gagal menambah user";
        Get.snackbar("Gagal", errorMsg, maxWidth: 400, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan: $e", maxWidth: 400);
    } finally {
      isLoading.value = false;
    }
  }

  // Blokir / Buka Blokir User (Update Status)
  void toggleBlockUser(int id, bool isCurrentlyBlocked) async {
    String newStatus = isCurrentlyBlocked ? 'ACTIVE' : 'BLOCKED';

    try {
      // Endpoint PUT: /api/admin/users/{id}
      final response = await _api.put('${ApiConstants.adminUsers}/$id', data: {
        'status': newStatus
      });

      if (response.statusCode == 200) {
        Get.snackbar(
            "Sukses",
            "Status user berhasil diubah menjadi $newStatus",
            maxWidth: 400,
            backgroundColor: isCurrentlyBlocked ? Colors.green : Colors.orange,
            colorText: Colors.white
        );
        fetchUsers();
      }
    } catch (e) {
      Get.snackbar("Gagal", "Tidak dapat mengubah status user: $e", maxWidth: 400);
    }
  }

  // Hapus User Permanen (Delete)
  void deleteUser(int id) async {
    Get.defaultDialog(
        title: "Hapus User?",
        middleText: "Tindakan ini tidak dapat dibatalkan. Semua data transaksi & portfolio user ini akan hilang.",
        textConfirm: "Hapus Permanen",
        confirmTextColor: Colors.white,
        buttonColor: Colors.red,
        textCancel: "Batal",
        onConfirm: () async {
          Get.back(); // Tutup dialog
          _performDelete(id);
        }
    );
  }

  void _performDelete(int id) async {
    try {
      // Endpoint DELETE: /api/admin/users/{id}
      final response = await _api.delete('${ApiConstants.adminUsers}/$id');
      if (response.statusCode == 200) {
        Get.snackbar("Terhapus", "User berhasil dihapus dari sistem",
            maxWidth: 400, backgroundColor: Colors.green, colorText: Colors.white);
        fetchUsers();
      }
    } catch (e) {
      Get.snackbar("Gagal", "Gagal menghapus user: $e", maxWidth: 400);
    }
  }

  // --- FITUR 3: LOG TRANSAKSI ---
  void fetchTransactions() async {
    isLoading.value = true;
    try {
      final response = await _api.get(ApiConstants.adminTransactions);
      if (response.statusCode == 200 && response.data['data'] != null) {
        transactions.value = response.data['data'];
      } else {
        transactions.clear();
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat log transaksi: $e",
          maxWidth: 400, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Logout
  void logout() {
    _auth.logout();
  }
}