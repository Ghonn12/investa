import 'package:flutter/material.dart';
import 'package:get/get.dart';

// View & Controller Lain
import '../modules/splash/views/splash_view.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/register_view.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/finance/views/finance_view.dart';
import '../modules/market/views/market_view.dart';
import '../modules/portfolio/views/portfolio_view.dart';
import '../modules/chat_ai/views/chat_ai_view.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/history/views/history_view.dart';

// FINANCE 2 (PUNYA KITA)
import '../modules/finance2/views/finance2_view.dart';
import '../modules/finance2/controllers/finance2_controller.dart';

// Controller Lain
import '../modules/splash/controllers/splash_controller.dart';
import '../modules/auth/controllers/login_controller.dart';
import '../modules/auth/controllers/register_controller.dart';
import '../modules/dashboard/controllers/dashboard_controller.dart';
import '../modules/finance/controllers/finance_controller.dart';
import '../modules/market/controllers/market_controller.dart';
import '../modules/portfolio/controllers/portfolio_controller.dart';
import '../modules/chat_ai/controllers/chat_ai_controller.dart';
import '../modules/profile/controllers/profile_controller.dart';
import '../modules/history/controllers/history_controller.dart';

// Services
import '../services/finance_service.dart';  // Service lama
import '../services/finance_service2.dart'; // Service baru
import '../../services/trade_service.dart';
import '../../services/ai_service.dart';

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    // 1. Splash Screen
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashView(),
      binding: BindingsBuilder(() {
        Get.put(SplashController());
      }),
    ),

    // 2. Auth Modules
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => LoginController());
      }),
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => const RegisterView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => RegisterController());
      }),
    ),

    // 3. Main Dashboard
    GetPage(
      name: Routes.DASHBOARD,
      page: () => const DashboardView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => TradeService());
        Get.lazyPut(() => DashboardController());
      }),
    ),

    // 4. Finance (Punya goni - LAMA)
    GetPage(
      name: Routes.FINANCE,
      page: () => const FinanceView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => FinanceService());
        Get.lazyPut(() => FinanceController());
      }),
    ),

    // ==========================================
    // 4.5. Finance Sakuku (Punya fajr - BARU)
    // ==========================================
    GetPage(
      name: Routes.FINANCE_SAKUKU,
      page: () => Finance2View(), 
      binding: BindingsBuilder(() {
        // Gunakan Service 2 & Controller 2
        Get.lazyPut(() => FinanceService2()); 
        Get.lazyPut(() => Finance2Controller());
      }),
    ),

    // 5. Market
    GetPage(
      name: Routes.MARKET,
      page: () => const MarketView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => TradeService());
        Get.lazyPut(() => MarketController());
      }),
    ),

    // 6. Portfolio
    GetPage(
      name: Routes.PORTFOLIO,
      page: () => const PortfolioView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => TradeService());
        Get.lazyPut(() => PortfolioController());
      }),
    ),

    // 7. AI Chat
    GetPage(
      name: Routes.CHAT_AI,
      page: () => const ChatAiView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AiService());
        Get.lazyPut(() => ChatAiController());
      }),
    ),

    // 8. Profile
    GetPage(
      name: Routes.PROFILE,
      page: () => const ProfileView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProfileController());
      }),
    ),

    // 9. History
    GetPage(
      name: Routes.HISTORY,
      page: () => const HistoryView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => FinanceService2()); 
        Get.lazyPut(() => HistoryController());
      }),
    ),
  ];
}