class Transaction {
  final String id;
  final String userId; 
  final String? recipientId; 
  final String type;
  final double amount;
  final String status;
  final String? referenceId;
  final String? xenditPaymentRequestId; 
  final bool adminWithdrawn; 
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    required this.userId,
    this.recipientId,
    required this.type,
    required this.amount,
    required this.status,
    this.referenceId,
    this.xenditPaymentRequestId,
    this.adminWithdrawn = false,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    try {
      print('🔧 Parsing transaction JSON: $json');

      return Transaction(
        id: json['id']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        recipientId: json['recipientId']?.toString(),
        type: json['type']?.toString() ?? '',
        amount: _parseDouble(json['amount']),
        status: json['status']?.toString() ?? '',
        referenceId: json['referenceId']?.toString(),
        xenditPaymentRequestId: json['xenditPaymentRequestId']?.toString(),
        adminWithdrawn: json['adminWithdrawn'] ?? false,
        description: json['description']?.toString(),
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
      );
    } catch (e) {
      print('❌ Error parsing transaction: $e');
      print('📄 JSON data: $json');
      rethrow;
    }
  }

  // Helper method to safely parse double values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Helper method to safely parse DateTime
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'recipientId': recipientId,
      'type': type,
      'amount': amount,
      'status': status,
      'referenceId': referenceId,
      'xenditPaymentRequestId': xenditPaymentRequestId,
      'adminWithdrawn': adminWithdrawn,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Transaction(id: $id, userId: $userId, type: $type, amount: $amount, status: $status, createdAt: $createdAt)';
  }
}
