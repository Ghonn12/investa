import 'dart:developer';
import 'package:get/get.dart';
import '../../../../services/trade_service.dart';
import '../../../../services/auth_service.dart';

class DashboardController extends GetxController {
  final TradeService _tradeService = Get.find();
  final AuthService _authService = Get.find();

  var isLoading = true.obs;
  var netWorth = 0.0.obs;
  var cashBalance = 0.0.obs;
  var userName = ''.obs;

  var marketMovers = <Map<String, dynamic>>[].obs;

  @override
  void onReady() {
    super.onReady();
    // Ambil nama user setelah init service
    userName.value = _authService.userName.value;
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    // Tetapkan loading true di awal agar user melihat spinner
    isLoading.value = true;

    // Reset data jika gagal fetch
    netWorth.value = 0.0;
    cashBalance.value = 0.0;
    marketMovers.clear();

    try {
      log("Starting data fetch for Dashboard...");

      // 1. Ambil Data Portfolio (Net Worth)
      final portfolioData = await _tradeService.getPortfolioOverview();

      // Pastikan semua parsing aman dari null
      netWorth.value = double.tryParse(portfolioData['net_worth']?.toString() ?? '0.0') ?? 0.0;
      cashBalance.value = double.tryParse(portfolioData['cash_balance']?.toString() ?? '0.0') ?? 0.0;

      log("Portfolio data loaded. Net Worth: ${netWorth.value}");


      // 2. Ambil Data Saham Populer (Market Movers)
      final stocksData = await _tradeService.getMarketStocks();

      // Ambil 5 saham teratas saja
      if (stocksData.isNotEmpty) {
        marketMovers.assignAll(stocksData.take(5).toList());
      }

    } catch (e) {
      log("ERROR: Data Dashboard gagal dimuat. Kemungkinan 401: $e");
      // Tidak perlu menampilkan snackbar karena ApiService sudah mengarahkan ke Login jika 401
    } finally {
      isLoading.value = false;
      log("Dashboard fetch complete.");
    }
  }
}