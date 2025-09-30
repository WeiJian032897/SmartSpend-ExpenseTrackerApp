class PlannedPaymentModel {
  final String id;
  final String userId;
  final String paymentName;
  final double amount;
  final String account;
  final String category;
  final String paymentType;
  final String payee;
  final String note;
  final DateTime startDate;
  final DateTime? endDate;
  final String repeatType; // 'one-time', 'daily', 'weekly', 'monthly'
  final List<int> selectedDays; // For weekly/monthly repeats
  final bool isManualConfirmation;
  final String currency;
  final bool isActive;

  PlannedPaymentModel({
    required this.id,
    required this.userId,
    required this.paymentName,
    required this.amount,
    required this.account,
    required this.category,
    required this.paymentType,
    required this.payee,
    required this.note,
    required this.startDate,
    this.endDate,
    required this.repeatType,
    required this.selectedDays,
    required this.isManualConfirmation,
    required this.currency,
    this.isActive = true,
  });

  factory PlannedPaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PlannedPaymentModel(
      id: id,
      userId: map['userId'] ?? '',
      paymentName: map['paymentName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      account: map['account'] ?? '',
      category: map['category'] ?? '',
      paymentType: map['paymentType'] ?? 'Cash',
      payee: map['payee'] ?? '',
      note: map['note'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] ?? 0),
      endDate: map['endDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate']) 
          : null,
      repeatType: map['repeatType'] ?? 'one-time',
      selectedDays: List<int>.from(map['selectedDays'] ?? []),
      isManualConfirmation: map['isManualConfirmation'] ?? true,
      currency: map['currency'] ?? 'RM',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'paymentName': paymentName,
      'amount': amount,
      'account': account,
      'category': category,
      'paymentType': paymentType,
      'payee': payee,
      'note': note,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'repeatType': repeatType,
      'selectedDays': selectedDays,
      'isManualConfirmation': isManualConfirmation,
      'currency': currency,
      'isActive': isActive,
    };
  }
}