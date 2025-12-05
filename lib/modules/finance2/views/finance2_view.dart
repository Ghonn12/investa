import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/finance2_controller.dart';
import 'add_sheet.dart';
import 'manage_category_view.dart';
import 'manage_wallet_view.dart';
import 'finance_dashboard_view.dart';

class Finance2View extends StatelessWidget {
  final controller = Get.put(Finance2Controller());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Finance Sakuku"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'cat') Get.to(() => ManageCategoryView());
              if (value == 'wal') Get.to(() => ManageWalletView());
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'cat', child: Text("Manajemen Kategori")),
              PopupMenuItem(value: 'wal', child: Text("Manajemen Wallet")),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[800],
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () => Get.bottomSheet(AddSheet(), isScrollControlled: true),
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.loadData(),
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              // 1. Dashboard Section
              SliverToBoxAdapter(child: FinanceDashboardView()),

              // 2. History Header with Search & Filter
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Riwayat Transaksi",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 10),
                      // Search Bar
                      TextField(
                        onChanged: (v) => controller.searchText.value = v,
                        decoration: InputDecoration(
                          hintText: "Cari transaksi...",
                          prefixIcon: Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      SizedBox(height: 10),
                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ["Semua", "1 Bulan", "7 Hari", "Hari Ini"]
                              .map((filter) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Obx(() {
                                    bool isSelected =
                                        controller.filterDate.value == filter;
                                    return ChoiceChip(
                                      label: Text(filter),
                                      selected: isSelected,
                                      onSelected: (val) {
                                        controller.filterDate.value = filter;
                                      },
                                      selectedColor: Colors.blue[100],
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.blue[800]
                                            : Colors.black,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    );
                                  }),
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. History List
              SliverPadding(
                padding: EdgeInsets.only(bottom: 80, top: 10),
                sliver: Obx(
                  () => SliverList(
                    delegate: SliverChildBuilderDelegate((ctx, i) {
                      var trx = controller.filteredTransactions[i];

                      // Detect Penarikan Strict Logic (using (Source) tag)
                      bool isPenarikan = trx.deskripsi.contains('(Source)');

                      String title = controller.getDisplayTitle(trx);

                      // Custom Rendering for Penarikan
                      if (isPenarikan) {
                        return Dismissible(
                          key: Key(trx.id.toString()),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async =>
                              false, // Disable delete for now
                          background: Container(color: Colors.red),
                          child: Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.purple.withOpacity(0.1),
                                child: Icon(
                                  Icons.swap_horiz,
                                  color: Colors.purple,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                "Penarikan",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "${trx.walletNama} -> Cash\n${trx.date}",
                                style: TextStyle(fontSize: 12),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "- Rp ${trx.amount}",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "+ Rp ${trx.amount}",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      // Generic Color Logic
                      Color amountColor = Colors.black;
                      IconData icon = Icons.money;

                      if (trx.tipe == 'Pemasukan' || trx.tipe == 'INCOME') {
                        amountColor = Colors.green;
                        icon = Icons.arrow_downward;
                      } else if (trx.tipe == 'Pengeluaran' ||
                          trx.tipe == 'EXPENSE') {
                        amountColor = Colors.red;
                        icon = Icons.arrow_upward;
                      }

                      return Dismissible(
                        key: Key(trx.id.toString()),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await Get.dialog(
                            AlertDialog(
                              title: Text("Hapus Transaksi?"),
                              content: Text("Data ini akan dihapus permanen."),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(result: false),
                                  child: Text("Batal"),
                                ),
                                TextButton(
                                  onPressed: () => Get.back(result: true),
                                  child: Text("Hapus"),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) => controller.delete(trx.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: amountColor.withOpacity(0.1),
                              child: Icon(icon, color: amountColor, size: 20),
                            ),
                            title: Text(
                              title,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "${trx.kategoriNama} • ${trx.walletNama}\n${trx.date}",
                              style: TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              "Rp ${trx.amount}",
                              style: TextStyle(
                                color: amountColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: controller.filteredTransactions.length),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
