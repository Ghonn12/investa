import 'package:intl/intl.dart';

class CurrencyFormat {
  static String toIdr(dynamic number, {int decimalDigits = 0}) {
    NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: decimalDigits,
    );
    return currencyFormatter.format(number);
  }

  static String toIdrCompact(dynamic number) {
    // Untuk format singkatan: 1.2M, 100K (Opsional)
    return NumberFormat.compactCurrency(
        locale: 'id_ID',
        symbol: 'Rp '
    ).format(number);
  }
}