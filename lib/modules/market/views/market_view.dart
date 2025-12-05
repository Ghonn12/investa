import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/market_controller.dart';
import 'stock_detail_bottomsheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart'; // Pastikan import ini ada

class MarketView extends GetView<MarketController> {
  const MarketView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Market"),
        centerTitle: true,
      ),
      body: Obx(() {
        // ... (Logika Loading dan Empty State) ...
        if (controller.stockPrices.isEmpty && controller.isLoadingAction.value == false) {
          if (controller.popularSymbols.isEmpty) {
            return const Center(child: Text("No market symbols available."));
          }
        }

        if (controller.stockPrices.isEmpty && controller.popularSymbols.isNotEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.popularSymbols.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final stock = controller.popularSymbols[index];
            final symbol = stock['symbol'] as String;
            final name = stock['name'] as String;

            // --- FIX 1: Ambil Map data lengkap ---
            final stockData = controller.stockPrices[symbol] ?? {};

            // --- FIX 2: Akses nilai 'price' di dalam Map dengan aman ---
            // Pastikan konversi ke String lalu ke double
            final price = double.tryParse(stockData['price']?.toString() ?? '0.0') ?? 0.0;

            // --- AKSES DATA PERUBAHAN ---
            final changePercent = double.tryParse(stockData['change_percent']?.toString() ?? '0.00') ?? 0.00;
            final isUp = stockData['is_up'] ?? false;

            final changeText = "${isUp && changePercent != 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%";


            return GestureDetector(
              onTap: () {
                // 1. Kirim harga yang sudah dikonversi dan pasti double
                controller.openTradeSheet(symbol, name, price);

                // 2. Buka BottomSheet
                Get.bottomSheet(
                  StockDetailBottomSheet(
                    symbol: symbol,
                    name: name,
                    price: price, // Kirim harga yang sudah pasti double
                  ),
                  isScrollControlled: true,
                  backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    // ... (Icon dan Simbol) ...
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(symbol, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimaryLight)),
                          Text(name, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : AppColors.textSecondaryLight, overflow: TextOverflow.ellipsis), maxLines: 1,),
                        ],
                      ),
                    ),
                    // HARGA DAN PERSENTASE
                    Obx(() {
                      // Gunakan stockData yang sudah dihitung di luar Obx jika memungkinkan
                      // Namun, untuk memastikan reaktif, kita panggil controller.stockPrices[symbol] lagi
                      final liveData = controller.stockPrices[symbol] ?? {};
                      final livePrice = double.tryParse(liveData['price']?.toString() ?? '0.0') ?? 0.0;
                      final liveChangePercent = double.tryParse(liveData['change_percent']?.toString() ?? '0.00') ?? 0.00;
                      final liveIsUp = liveData['is_up'] ?? false;
                      final liveChangeText = "${liveIsUp && liveChangePercent != 0 ? '+' : ''}${liveChangePercent.toStringAsFixed(2)}%";


                      // Jika harga masih 0 (sedang loading), tampilkan spinner kecil
                      if (livePrice == 0) {
                        return const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary
                            )
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormat.toIdr(livePrice),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Persentase
                          Text(
                            liveChangeText,
                            style: TextStyle(
                              color: liveIsUp ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}