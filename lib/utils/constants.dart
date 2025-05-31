import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}

class AppSizes {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
}

class ApiEndpoints {
  static const String baseUrl = 'https://be-ewallet-xendit-xkzb.vercel.app';
}

class PaymentMethods {
  static const Map<String, String> eWallets = {
    'OVO': 'ID_OVO',
    'GoPay': 'ID_GOPAY',
    'Dana': 'ID_DANA',
    'LinkAja': 'ID_LINKAJA',
    'ShopeePay': 'ID_SHOPEEPAY',
  };

  static const Map<String, String> banks = {
    'BCA': 'BCA',
    'BNI': 'BNI',
    'BRI': 'BRI',
    'Mandiri': 'MANDIRI',
    'CIMB': 'CIMB',
  };
}
