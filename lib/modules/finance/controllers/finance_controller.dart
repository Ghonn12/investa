import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer'; // <--- tambahkan ini
import '../../../../services/finance_service.dart';
import '../../../../models/transaction_model.dart';
import '../../../../widgets/error_snackbar.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../../../services/notification_service.dart';

class FinanceController extends GetxController {
  final FinanceService _financeService = Get.find();
  final NotificationService _notificationService = Get.find();
  var transactions = <TransactionModel>[].obs;
  var isLoading = true.obs;
  var isSubmitting = false.obs;

  // Form Controllers
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final categoryController = TextEditingController();
  var selectedType = 'EXPENSE'.obs;
  var selectedDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
  }

  void addTransaction() async {
    if (titleController.text.isEmpty || amountController.text.isEmpty) {
      AppSnackbars.showError("Mohon isi Judul dan Nominal");
      return;
    }

    isSubmitting.value = true;
    try {
      double amount = double.tryParse(
          amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')
      ) ?? 0;

      final success = await _financeService.addTransaction(
        title: titleController.text,
        amount: amount,
        type: selectedType.value,
        category: categoryController.text.isEmpty ? "Umum" : categoryController.text,
        date: selectedDate.value.toIso8601String(),
      );

      if (success) {
        AppSnackbars.showSuccess("Transaksi berhasil disimpan");
        Get.back();
        _resetForm();

        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().fetchDashboardData();
        }
      } else {
        AppSnackbars.showError("Gagal menyimpan transaksi");
      }
    } catch (e, s) {
      AppSnackbars.showError("Terjadi kesalahan: $e");
      debugPrintStack(stackTrace: s);
    } finally {
      isSubmitting.value = false;
    }
  }

  void _resetForm() {
    titleController.clear();
    amountController.clear();
    categoryController.clear();
    selectedType.value = 'EXPENSE';
    selectedDate.value = DateTime.now();
  }

  @override
  void onClose() {
    titleController.dispose();
    amountController.dispose();
    categoryController.dispose();
    super.onClose();
  }
}
