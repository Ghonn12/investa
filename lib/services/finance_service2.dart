import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../core/values/api_constants.dart';
import '../models/transaction_model_v2.dart';
import '../models/category_model.dart';
import '../models/wallet_model.dart';

class FinanceService2 extends GetxService {
  Map<String, String> get headers {
    final token = Get.find<AuthService>().token;
    return {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
  }

  // --- DASHBOARD ---
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/dashboard/summary'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'];
      }
    } catch (e) {
      print("Error Dashboard: $e");
    }
    return {};
  }

  // --- TRANSACTIONS ---
  Future<List<TransactionModelV2>> getTransactions() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.transaksi),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return (json['data'] as List)
            .map((e) => TransactionModelV2.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error Trx: $e");
      return [];
    }
  }

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
        Uri.parse(ApiConstants.transaksi),
        headers: headers,
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
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.transaksi}/$id'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- WALLETS ---
  Future<List<WalletModel>> getWallets() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.wallet),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return (json['data'] as List)
            .map((e) => WalletModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      print("Error Wal: $e");
    }
    return [];
  }

  Future<bool> addWallet(String name, String type) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.wallet),
        headers: headers,
        body: {'nama_wallet': name, 'tipe_wallet': type},
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteWallet(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.wallet}/$id'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- CATEGORIES ---
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.kategori),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return (json['data'] as List)
            .map((e) => CategoryModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      print("Error Cat: $e");
    }
    return [];
  }

  Future<bool> addCategory(String name, String type) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.kategori),
        headers: headers,
        body: {'nama_kategori': name, 'tipe': type},
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.kategori}/$id'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
