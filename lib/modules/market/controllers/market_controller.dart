import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../../services/trade_service.dart';
import '../../../../widgets/error_snackbar.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

class MarketController extends GetxController {
  final TradeService _tradeService = Get.find();

  var quantityController = TextEditingController();
  var isLoadingAction = false.obs;

  // Daftar Saham Populer
  final popularSymbols = [
    {'symbol': 'BBCA.JK', 'name': 'Bank Central Asia'},
    {'symbol': 'TLKM.JK', 'name': 'Telkom Indonesia'},
    {'symbol': 'BBRI.JK', 'name': 'Bank Rakyat Indonesia'},
    {'symbol': 'BMRI.JK', 'name': 'Bank Mandiri'},
    {'symbol': 'ASII.JK', 'name': 'Astra International'},
    {'symbol': 'GOTO.JK', 'name': 'GoTo Gojek Tokopedia'},
    {'symbol': 'BTC-USD', 'name': 'Bitcoin'},
    {'symbol': 'ETH-USD', 'name': 'Ethereum'},
  ];

  // FIX: Mengubah tipe data untuk menyimpan data lengkap (price, percent, is_up)
  var stockPrices = <String, Map<String, dynamic>>{}.obs;

  var currentDetailPrice = 0.0.obs;
  var isFetchingPrice = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllPrices();
  }

  void fetchAllPrices() async {
    try {
      final stocksData = await _tradeService.getMarketStocks();

      if (stocksData.isNotEmpty) {
        Map<String, Map<String, dynamic>> tempMap = {};
        for (var stock in stocksData) {
          final symbol = stock['symbol'] as String;
          tempMap[symbol] = {
            // Pastikan parsing yang aman
            'price': double.tryParse(stock['price']?.toString() ?? '0.0') ?? 0.0,
            'change_percent': double.tryParse(stock['change_percent']?.toString() ?? '0.0') ?? 0.0,
            'is_up': stock['is_up'] ?? false,
          };
        }
        stockPrices.value = tempMap;
      }
    } catch (e) {
      log('Error fetching all market data: $e');
    }
  }

  void openTradeSheet(String symbol, String name, double initialPrice) async {
    isFetchingPrice.value = true;
    currentDetailPrice.value = initialPrice;
    quantityController.clear();

    try {
      // Panggil API tunggal untuk memastikan harga saat ini benar-benar fresh
      final price = await _tradeService.getStockPrice(symbol);

      if (price > 0) {
        currentDetailPrice.value = price;

        // KRITIS: Update harga di Map utama (stockPrices)
        if (stockPrices.containsKey(symbol)) {
          // Kita hanya update price, bukan change_percent atau is_up
          stockPrices[symbol]!['price'] = price;
          // Gunakan update() untuk memicu rebuild di Obx
          stockPrices.update(symbol, (value) => value);
        }
      }
    } catch (e) {
      log('Error fetching detail price: $e');
    } finally {
      isFetchingPrice.value = false;
    }
  }

  double get estimatedCost {
    if (quantityController.text.isEmpty) return 0;
    final qty = double.tryParse(quantityController.text) ?? 0;
    return qty * currentDetailPrice.value;
  }

  void executeTrade(String symbol, bool isBuy) async {
    if (quantityController.text.isEmpty) {
      AppSnackbars.showError("Masukkan jumlah lot/lembar");
      return;
    }

    // FIX 1: Pindahkan deklarasi qty ke sini (di luar blok if)
    final qtyText = quantityController.text;
    final qty = double.tryParse(qtyText);

    if (qty == null || qty <= 0) {
      AppSnackbars.showError("Jumlah harus angka positif");
      return;
    }

    // Karena qty sudah terdefinisi dan diverifikasi bukan null/0, kita bisa langsung menggunakan qty!
    // final confirmedQty = qty; // Line ini tidak diperlukan lagi

    isLoadingAction.value = true;
    try {
      bool success;
      // Gunakan qty! untuk non-null assertion
      log('Executing trade: $symbol, Buy: $isBuy, Qty: $qty');

      if (isBuy) {
        success = await _tradeService.buyStock(symbol, qty!);
      } else {
        success = await _tradeService.sellStock(symbol, qty!);
      }

      if (success) {
        // ... (Logika sukses) ...
        AppSnackbars.showSuccess(isBuy ? "Pembelian Berhasil" : "Penjualan Berhasil");
        Get.back();
        quantityController.clear();

        fetchAllPrices();

        if (Get.isRegistered<DashboardController>()) {
          log('Refreshing Dashboard Data...');
          Get.find<DashboardController>().fetchDashboardData();
        }

      } else {
        AppSnackbars.showError("Transaksi Gagal.");
      }
    } on DioException catch (e) {
      // ... (error handling) ...
      log('DioException during trade: ${e.response?.data}');
      String message = "Terjadi kesalahan koneksi";
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data['message'] != null) {
          message = data['message'].toString();
        } else if (data['messages'] != null) {
          if (data['messages'] is Map) {
            message = data['messages'].values.first.toString();
          } else {
            message = data['messages'].toString();
          }
        } else if (data['error'] != null) {
          message = data['error'].toString();
        }
      }
      AppSnackbars.showError(message);

    } catch (e) {
      log('Unknown error during trade: $e');
      AppSnackbars.showError("Gagal: ${e.toString()}");
    } finally {
      isLoadingAction.value = false;
    }
  }
}