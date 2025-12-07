import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/admin_theme.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';

void main() async {
  // Init Services
  await Get.putAsync(() => ApiService().init());
  // FIX: Tambahkan tanda kurung penutup yang hilang
  await Get.putAsync(() => AuthService().init());

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Investa Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.theme,
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => LoginView()),
        GetPage(name: '/home', page: () => HomeView()),
      ],
    );
  }
}