import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/finance_service.dart';
import '../../../models/transaction_model_v2.dart';
import '../../../models/category_model.dart';
import '../../../models/wallet_model.dart';

class Finance2Controller extends GetxController {
  final FinanceService _service = Get.find<FinanceService>();

  var transactions = <TransactionModelV2>[].obs;
  var categories = <CategoryModel>[].obs;
  var wallets = <WalletModel>[].obs;
  var isLoading = true.obs;

  // Form Input
  final deskripsiC = TextEditingController();
  final amountC = TextEditingController();
  
  // Pilihan
  var selectedType = 'Pengeluaran'.obs;
  var selectedDate = DateTime.now().obs;
  var selectedCatId = Rxn<int>();
  var selectedWalletId = Rxn<int>();

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void loadData() async {
    isLoading.value = true;
    await Future.wait([
      fetchTrx(),
      fetchCat(),
      fetchWal()
    ]);
    isLoading.value = false;
  }

  Future<void> fetchTrx() async {
    var res = await _service.getTransactions();
    transactions.assignAll(res);
  }
  Future<void> fetchCat() async {
    var res = await _service.getCategories();
    categories.assignAll(res);
  }
  Future<void> fetchWal() async {
    var res = await _service.getWallets();
    wallets.assignAll(res);
  }

  // Filter kategori berdasarkan tipe
  List<CategoryModel> get filteredCat {
    return categories.where((e) => e.tipe == selectedType.value).toList();
  }

  void save() async {
    if(selectedCatId.value == null || selectedWalletId.value == null) {
      Get.snackbar("Error", "Pilih kategori & wallet");
      return;
    }
    bool ok = await _service.addTransaction(
      deskripsi: deskripsiC.text,
      amount: double.tryParse(amountC.text) ?? 0,
      type: selectedType.value,
      walletId: selectedWalletId.value!,
      kategoriId: selectedCatId.value!,
      date: selectedDate.value.toIso8601String(),
    );
    if(ok) {
      Get.back();
      fetchTrx();
      deskripsiC.clear(); amountC.clear();
      Get.snackbar("Sukses", "Disimpan");
    } else {
      Get.snackbar("Gagal", "Cek koneksi");
    }
  }

  void delete(int id) async {
    bool ok = await _service.deleteTransaction(id);
    if(ok) fetchTrx();
  }
}