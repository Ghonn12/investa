import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/finance2_controller.dart';

class ManageCategoryView extends GetView<Finance2Controller> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Atur Kategori")),
      body: Obx(() {
        if (controller.categories.isEmpty) {
          return Center(child: Text("Belum ada kategori"));
        }
        return ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: controller.categories.length,
          separatorBuilder: (c, i) => Divider(),
          itemBuilder: (ctx, i) {
            var item = controller.categories[i];
            bool isIncome = item.tipe == 'Pemasukan' || item.tipe == 'INCOME';
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isIncome ? Colors.green[100] : Colors.red[100],
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
              title: Text(item.namaKategori),
              subtitle: Text(item.tipe),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.grey),
                onPressed: () => _confirmDelete(item.id),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAddDialog(context),
      ),
    );
  }

  void _confirmDelete(int id) {
    Get.defaultDialog(
      title: "Hapus Kategori?",
      middleText: "Hati-hati, data tidak bisa dikembalikan.",
      textConfirm: "Hapus",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.removeCategory(id);
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameC = TextEditingController();
    final typeC = TextEditingController(text: "Pengeluaran"); // Default

    Get.defaultDialog(
      title: "Tambah Kategori",
      content: Column(
        children: [
          TextField(
            controller: nameC,
            decoration: InputDecoration(labelText: "Nama Kategori"),
          ),
          SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: "Pengeluaran",
            items: [
              "Pemasukan",
              "Pengeluaran",
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => typeC.text = v!,
            decoration: InputDecoration(labelText: "Tipe"),
          ),
        ],
      ),
      textConfirm: "Simpan",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () {
        if (nameC.text.isNotEmpty) {
          controller.addCategory(nameC.text, typeC.text);
        }
      },
    );
  }
}
