import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/finance2_controller.dart';

class ManageWalletView extends GetView<Finance2Controller> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Atur Wallet")),
      body: Obx(() {
        if (controller.wallets.isEmpty) {
          return Center(child: Text("Belum ada wallet"));
        }
        return ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: controller.wallets.length,
          separatorBuilder: (c, i) => Divider(),
          itemBuilder: (ctx, i) {
            var item = controller.wallets[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Icon(Icons.account_balance_wallet, color: Colors.blue),
              ),
              title: Text(item.namaWallet),
              subtitle: Text(item.tipeWallet),
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
      title: "Hapus Wallet?",
      middleText: "Hati-hati, data tidak bisa dikembalikan.",
      textConfirm: "Hapus",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.removeWallet(id);
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameC = TextEditingController();
    final typeC = TextEditingController(text: "Cash"); // Default

    Get.defaultDialog(
      title: "Tambah Wallet",
      content: Column(
        children: [
          TextField(
            controller: nameC,
            decoration: InputDecoration(labelText: "Nama Wallet"),
          ),
          SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: "Cash",
            items: [
              "Cash",
              "Bank",
              "E-Wallet",
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
          controller.addWallet(nameC.text, typeC.text);
        }
      },
    );
  }
}
