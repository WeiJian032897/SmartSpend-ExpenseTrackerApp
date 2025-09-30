class AccountModel {
  final String id;
  final String userId;
  final String name;
  final double balance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  AccountModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.balance,
    this.currency = 'RM',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'balance': balance,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map, String id) {
    return AccountModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'RM',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  AccountModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? balance,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}