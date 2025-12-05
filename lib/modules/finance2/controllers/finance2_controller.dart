import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/finance_service2.dart';
import '../../../models/transaction_model_v2.dart';
import '../../../models/category_model.dart';
import '../../../models/wallet_model.dart';

class Finance2Controller extends GetxController {
  final FinanceService2 _service = Get.find<FinanceService2>();

  var transactions = <TransactionModelV2>[].obs;
  var categories = <CategoryModel>[].obs;
  var wallets = <WalletModel>[].obs;
  var isLoading = true.obs;

  // Dashboard Data
  var totalCash = 0.0.obs;
  var totalRekening = 0.0.obs;
  var pieChartData = <Map<String, dynamic>>[].obs;

  // Filters
  var searchText = ''.obs;
  var filterDate = 'Semua'.obs;

  // Form Input
  final deskripsiC = TextEditingController();
  final amountC = TextEditingController();

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
    await Future.wait([fetchDash(), fetchTrx(), fetchCat(), fetchWal()]);
    isLoading.value = false;
  }

  Future<void> fetchDash() async {
    var data = await _service.getDashboardSummary();
    if (data.isNotEmpty) {
      totalCash.value = double.tryParse(data['total_cash'].toString()) ?? 0;
      totalRekening.value =
          double.tryParse(data['total_rekening'].toString()) ?? 0;
      var charts = data['pie_chart'] as List;
      pieChartData.assignAll(
        charts.map((e) => e as Map<String, dynamic>).toList(),
      );
    }
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

  List<TransactionModelV2> get filteredTransactions {
    var list = transactions.toList();
    // 1. Merge Penarikan: Hide (Dest)
    list = list.where((e) {
      bool isDestPenarikan = e.deskripsi.contains('(Dest)');
      return !isDestPenarikan;
    }).toList();

    // 2. Date
    if (filterDate.value != 'Semua') {
      DateTime now = DateTime.now();
      list = list.where((e) {
        DateTime date = DateTime.tryParse(e.date) ?? DateTime.now();
        if (filterDate.value == 'Hari Ini') {
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        } else if (filterDate.value == '7 Hari') {
          return date.isAfter(now.subtract(Duration(days: 7)));
        } else if (filterDate.value == '1 Bulan') {
          return date.isAfter(now.subtract(Duration(days: 30)));
        }
        return true;
      }).toList();
    }

    // 3. Search
    if (searchText.value.isNotEmpty) {
      String query = searchText.value.toLowerCase();
      list = list.where((e) {
        return e.deskripsi.toLowerCase().contains(query) ||
            e.amount.toString().contains(query) ||
            e.walletNama.toLowerCase().contains(query);
      }).toList();
    }
    return list;
  }

  String getDisplayTitle(TransactionModelV2 trx) {
    // Rely on (Source) tag for identification
    if (trx.deskripsi.contains('(Source)')) {
      // Clean up the tag. Original desc + tag -> return Original desc
      return trx.deskripsi.replaceAll('(Source)', '').trim();
    }
    return trx.deskripsi.trim();
  }

  List<CategoryModel> get filteredCat {
    String typeFilter = selectedType.value;
    if (typeFilter == 'Penarikan') typeFilter = 'Pengeluaran';
    return categories
        .where((e) => e.tipe == typeFilter || e.tipe == 'EXPENSE')
        .toList();
  }

  // Filter Wallet: Jika Penarikan, jangan tampilkan Cash/Tunai
  List<WalletModel> get filteredWallets {
    if (selectedType.value == 'Penarikan') {
      return wallets.where((w) {
        return w.tipeWallet != 'Cash' &&
            !w.namaWallet.toLowerCase().contains('cash') &&
            !w.namaWallet.toLowerCase().contains('tunai');
      }).toList();
    }
    return wallets;
  }

  void save() async {
    if (selectedType.value != 'Penarikan' && selectedCatId.value == null) {
      Get.snackbar("Error", "Pilih kategori");
      return;
    }
    if (selectedWalletId.value == null) {
      Get.snackbar("Error", "Pilih wallet");
      return;
    }

    bool ok = await _service.addTransaction(
      deskripsi: deskripsiC.text,
      amount: double.tryParse(amountC.text) ?? 0,
      type: selectedType.value,
      walletId: selectedWalletId.value!,
      kategoriId: selectedCatId.value ?? 0,
      date: selectedDate.value.toIso8601String(),
    );

    if (ok) {
      Get.back();
      loadData();
      deskripsiC.clear();
      amountC.clear();
      Get.snackbar("Sukses", "Disimpan");
    } else {
      Get.snackbar("Gagal", "Cek koneksi");
    }
  }

  void delete(int id) async {
    bool ok = await _service.deleteTransaction(id);
    if (ok) loadData();
  }

  // --- Manage Category ---
  void addCategory(String name, String type) async {
    bool ok = await _service.addCategory(name, type);
    if (ok) {
      Get.back();
      fetchCat();
      Get.snackbar("Sukses", "Kategori berhasil ditambahkan");
    }
  }

  void removeCategory(int id) async {
    bool ok = await _service.deleteCategory(id);
    if (ok) {
      fetchCat();
      Get.snackbar("Sukses", "Kategori dihapus");
    }
  }

  // --- Manage Wallet ---
  void addWallet(String name, String type) async {
    bool ok = await _service.addWallet(name, type);
    if (ok) {
      Get.back();
      fetchWal();
      Get.snackbar("Sukses", "Wallet berhasil ditambahkan");
    }
  }

  void removeWallet(int id) async {
    bool ok = await _service.deleteWallet(id);
    if (ok) {
      fetchWal();
      Get.snackbar("Sukses", "Wallet dihapus");
    }
  }
}
