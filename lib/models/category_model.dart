class CategoryModel {
  final int id;
  final String namaKategori;
  final String tipe;

  CategoryModel({required this.id, required this.namaKategori, required this.tipe});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: int.parse(json['id'].toString()),
      namaKategori: json['nama_kategori'],
      tipe: json['tipe'],
    );
  }
}