class ApiConstants {
  // GUNAKAN 10.0.2.2 KHUSUS UNTUK EMULATOR ANDROID
  // Jika Anda memakai HP fisik, ganti dengan IP Laptop (misal: 192.168.1.X)
  // Jika Anda memakai iOS Simulator, ganti dengan localhost
  // static const String baseUrl = "http://10.0.2.2:8080";
  // static const String baseUrl = "http://localhost:8081"; // Untuk iOS Simulator
  static const String baseUrl = "http://192.168.1.25:8080";
  // Auth Endpoints
  static const String login = "/auth/login";
  static const String register = "/auth/register";
  static const String profile  = "/auth/profile";

  // Feature Endpoints
  static const String finance = "/api/finance";
  static const String portfolio = "/api/portfolio";
  static const String tradeBuy = "/api/trade/buy";
  static const String tradeSell = "/api/trade/sell";
  static const String chat = "/api/chat";

  // Market Data Endpoints (Yang baru kita tambahkan)
  static const String marketPrice = "/api/market/price";
  static const String marketStocks = "/api/market/stocks";
}