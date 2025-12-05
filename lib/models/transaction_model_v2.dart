class TransactionModelV2 {
  final int id;
  final String deskripsi;
  final double amount;
  final String tipe;
  final String date;
  final String kategoriNama;
  final String walletNama;

  TransactionModelV2({
    required this.id, required this.deskripsi, required this.amount,
    required this.tipe, required this.date,
    required this.kategoriNama, required this.walletNama
  });

  factory TransactionModelV2.fromJson(Map<String, dynamic> json) {
    return TransactionModelV2(
      id: int.parse(json['id'].toString()),
      deskripsi: json['deskripsi'] ?? json['title'] ?? '',
      amount: double.parse(json['amount'].toString()),
      tipe: json['type'],
      date: json['date'],
      kategoriNama: json['nama_kategori'] ?? '-',
      walletNama: json['nama_wallet'] ?? '-',
    );
  }
}