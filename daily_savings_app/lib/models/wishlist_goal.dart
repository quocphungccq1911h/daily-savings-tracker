class WishlistGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double allocatedAmount;
  final String emoji;

  WishlistGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.allocatedAmount = 0.0,
    this.emoji = '🏠',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'target_amount': targetAmount,
        'allocated_amount': allocatedAmount,
        'emoji': emoji,
      };

  factory WishlistGoal.fromMap(Map<String, dynamic> map) => WishlistGoal(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        targetAmount: ((map['target_amount'] ?? map['targetAmount'] ?? 0.0) as num).toDouble(),
        allocatedAmount: ((map['allocated_amount'] ?? map['allocatedAmount'] ?? 0.0) as num).toDouble(),
        emoji: map['emoji'] ?? '🏠',
      );

  WishlistGoal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? allocatedAmount,
    String? emoji,
  }) {
    return WishlistGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      emoji: emoji ?? this.emoji,
    );
  }
}
