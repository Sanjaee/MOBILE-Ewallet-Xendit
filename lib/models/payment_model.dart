class PaymentResponse {
  final bool success;
  final String referenceId;
  final String status;
  final String paymentId;
  final String? checkoutUrl;
  final bool isRedirectRequired;
  final String? qrString;

  PaymentResponse({
    required this.success,
    required this.referenceId,
    required this.status,
    required this.paymentId,
    this.checkoutUrl,
    required this.isRedirectRequired,
    this.qrString,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return PaymentResponse(
      success: json['success'] ?? true,
      referenceId: data['referenceId'] ?? '',
      status: data['status'] ?? '',
      paymentId: data['paymentId'] ?? '',
      checkoutUrl: data['checkoutUrl'],
      isRedirectRequired: data['isRedirectRequired'] ?? false,
      qrString: data['qrString'],
    );
  }
}

class PaymentStatus {
  final String status;
  final double amount;
  final String referenceId;
  final double currentBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentStatus({
    required this.status,
    required this.amount,
    required this.referenceId,
    required this.currentBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      status: json['status'],
      amount: json['amount'].toDouble(),
      referenceId: json['referenceId'],
      currentBalance: json['currentBalance'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}