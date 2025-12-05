class WalletModel {
  final int id;
  final String namaWallet;
  final String tipeWallet;

  WalletModel({required this.id, required this.namaWallet, required this.tipeWallet});

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: int.parse(json['id'].toString()),
      namaWallet: json['nama_wallet'],
      tipeWallet: json['tipe_wallet'],
    );
  }
}