import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/finance2_controller.dart';

class AddSheet extends GetView<Finance2Controller> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              "Catat Transaksi",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // 1. Tipe Transaksi
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _typeBtn("Pengeluaran", Colors.red),
                  SizedBox(width: 10),
                  _typeBtn("Pemasukan", Colors.green),
                  SizedBox(width: 10),
                  _typeBtn("Penarikan", Colors.orange),
                ],
              ),
            ),
            SizedBox(height: 20),

            // 2. Input Nominal
            TextField(
              controller: controller.amountC,
              decoration: InputDecoration(
                labelText: "Nominal (Rp)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixText: "Rp ",
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),

            // 3. Deskripsi
            TextField(
              controller: controller.deskripsiC,
              decoration: InputDecoration(
                labelText: "Deskripsi",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.note),
              ),
            ),
            SizedBox(height: 15),

            // 4. Wallet & Kategori
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: controller.selectedType.value == 'Penarikan'
                            ? "Dari Wallet"
                            : "Wallet",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      value: controller.selectedWalletId.value,
                      items: controller
                          .filteredWallets // Use Filtered Wallets
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(
                                e.namaWallet,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => controller.selectedWalletId.value = v,
                    ),
                  ),
                ),
                // Hide Category if Penarikan
                Obx(() {
                  if (controller.selectedType.value == 'Penarikan')
                    return SizedBox.shrink();
                  return Row(
                    children: [
                      SizedBox(width: 10),
                      SizedBox(
                        width:
                            (MediaQuery.of(context).size.width - 48) /
                            2, // Half width
                        child: DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: "Kategori",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          value: controller.selectedCatId.value,
                          items: controller.filteredCat
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(
                                    e.namaKategori,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => controller.selectedCatId.value = v,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            SizedBox(height: 15),

            // 5. Tanggal
            Obx(
              () => InkWell(
                onTap: () async {
                  var d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) controller.selectedDate.value = d;
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey),
                      SizedBox(width: 10),
                      Text(
                        DateFormat(
                          'dd MMMM yyyy',
                          'id_ID',
                        ).format(controller.selectedDate.value),
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: controller.save,
                child: Text(
                  "SIMPAN TRANSAKSI",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _typeBtn(String type, Color color) {
    return Obx(() {
      bool isSelected = controller.selectedType.value == type;
      return GestureDetector(
        onTap: () {
          controller.selectedType.value = type;
          controller.selectedCatId.value =
              null; // Reset kategori saat ganti tipe
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? color : Colors.grey),
          ),
          child: Text(
            type,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    });
  }
}
