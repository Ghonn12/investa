import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../routes/app_pages.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Obx(() => Text(
              controller.userName.value.isNotEmpty ? controller.userName.value[0] : "U",
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            )),
          ),
        ),
        title: const Text("Home"),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: isDark ? Colors.white : AppColors.textSecondaryLight),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.fetchDashboardData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Total Balance Card
              Obx(() => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Balance", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                    const SizedBox(height: 8),
                    controller.isLoading.value
                        ? const SizedBox(height: 30, width: 30, child: CircularProgressIndicator(color: Colors.white))
                        : Text(
                      CurrencyFormat.toIdr(controller.netWorth.value),
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        "Cash: ${CurrencyFormat.toIdr(controller.cashBalance.value)}",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )),

              const SizedBox(height: 24),

              // 2. Menu Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMenuItem(context, Icons.add_card, "Top Up", () => Get.toNamed(Routes.FINANCE)),
                  _buildMenuItem(context, Icons.pie_chart_outline, "Portfolio", () => Get.toNamed(Routes.PORTFOLIO)),
                  _buildMenuItem(context, Icons.history, "History", () => Get.toNamed(Routes.HISTORY)),
                  _buildMenuItem(context, Icons.smart_toy_outlined, "Chat AI", () => Get.toNamed(Routes.CHAT_AI)),
                ],
              ),

              const SizedBox(height: 32),

              // 3. Market Movers Title
              Text(
                "Market Movers",
                style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),

              // 4. Horizontal List (DATA ASLI DARI CONTROLLER)
              SizedBox(
                height: 140,
                child: Obx(() {
                  if (controller.isLoading.value && controller.marketMovers.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.marketMovers.isEmpty) {
                    return const Center(child: Text("No market data"));
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.marketMovers.length,
                    itemBuilder: (context, index) {
                      final stock = controller.marketMovers[index];
                      final symbol = stock['symbol'] ?? '';
                      final name = stock['name'] ?? '';
                      final price = double.tryParse(stock['price']?.toString() ?? '0.0') ?? 0.0;

                      // --- MENGAMBIL DATA PERUBAHAN DARI BACKEND ---
                      final changePercent = double.tryParse(stock['change_percent']?.toString() ?? '0.00') ?? 0.00;
                      final isUp = stock['is_up'] ?? true;

                      final changeText = "${isUp && changePercent != 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%";
                      // ------------------------------------------

                      return _buildMarketCard(context, symbol, name, CurrencyFormat.toIdr(price), changeText, isUp);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      // Bottom Nav Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDark.withOpacity(0.9) : Colors.white.withOpacity(0.9),
          border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, "Home", true),
            _buildNavItem(Icons.candlestick_chart, "Market", false, onTap: () => Get.toNamed(Routes.MARKET)),
            _buildNavItem(Icons.account_balance_wallet, "Wallet", false, onTap: () => Get.toNamed(Routes.FINANCE)),
            _buildNavItem(Icons.person, "Profile", false, onTap: () => Get.toNamed(Routes.PROFILE)),
          ],
        ),
      ),
    );
  }

  // Widget Helper (Sama seperti sebelumnya)
  Widget _buildMenuItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketCard(BuildContext context, String symbol, String name, String price, String change, bool isUp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                child: Text(symbol.isNotEmpty ? symbol[0] : '?', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(name, style: TextStyle(color: Colors.grey[500], fontSize: 10, overflow: TextOverflow.ellipsis), maxLines: 1,),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                change,
                style: TextStyle(
                  color: isUp ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? AppColors.primary : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? AppColors.primary : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}