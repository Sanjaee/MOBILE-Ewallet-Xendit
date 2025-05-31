class User {
  final String id;
  final String name;
  final String email;
  final String token;
  final String? phoneNumber;
  final double balance;
  final String role;
  final bool isVerified; // Field baru ditambahkan
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.token,
    this.phoneNumber,
    this.balance = 0,
    this.role = 'USER',
    required this.isVerified, // Ditambahkan ke constructor
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      token: json['token'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      balance: (json['balance'] ?? 0).toDouble(),
      role: json['role'] as String? ?? 'USER',
      isVerified: json['isVerified'] as bool? ?? false, // Mengambil nilai isVerified dari JSON
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'token': token,
      'phoneNumber': phoneNumber,
      'balance': balance,
      'role': role,
      'isVerified': isVerified, // Ditambahkan ke method toJson
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
