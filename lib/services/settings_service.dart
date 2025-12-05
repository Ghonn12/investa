import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsService extends GetxService {
  late SharedPreferences _prefs;

  // Keys
  static const String _darkModeKey = 'darkMode';
  static const String _currencyKey = 'currency';
  static const String _languageKey = 'language';
  static const String _notifKey = 'notificationsEnabled';
  static const String _fontSizeKey = 'fontSize';
  static const String _onboardingKey = 'onboardingDone';

  // Reactive states
  final isDarkMode = false.obs;
  final currency = 'IDR'.obs;
  final language = 'id'.obs; // default bahasa Indonesia
  final notificationsEnabled = true.obs;
  final fontSize = 14.0.obs;
  final onboardingDone = false.obs;

  /// Inisialisasi service dan load preferences
  Future<SettingsService> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Load saved preferences
    isDarkMode.value = _prefs.getBool(_darkModeKey) ?? false;
    currency.value = _prefs.getString(_currencyKey) ?? 'IDR';
    language.value = _prefs.getString(_languageKey) ?? 'id';
    notificationsEnabled.value = _prefs.getBool(_notifKey) ?? true;
    fontSize.value = _prefs.getDouble(_fontSizeKey) ?? 14.0;
    onboardingDone.value = _prefs.getBool(_onboardingKey) ?? false;

    // Apply theme sesuai dark mode
    _applyTheme();

    // Apply locale sesuai bahasa
    _applyLocale();

    return this;
  }

  // ---------------- Dark Mode ----------------
  void toggleDarkMode(bool isDark) {
    isDarkMode.value = isDark;
    _prefs.setBool(_darkModeKey, isDark);
    _applyTheme();
  }

  void _applyTheme() {
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  // ---------------- Currency ----------------
  Future<void> setCurrency(String newCurrency) async {
    currency.value = newCurrency;
    await _prefs.setString(_currencyKey, newCurrency);
  }

  // ---------------- Language ----------------
  Future<void> setLanguage(String newLang) async {
    language.value = newLang;
    await _prefs.setString(_languageKey, newLang);
    _applyLocale();
  }

  void _applyLocale() {
    final langCode = language.value;
    Get.updateLocale(Locale(langCode));
  }

  // ---------------- Notifications ----------------
  Future<void> toggleNotifications(bool enabled) async {
    notificationsEnabled.value = enabled;
    await _prefs.setBool(_notifKey, enabled);
  }

  // ---------------- Font Size ----------------
  Future<void> setFontSize(double size) async {
    fontSize.value = size;
    await _prefs.setDouble(_fontSizeKey, size);
  }

  // ---------------- Onboarding ----------------
  Future<void> setOnboardingDone(bool done) async {
    onboardingDone.value = done;
    await _prefs.setBool(_onboardingKey, done);
  }
}
