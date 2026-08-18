class ExpenseEntry {
  final String id;
  final String date; // YYYY-MM-DD
  final double amount;
  final String category;
  final String note;

  ExpenseEntry({
    required this.id,
    required this.date,
    required this.amount,
    required this.category,
    required this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'entry_date': date,
        'amount': amount.toInt(),
        'category': category,
        'note': note,
      };

  factory ExpenseEntry.fromMap(Map<String, dynamic> map) {
    return ExpenseEntry(
      id: map['id'] ?? '',
      date: map['entry_date'] ?? map['date'] ?? '',
      amount: ((map['amount'] ?? 0.0) as num).toDouble(),
      category: map['category'] ?? 'Khác',
      note: map['note'] ?? '',
    );
  }

  ExpenseEntry copyWith({
    String? id,
    String? date,
    double? amount,
    String? category,
    String? note,
  }) {
    return ExpenseEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
    );
  }
}
