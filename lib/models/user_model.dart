class UserModel {
  final int id;
  final String name;
  final String email;
  final double balance;
  final String role;
  final String status;
  final String createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.balance,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      role: json['role'] ?? 'USER',
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['created_at'] ?? '',
    );
  }

  // Helper untuk cek status
  bool get isBlocked => status == 'BLOCKED';
}