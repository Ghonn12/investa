import 'package:get/get.dart';
import 'dart:developer';
import '../../../services/finance_service2.dart';
import '../../../models/transaction_model.dart';

class HistoryController extends GetxController {
  final FinanceService _financeService = Get.find();

  var transactions = <TransactionModel>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      isLoading.value = true;
      final data = await _financeService.getTransactions();
      transactions.assignAll(data);
      log("[History] Fetched ${data.length} transactions.");
    } catch (e) {
      log("[History] Error fetching transactions: $e");
      transactions.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshHistory() async {
    await fetchTransactions();
  }
}
