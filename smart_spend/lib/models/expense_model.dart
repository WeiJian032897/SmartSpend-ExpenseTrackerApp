class ExpenseModel {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String subCategory;
  final String paymentType;
  final String payee;
  final String note;
  final DateTime date;
  final String currency;
  final bool isIncome;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.subCategory,
    required this.paymentType,
    required this.payee,
    required this.note,
    required this.date,
    required this.currency,
    required this.isIncome,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseModel(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      paymentType: map['paymentType'] ?? 'Cash',
      payee: map['payee'] ?? '',
      note: map['note'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      currency: map['currency'] ?? 'RM',
      isIncome: map['isIncome'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'category': category,
      'subCategory': subCategory,
      'paymentType': paymentType,
      'payee': payee,
      'note': note,
      'date': date.millisecondsSinceEpoch,
      'currency': currency,
      'isIncome': isIncome,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? category,
    String? subCategory,
    String? paymentType,
    String? payee,
    String? note,
    DateTime? date,
    String? currency,
    bool? isIncome,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      paymentType: paymentType ?? this.paymentType,
      payee: payee ?? this.payee,
      note: note ?? this.note,
      date: date ?? this.date,
      currency: currency ?? this.currency,
      isIncome: isIncome ?? this.isIncome,
    );
  }
}