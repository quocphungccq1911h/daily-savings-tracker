class SavingsEntry {
  final String id;
  final String date; // YYYY-MM-DD
  final double amount;
  final String category;
  final String note;

  SavingsEntry({
    required this.id,
    required this.date,
    required this.amount,
    required this.category,
    required this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'entry_date': date,
        'amount': amount,
        'category': category,
        'note': note,
      };

  factory SavingsEntry.fromMap(Map<String, dynamic> map) {
    final String rawNote = map['note'] ?? '';
    String cat = map['category'] ?? '';
    String cleanNote = rawNote;

    if (cat.isEmpty) {
      final match = RegExp(r'^\[(.*?)\]').firstMatch(rawNote);
      if (match != null && match.group(1) != null) {
        cat = match.group(1)!;
        cleanNote = rawNote.replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
      } else {
        cat = 'Khác';
      }
    }

    return SavingsEntry(
      id: map['id'] ?? '',
      date: map['entry_date'] ?? map['date'] ?? '',
      amount: ((map['amount'] ?? 0.0) as num).toDouble(),
      category: cat,
      note: cleanNote,
    );
  }

  SavingsEntry copyWith({
    String? id,
    String? date,
    double? amount,
    String? category,
    String? note,
  }) {
    return SavingsEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
    );
  }
}
