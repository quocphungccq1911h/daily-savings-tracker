import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/savings_entry.dart';
import '../../models/wishlist_goal.dart';
import '../core/constants/app_constants.dart';
import '../services/local_storage_service.dart';
import '../services/supabase_service.dart';

class SavingsState {
  final List<SavingsEntry> entries;
  final List<WishlistGoal> wishlistGoals;
  final double dailyGoal;
  final bool isLoading;

  SavingsState({
    required this.entries,
    required this.wishlistGoals,
    this.dailyGoal = AppConstants.defaultDailyGoal,
    this.isLoading = false,
  });

  SavingsState copyWith({
    List<SavingsEntry>? entries,
    List<WishlistGoal>? wishlistGoals,
    double? dailyGoal,
    bool? isLoading,
  }) {
    return SavingsState(
      entries: entries ?? this.entries,
      wishlistGoals: wishlistGoals ?? this.wishlistGoals,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // --- CORE COMPUTED PROPERTIES ---

  /// Calculates current streak count (consecutive days meeting target)
  int get streakCount {
    if (entries.isEmpty) return 0;
    final Map<String, double> dayTotals = {};
    for (var e in entries) {
      dayTotals[e.date] = (dayTotals[e.date] ?? 0.0) + e.amount;
    }

    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    String formatDateKey(DateTime d) =>
        '${d.year}-${String.fromCharCodes([d.month]).padLeft(2, '0')}-${String.fromCharCodes([d.day]).padLeft(2, '0')}';

    final String todayKey =
        '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

    if ((dayTotals[todayKey] ?? 0.0) < dailyGoal) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (true) {
      final key =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if ((dayTotals[key] ?? 0.0) >= dailyGoal) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// Calculates total lifetime savings
  double get lifetimeTotal =>
      entries.fold(0.0, (sum, item) => sum + item.amount);

  /// Calculates current month total savings
  double get currentMonthTotal {
    final now = DateTime.now();
    final monthPrefix =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return entries
        .where((e) => e.date.startsWith(monthPrefix))
        .fold(0.0, (sum, e) => sum + e.amount);
  }
}

class SavingsNotifier extends StateNotifier<SavingsState> {
  SavingsNotifier()
      : super(SavingsState(entries: [], wishlistGoals: [])) {
    _loadInitialData();
  }

  void _loadInitialData() {
    final localEntries = LocalStorageService.getEntries();
    final localGoals = LocalStorageService.getWishlistGoals();
    state = state.copyWith(entries: localEntries, wishlistGoals: localGoals);
  }

  Future<void> addOrUpdateEntry(SavingsEntry entry) async {
    final List<SavingsEntry> updated = List.from(state.entries);
    final idx = updated.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      updated[idx] = entry;
    } else {
      updated.add(entry);
    }
    state = state.copyWith(entries: updated);
    await LocalStorageService.saveEntry(entry);
    await SupabaseService.syncSaveEntry(entry);
  }

  Future<void> deleteEntry(String id) async {
    final updated = state.entries.where((e) => e.id != id).toList();
    state = state.copyWith(entries: updated);
    await LocalStorageService.deleteEntry(id);
  }

  Future<void> addOrUpdateGoal(WishlistGoal goal) async {
    final List<WishlistGoal> updated = List.from(state.wishlistGoals);
    final idx = updated.indexWhere((g) => g.id == goal.id);
    if (idx != -1) {
      updated[idx] = goal;
    } else {
      updated.add(goal);
    }
    state = state.copyWith(wishlistGoals: updated);
    await LocalStorageService.saveWishlistGoal(goal);
  }

  Future<void> deleteGoal(String id) async {
    final updated = state.wishlistGoals.where((g) => g.id != id).toList();
    state = state.copyWith(wishlistGoals: updated);
    await LocalStorageService.deleteWishlistGoal(id);
  }
}

final savingsProvider =
    StateNotifierProvider<SavingsNotifier, SavingsState>((ref) {
  return SavingsNotifier();
});
