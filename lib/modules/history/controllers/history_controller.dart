import 'package:get/get.dart';
import 'dart:developer';
// Import Service 2 (Sakuku)
import '../../../services/finance_service2.dart'; 
// Import Model V2 (PENTING: Pakai model V2 agar cocok dengan data service)
import '../../../models/transaction_model_v2.dart'; 

class HistoryController extends GetxController {
  // Gunakan Service 2
  final FinanceService2 _financeService = Get.find<FinanceService2>();

  // GANTI TIPE DATA JADI V2
  var transactions = <TransactionModelV2>[].obs; 
  
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      isLoading.value = true;
      // Sekarang tipe datanya cocok (sama-sama V2)
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