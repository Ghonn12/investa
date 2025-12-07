import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../core/theme/admin_theme.dart';

class LoginView extends StatelessWidget {
  // Inject AuthController
  final controller = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg, // Abu-abu muda
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 400, // Lebar ideal untuk tampilan web
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Logo dan Title
                Row(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 32, color: AdminColors.primary),
                    const SizedBox(width: 12),
                    const Text(
                      "Investa Admin",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Masuk untuk mengelola data pengguna",
                  style: TextStyle(color: AdminColors.textGrey, fontSize: 14),
                ),

                const SizedBox(height: 40),

                // Form Input: Email
                const Text("Email", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.emailC,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    // hintText: "admin@investa.com",
                    prefixIcon: Icon(Icons.email_outlined, color: AdminColors.textGrey),
                  ),
                ),

                const SizedBox(height: 20), // Jarak antar input

                // Form Input: Password
                const Text("Password", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8), // Ganti marginBottom dengan SizedBox
                TextField(
                  controller: controller.passC,
                  obscureText: true,
                  decoration: const InputDecoration(
                    // hintText: "••••••••",
                    prefixIcon: Icon(Icons.lock_outline, color: AdminColors.textGrey),
                  ),
                  onSubmitted: (_) => controller.login(),
                ),

                const SizedBox(height: 40),

                // Tombol Login
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                        : const Text(
                        "Masuk Dashboard",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}