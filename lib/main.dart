import 'package:flutter/material.dart';
import 'package:get/get.dart';
// 1. Import library intl data local
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Format Tanggal Indonesia (Wajib)
  await initializeDateFormatting('id_ID', null);

  try {
    // Registrasi semua service yang butuh init async
    await Get.putAsync<ApiService>(() async => await ApiService().init());
    await Get.putAsync<AuthService>(() async => await AuthService().init());
    await Get.putAsync<SettingsService>(() async => await SettingsService().init());
    await Get.putAsync<NotificationService>(() async => await NotificationService().init());
  } catch (e) {
    debugPrint("Service init error: $e");
  }

  runApp(const InvestaApp());
}

class InvestaApp extends StatelessWidget {
  const InvestaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Investa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Default locale ke Indonesia agar konsisten
      locale: const Locale('id', 'ID'),

      initialRoute: Routes.SPLASH,
      getPages: AppPages.routes,
    );
  }
}
