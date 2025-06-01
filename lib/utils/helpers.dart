import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class Helpers {
  static String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  static String formatDate(DateTime date) {
    // Convert UTC to local time
    final localDate = date.toLocal();
    return DateFormat('dd MMM yyyy, HH:mm').format(localDate);
  }

  static void showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhoneNumber(String phone) {
    return RegExp(r'^[\+]?[1-9][\d]{0,15}$').hasMatch(phone);
  }

  static String getTransactionTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'TOPUP':
        return '💰';
      case 'TRANSFER':
        return '📤';
      case 'WITHDRAW':
        return '🏦';
      case 'FEE':
        return '💸';
      default:
        return '💳';
    }
  }

  static Color getTransactionColor(String type) {
    switch (type.toUpperCase()) {
      case 'TOPUP':
        return Colors.green;
      case 'TRANSFER':
        return Colors.orange;
      case 'WITHDRAW':
        return Colors.red;
      case 'FEE':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
