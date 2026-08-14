# 📱 03-Flutter Mobile App Specification

## 1. Project Specifications

- **Target Platforms:** iOS 14.0+, Android 7.0+ (API Level 24+)
- **SDK Version:** Flutter 3.22+ / Dart 3.4+
- **Architecture:** Feature-first Clean Architecture with Riverpod 2.x

---

## 2. Pubspec Dependencies Specification (`pubspec.yaml`)

```yaml
name: daily_savings_app
description: "Sổ Tiết Kiệm Daily - Native Flutter Mobile Application"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.5.1
  
  # Backend & Realtime
  supabase_flutter: ^2.5.4
  
  # Offline Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.2.2
  
  # UI & Visualizations
  fl_chart: ^0.68.0
  google_fonts: ^6.2.1
  flutter_animate: ^4.5.0
  
  # Security & Biometrics
  local_auth: ^2.2.0
  
  # Utilities
  intl: ^0.19.0
  uuid: ^4.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.9

flutter:
  uses-material-design: true
  assets:
    - assets/icons/
```

---

## 3. Core Models & State Providers

### `SavingsEntry` Model (`lib/models/savings_entry.dart`)

```dart
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

  factory SavingsEntry.fromMap(Map<String, dynamic> map) => SavingsEntry(
    id: map['id'],
    date: map['entry_date'],
    amount: (map['amount'] as num).toDouble(),
    category: map['category'] ?? 'Grab / Chạy xe',
    note: map['note'] ?? '',
  );
}
```

### `SavingsProvider` State Manager (`lib/providers/savings_provider.dart`)

```dart
final savingsProvider = StateNotifierProvider<SavingsNotifier, SavingsState>((ref) {
  return SavingsNotifier();
});

class SavingsState {
  final List<SavingsEntry> entries;
  final List<WishlistGoal> wishlistGoals;
  final double dailyGoal;
  final bool isLoading;

  SavingsState({
    required this.entries,
    required this.wishlistGoals,
    this.dailyGoal = 150000.0,
    this.isLoading = false,
  });

  int get streakCount => _calculateStreak(entries, dailyGoal);
  double get lifetimeTotal => entries.fold(0, (sum, e) => sum + e.amount);
}
```

---

## 4. Mobile UX & Gesture Specifications

> [!NOTE]
> 1. **Collapsible Form Widget:** Uses `AnimatedCrossFade` to automatically collapse form after saving on mobile.
> 2. **Touch-Drag Threshold:** Implements `RawGestureDetector` with 10px drag threshold to prevent accidental form submissions while scrolling.
> 3. **Swipeable Tab View:** Implements `PageView` linked with a custom `SwipeableTabBar` so users can swipe between Tab 1 (Journal), Tab 2 (Charts), Tab 3 (Badges), and Tab 4 (Wishlist).
