enum HometownTripStatus {
  ongoing,
  today,
  tomorrow,
  upcoming,
  completed,
}


class HometownTrip {
  final String id;
  final String title;
  final String startDate; // YYYY-MM-DD
  final String endDate; // YYYY-MM-DD
  final double budget;
  final String note;
  final DateTime? createdAt;

  HometownTrip({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.budget = 0.0,
    this.note = '',
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'start_date': startDate,
        'end_date': endDate,
        'budget': budget.toInt(),
        'note': note,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      };

  factory HometownTrip.fromMap(Map<String, dynamic> map) {
    return HometownTrip(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      startDate: (map['start_date'] ?? map['startDate'] ?? '').toString(),
      endDate: (map['end_date'] ?? map['endDate'] ?? '').toString(),
      budget: ((map['budget'] ?? 0) as num).toDouble(),
      note: map['note']?.toString() ?? '',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }

  HometownTrip copyWith({
    String? id,
    String? title,
    String? startDate,
    String? endDate,
    double? budget,
    String? note,
    DateTime? createdAt,
  }) {
    return HometownTrip(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // --- Helper Computed Properties ---

  DateTime? get parsedStartDate {
    try {
      return DateTime.parse(startDate);
    } catch (_) {
      return null;
    }
  }

  DateTime? get parsedEndDate {
    try {
      return DateTime.parse(endDate);
    } catch (_) {
      return null;
    }
  }

  DateTime get startDateTime => parsedStartDate ?? DateTime.now();
  DateTime get endDateTime => parsedEndDate ?? startDateTime;

  int get durationInDays {
    final s = parsedStartDate;
    final e = parsedEndDate;
    if (s == null || e == null) return 1;
    final sDay = DateTime(s.year, s.month, s.day);
    final eDay = DateTime(e.year, e.month, e.day);
    final diff = eDay.difference(sDay).inDays + 1;
    return diff > 0 ? diff : 1;
  }

  HometownTripStatus get status {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final s = parsedStartDate;
    final e = parsedEndDate;

    if (s == null || e == null) return HometownTripStatus.completed;

    final sDay = DateTime(s.year, s.month, s.day);
    final eDay = DateTime(e.year, e.month, e.day);

    if (today.isBefore(sDay)) {
      final diff = sDay.difference(today).inDays;
      if (diff == 0) return HometownTripStatus.today;
      if (diff == 1) return HometownTripStatus.tomorrow;
      return HometownTripStatus.upcoming;
    } else if (today.isAfter(eDay)) {
      return HometownTripStatus.completed;
    } else {
      return HometownTripStatus.ongoing;
    }
  }

  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final s = parsedStartDate;
    if (s == null) return 0;
    final sDay = DateTime(s.year, s.month, s.day);
    return sDay.difference(today).inDays;
  }

  String get dateMonthText {
    final s = parsedStartDate;
    if (s == null) return 'T--';
    return 'T${s.month}';
  }

  String get dateDayText {
    final s = parsedStartDate;
    if (s == null) return '--';
    return '${s.day}';
  }

  String get formattedDateRange {
    final s = parsedStartDate;
    final e = parsedEndDate;
    if (s == null || e == null) return '$startDate - $endDate';
    final sStr = '${s.day.toString().padLeft(2, '0')}/${s.month.toString().padLeft(2, '0')}';
    final eStr = '${e.day.toString().padLeft(2, '0')}/${e.month.toString().padLeft(2, '0')}/${e.year}';
    return '$sStr - $eStr';
  }
}
