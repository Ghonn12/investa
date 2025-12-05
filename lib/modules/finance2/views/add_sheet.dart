import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/finance2_controller.dart';

class AddSheet extends GetView<Finance2Controller> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text("Catat Transaksi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            // 1. Tipe
            Obx(() => Row(
              children: [
                _btn("Pemasukan", Colors.green), SizedBox(width: 10),
                _btn("Pengeluaran", Colors.red),
              ],
            )),
            SizedBox(height: 15),
            // 2. Input
            TextField(controller: controller.deskripsiC, decoration: InputDecoration(labelText: "Deskripsi", border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(controller: controller.amountC, decoration: InputDecoration(labelText: "Nominal", border: OutlineInputBorder()), keyboardType: TextInputType.number),
            SizedBox(height: 10),
            // 3. Wallet
            Obx(() => DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: "Wallet", border: OutlineInputBorder()),
              value: controller.selectedWalletId.value,
              items: controller.wallets.map((e) => DropdownMenuItem(value: e.id, child: Text(e.namaWallet))).toList(),
              onChanged: (v) => controller.selectedWalletId.value = v,
            )),
            SizedBox(height: 10),
            // 4. Kategori
            Obx(() => DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: "Kategori", border: OutlineInputBorder()),
              value: controller.selectedCatId.value,
              items: controller.filteredCat.map((e) => DropdownMenuItem(value: e.id, child: Text(e.namaKategori))).toList(),
              onChanged: (v) => controller.selectedCatId.value = v,
            )),
            SizedBox(height: 10),
            // 5. Tanggal
            Obx(() => ListTile(
              title: Text("Tanggal: ${DateFormat('dd MMM yyyy').format(controller.selectedDate.value)}"),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                var d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                if(d != null) controller.selectedDate.value = d;
              },
            )),
            SizedBox(height: 20),
            ElevatedButton(onPressed: controller.save, child: Text("SIMPAN"))
          ],
        ),
      ),
    );
  }

  Widget _btn(String type, Color color) {
    return Expanded(
      child: Obx(() => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: controller.selectedType.value == type ? color : Colors.grey[200],
          foregroundColor: controller.selectedType.value == type ? Colors.white : Colors.black
        ),
        onPressed: () { controller.selectedType.value = type; controller.selectedCatId.value = null; },
        child: Text(type),
      )),
    );
  }
}