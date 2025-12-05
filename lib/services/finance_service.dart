import 'package:get/get.dart';
import 'api_service.dart';
import '../core/values/api_constants.dart';
import '../models/transaction_model.dart';

class FinanceService extends GetxService {
  final ApiService _api = Get.find();

  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await _api.get(ApiConstants.finance);
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        return data.map((e) => TransactionModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      // print("Error fetch transactions: $e");
      return [];
    }
  }

  Future<bool> addTransaction({
    required String title,
    required double amount,
    required String type, // INCOME / EXPENSE
    required String category,
    required String date, // YYYY-MM-DD
  }) async {
    try {
      final response = await _api.post(ApiConstants.finance, data: {
        'title': title,
        'amount': amount,
        'type': type,
        'category': category,
        'date': date,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}