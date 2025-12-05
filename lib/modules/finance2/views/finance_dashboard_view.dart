import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/finance2_controller.dart';
import 'package:intl/intl.dart';

class FinanceDashboardView extends GetView<Finance2Controller> {
  final currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Pie Chart Pengeluaran Bulan Ini
          Text(
            "Pengeluaran Bulan Ini",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1.5,
            child: Obx(() {
              if (controller.pieChartData.isEmpty) {
                return Center(child: Text("Belum ada data pengeluaran"));
              }
              return PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: controller.pieChartData.map((data) {
                    final value =
                        double.tryParse(data['total'].toString()) ?? 0;
                    final name = data['nama_kategori'];
                    return PieChartSectionData(
                      color:
                          Colors.primaries[controller.pieChartData.indexOf(
                                data,
                              ) %
                              Colors.primaries.length],
                      value: value,
                      title: '$name',
                      radius: 50,
                      titleStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
          ),

          SizedBox(height: 30),

          // 2. Info Saldo
          Text(
            "Total Keuangan",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _balanceCard(
                  "Rekening",
                  controller.totalRekening,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _balanceCard("Cash", controller.totalCash, Colors.green),
              ),
            ],
          ),

          SizedBox(height: 30),

          Text(
            "Riwayat Terakhir",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // List Transaksi akan ditampilkan di parent view atau section bawah
        ],
      ),
    );
  }

  Widget _balanceCard(String title, RxDouble value, Color color) {
    return Obx(
      () => Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              currency.format(value.value),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
