import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../models/wallet_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model_v2.dart';
import 'auth_service.dart'; // Sesuaikan import auth service temanmu

class FinanceService extends GetxService {
  final String baseUrl = "http://localhost:8080/api"; // Sesuaikan IP
  
  // Helper Header
  Map<String, String> get headers {
    final token = Get.find<AuthService>().token; // Ambil token dari service auth temanmu
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  // Get Wallets
  Future<List<WalletModel>> getWallets() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/wallet'), headers: headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return (json['data'] as List).map((e) => WalletModel.fromJson(e)).toList();
      }
    } catch (e) { print(e); }
    return [];
  }

  // Get Categories
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/kategori'), headers: headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return (json['data'] as List).map((e) => CategoryModel.fromJson(e)).toList();
      }
    } catch (e) { print(e); }
    return [];
  }

  // Get Transactions
  Future<List<TransactionModelV2>> getTransactions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/transaksi'), headers: headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return (json['data'] as List).map((e) => TransactionModelV2.fromJson(e)).toList();
      }
    } catch (e) { print(e); }
    return [];
  }

  // Add Transaction
  Future<bool> addTransaction({
    required String deskripsi,
    required double amount,
    required String type,
    required int walletId,
    required int kategoriId,
    required String date,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transaksi'),
        headers: headers, // Header sudah ada Authorization
        body: {
          'deskripsi': deskripsi,
          'amount': amount.toString(),
          'type': type,
          'wallet_id': walletId.toString(),
          'category_id': kategoriId.toString(),
          'date': date,
        },
      );
      return response.statusCode == 201;
    } catch (e) { return false; }
  }

  // Delete Transaction
  Future<bool> deleteTransaction(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/transaksi/$id'), headers: headers);
      return response.statusCode == 200;
    } catch (e) { return false; }
  }
}