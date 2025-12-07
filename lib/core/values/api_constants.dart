class ApiConstants {
  // PENTING: Untuk Web Development di Chrome, gunakan localhost
  static const String baseUrl = "http://192.168.239.181:8080";

  // --- AUTH ENDPOINTS ---
  static const String login = "/auth/login";

  // --- ADMIN ENDPOINTS (/api/admin) ---

  // Dashboard & Statistik
  static const String adminDashboard = "/api/admin/dashboard";
  static const String adminUserGrowth =
      "/api/admin/user-growth"; // Untuk grafik

  // User Management (List, Create, Update, Delete)
  static const String adminUsers = "/api/admin/users";

  // Transaction Monitoring
  static const String adminTransactions =
      "/api/admin/transactions"; // Log semua transaksi
}
