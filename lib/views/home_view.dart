import 'package:flutter/material.dart';
import 'package:get/get.dart';
// FIX 1: Hapus spasi di fl_chart (jika masih ada)
import 'package:fl_chart/fl_chart.dart';
import '../controllers/home_controller.dart';
import '../core/theme/admin_theme.dart';
// FIX 2: Import CurrencyFormat (Gunakan path package untuk mencegah error)
import 'package:investa_admin/core/utils/currency_format.dart';

class HomeView extends StatelessWidget {
  final controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // --- SIDEBAR ---
          Container(
            width: 260,
            color: AdminColors.primary,
            child: Column(
              children: [
                _buildHeader(),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 24),
                Obx(
                  () => Column(
                    children: [
                      _buildSidebarItem(
                        Icons.dashboard,
                        "Dashboard",
                        0,
                        isActive: controller.activeTab.value == 0,
                      ),
                      _buildSidebarItem(
                        Icons.people,
                        "User Management",
                        1,
                        isActive: controller.activeTab.value == 1,
                      ),
                      _buildSidebarItem(
                        Icons.receipt_long,
                        "Transactions",
                        2,
                        isActive: controller.activeTab.value == 2,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _buildSidebarItem(
                  Icons.logout,
                  "Logout",
                  99,
                  isActive: false,
                  onTap: controller.logout,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // --- MAIN CONTENT ---
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: Container(
                    color: AdminColors.bg,
                    padding: const EdgeInsets.all(32),
                    child: Obx(() {
                      if (controller.activeTab.value == 0) {
                        return _buildDashboardContent();
                      } else if (controller.activeTab.value == 1) {
                        return _buildUserContent(context);
                      } else {
                        // KONTEN TRANSAKSI
                        return _buildTransactionContent();
                      }
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- KONTEN TRANSAKSI ---
  Widget _buildTransactionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Log Aktivitas Transaksi",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.transactions.isEmpty) {
                  return const Center(child: Text("Belum ada data transaksi."));
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              AdminColors.bg,
                            ),
                          dataRowHeight: 56,
                          dividerThickness: 0.5,
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'ID',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Tanggal',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Pemilik',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Tipe',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Judul/Kategori',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Nominal',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              numeric: true,
                            ),
                          ],
                          rows: controller.transactions.map((trx) {
                            final bool isIncome = trx['type'] == 'INCOME';
                            final Color statusColor = isIncome
                                ? Colors.green
                                : Colors.red;

                            return DataRow(
                              cells: [
                                DataCell(Text("#${trx['id']}")),
                                DataCell(Text(trx['date'] ?? '-')),
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        trx['user_name'] ?? 'N/A',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        trx['user_email'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AdminColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      trx['type'] ?? '-',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(trx['title'] ?? trx['category'] ?? '-'),
                                ),
                                DataCell(
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      // Format harus aman dari null/integer
                                      "${isIncome ? '+' : '-'} ${CurrencyFormat.toIdr(double.tryParse(trx['amount']?.toString() ?? '0') ?? 0)}",
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(), // Closing toList
                        ),
                      ),
                      )
                    );
                  }, // Closing builder
                ); // Closing LayoutBuilder
              }),
            ),
          ),
        ),
      ],
    );
  }

  // Widget Top Bar (Contoh)
  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(
            () => Text(
              controller.activeTab.value == 0
                  ? "Dashboard Overview"
                  : controller.activeTab.value == 1
                  ? "User Management"
                  : "Transaction Log",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: AdminColors.bg,
                child: Icon(Icons.person, color: AdminColors.text),
              ),
              SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Admin",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    "Super Admin",
                    style: TextStyle(color: AdminColors.textGrey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Header Sidebar (Contoh)
  Widget _buildHeader() {
    return Container(
      height: 80,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: const Row(
        children: [
          Icon(Icons.bar_chart_rounded, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Text(
            "Investa",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Widget Sidebar Item (Contoh)
  Widget _buildSidebarItem(
    IconData icon,
    String title,
    int index, {
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () => controller.changeTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
          border: isActive
              ? const Border(
                  left: BorderSide(color: AdminColors.secondary, width: 4),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white70,
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Dashboard Content (Contoh)
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grid Kartu Statistik
          Row(
            children: [
              _buildStatCard(
                "Total Users",
                "${controller.stats['total_users'] ?? 0}",
                Icons.people,
                Colors.blue,
              ),
              const SizedBox(width: 24),
              _buildStatCard(
                "Total Transactions",
                "${controller.stats['total_transactions'] ?? 0}",
                Icons.receipt,
                Colors.orange,
              ),
              const SizedBox(width: 24),
              _buildStatCard(
                "Total Circulation",
                "Rp ${controller.stats['total_balance'] ?? 0}",
                Icons.monetization_on,
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Grafik Pertumbuhan User (Real Data)
          Container(
            width: double.infinity,
            height: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Pertumbuhan User (6 Bulan Terakhir)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Obx(() {
                    if (controller.userGrowthData.isEmpty) {
                      // Tampilkan loading jika sedang fetch
                      return const Center(child: CircularProgressIndicator());
                    }
                    return LineChart(
                      _mainData(
                        controller.userGrowthData.toList(),
                        controller.labels.toList(),
                      ),
                      // FIX: Hapus swapAnimationDuration di sini
                      // swapAnimationDuration: const Duration(milliseconds: 500),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk data LineChart
  LineChartData _mainData(List<double> data, List<String> labels) {
    // Mapping data ke FlSpot (x=index, y=value)
    List<FlSpot> spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    // Nilai tertinggi untuk sumbu Y
    final maxY = data.reduce((a, b) => a > b ? a : b) * 1.1;
    final intervalY = (maxY / 5).ceilToDouble();

    return LineChartData(
      // FIX: Default duration is now 150ms in newer fl_chart versions
      // You can set the duration here if needed: duration: const Duration(milliseconds: 500),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: intervalY,
        getDrawingHorizontalLine: (value) =>
            const FlLine(color: AdminColors.border, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < labels.length) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    labels[index],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AdminColors.textGrey,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(), // Tampilkan angka user
              style: const TextStyle(fontSize: 12, color: AdminColors.textGrey),
            ),
            interval: intervalY,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(color: AdminColors.border, width: 2),
          left: BorderSide(color: AdminColors.border, width: 2),
        ),
      ),
      minX: 0,
      maxX: (data.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AdminColors.primary,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AdminColors.primary.withOpacity(0.4),
                AdminColors.primary.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action Bar (Search & Add)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Search
            Container(
              width: 300,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminColors.border),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: AdminColors.textGrey),
                  hintText: "Cari user...",
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            // Add Button
            ElevatedButton.icon(
              onPressed: () => _showAddUserDialog(context),
              icon: const Icon(Icons.add),
              label: const Text("Tambah User Baru"),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Data Table Card
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Jika data kosong
                if (controller.users.isEmpty) {
                  return const Center(child: Text("Belum ada data user."));
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(AdminColors.bg),
                            dataRowHeight: 72,
                            dividerThickness: 0.5,
                            columns: const [
                      DataColumn(
                        label: Text(
                          'ID',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'User Info',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Balance',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: controller.users.map((user) {
                      final bool isBlocked = user['status'] == 'BLOCKED';

                      return DataRow(
                        cells: [
                          DataCell(Text("#${user['id']}")),

                          // Kolom User Info (Avatar + Nama + Email)
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AdminColors.primary
                                      .withOpacity(0.1),
                                  child: Text(
                                    user['name'].toString().isNotEmpty
                                        ? user['name'][0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: AdminColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      user['email'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AdminColors.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          DataCell(
                            Text(
                              "Rp ${user['balance']}",
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),

                          // Kolom Status Badge
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isBlocked
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isBlocked ? "Blocked" : "Active",
                                style: TextStyle(
                                  color: isBlocked ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                          // Kolom Aksi
                          DataCell(
                            Row(
                              children: [
                                // Block/Unblock
                                IconButton(
                                  icon: Icon(
                                    isBlocked ? Icons.lock_open : Icons.block,
                                    color: isBlocked
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  tooltip: isBlocked
                                      ? "Unblock User"
                                      : "Block User",
                                  onPressed: () => controller.toggleBlockUser(
                                    int.parse(user['id'].toString()),
                                    isBlocked,
                                  ),
                                ),
                                // Delete
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  tooltip: "Hapus User",
                                  onPressed: () => controller.deleteUser(
                                    int.parse(user['id'].toString()),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                    }).toList(),
                  ),
                        ),
                      ),
                    );
                  }
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  // Widget Helper: Kartu Statistik
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AdminColors.textGrey,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog Tambah User
  void _showAddUserDialog(BuildContext context) {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final passC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah User Baru"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: "Nama Lengkap"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailC,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passC,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              controller.addUser(nameC.text, emailC.text, passC.text);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }
}
