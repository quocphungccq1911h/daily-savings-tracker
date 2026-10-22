import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/hometown_trip.dart';
import '../../models/savings_entry.dart';
import '../../models/wishlist_goal.dart';
import '../core/constants/app_constants.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';

class SavingsState {
  final List<SavingsEntry> entries;
  final List<WishlistGoal> wishlistGoals;
  final List<HometownTrip> hometownTrips;
  final double dailyGoal;
  final bool isLoading;

  SavingsState({
    required this.entries,
    required this.wishlistGoals,
    this.hometownTrips = const [],
    this.dailyGoal = AppConstants.defaultDailyGoal,
    this.isLoading = false,
  });

  SavingsState copyWith({
    List<SavingsEntry>? entries,
    List<WishlistGoal>? wishlistGoals,
    List<HometownTrip>? hometownTrips,
    double? dailyGoal,
    bool? isLoading,
  }) {
    return SavingsState(
      entries: entries ?? this.entries,
      wishlistGoals: wishlistGoals ?? this.wishlistGoals,
      hometownTrips: hometownTrips ?? this.hometownTrips,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // --- CORE COMPUTED PROPERTIES ---

  static bool isGrabCategory(String cat) {
    final lower = cat.toLowerCase();
    return lower.contains('grab') || lower.contains('chạy xe');
  }

  /// Filter entries belonging to Grab
  List<SavingsEntry> get grabEntries =>
      entries.where((e) => isGrabCategory(e.category)).toList();

  /// Filter entries belonging to Other sources (Salary, Bonus, etc.)
  List<SavingsEntry> get otherEntries =>
      entries.where((e) => !isGrabCategory(e.category)).toList();

  /// Calculates Grab streak count (consecutive days meeting target via Grab)
  int get grabStreakCount => _calculateStreakForEntries(grabEntries);

  /// Calculates total streak count (all entries)
  int get streakCount => _calculateStreakForEntries(entries);

  int _calculateStreakForEntries(List<SavingsEntry> listEntries) {
    if (listEntries.isEmpty) return 0;
    final Map<String, double> dayTotals = {};
    for (var e in listEntries) {
      dayTotals[e.date] = (dayTotals[e.date] ?? 0.0) + e.amount;
    }

    int streak = 0;
    DateTime checkDate = DateTime.now();

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

  /// Calculates total lifetime savings for Grab
  double get grabLifetimeTotal =>
      grabEntries.fold(0.0, (sum, item) => sum + item.amount);

  /// Calculates total lifetime savings for Other sources
  double get otherLifetimeTotal =>
      otherEntries.fold(0.0, (sum, item) => sum + item.amount);

  /// Calculates total lifetime savings for All sources
  double get lifetimeTotal =>
      entries.fold(0.0, (sum, item) => sum + item.amount);

  /// Calculates current month Grab savings
  double get currentMonthGrabTotal {
    final now = DateTime.now();
    final monthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return grabEntries
        .where((e) => e.date.startsWith(monthPrefix))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Calculates current month Other savings
  double get currentMonthOtherTotal {
    final now = DateTime.now();
    final monthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return otherEntries
        .where((e) => e.date.startsWith(monthPrefix))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Calculates current month total savings
  double get currentMonthTotal {
    final now = DateTime.now();
    final monthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return entries
        .where((e) => e.date.startsWith(monthPrefix))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // --- HOMETOWN TRIPS COMPUTED PROPERTIES ---

  /// Danh sách chuyến đi sắp xếp:
  /// 1. Đang ở quê (ongoing) lên đầu tiên
  /// 2. Các chuyến sắp tới (chưa về: today, tomorrow, upcoming) xếp theo ngày tăng dần (gần nhất lên trước)
  /// 3. Các chuyến đã hoàn thành (completed) xếp xuống dưới cùng, theo ngày giảm dần
  List<HometownTrip> get sortedHometownTrips {
    final list = List<HometownTrip>.from(hometownTrips);
    list.sort((a, b) {
      final rankA = _statusRank(a.status);
      final rankB = _statusRank(b.status);
      if (rankA != rankB) {
        return rankA.compareTo(rankB);
      }
      if (rankA < 2) {
        return a.startDate.compareTo(b.startDate);
      }
      return b.startDate.compareTo(a.startDate);
    });
    return list;
  }

  static int _statusRank(HometownTripStatus status) {
    switch (status) {
      case HometownTripStatus.ongoing:
        return 0;
      case HometownTripStatus.today:
      case HometownTripStatus.tomorrow:
      case HometownTripStatus.upcoming:
        return 1;
      case HometownTripStatus.completed:
        return 2;
    }
  }

  /// Chuyến đi đang diễn ra (nếu có)
  HometownTrip? get activeHometownTrip {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final trip in sortedHometownTrips) {
      final start = DateTime(trip.startDateTime.year, trip.startDateTime.month, trip.startDateTime.day);
      final end = DateTime(trip.endDateTime.year, trip.endDateTime.month, trip.endDateTime.day);
      if (!today.isBefore(start) && !today.isAfter(end)) {
        return trip;
      }
    }
    return null;
  }

  /// Chuyến đi sắp tới gần nhất (chưa bắt đầu)
  HometownTrip? get nearestUpcomingHometownTrip {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final trip in sortedHometownTrips) {
      final start = DateTime(trip.startDateTime.year, trip.startDateTime.month, trip.startDateTime.day);
      if (start.isAfter(today)) {
        return trip;
      }
    }
    return null;
  }

  /// Chuyến đi để hiển thị trên Banner: ưu tiên chuyến đang diễn ra, sau đó đến chuyến sắp tới gần nhất
  HometownTrip? get bannerHometownTrip =>
      activeHometownTrip ?? nearestUpcomingHometownTrip;

  /// Số lần đã về quê trong năm (mặc định năm hiện tại)
  int completedTripsInYear([int? year]) {
    final targetYear = year ?? DateTime.now().year;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return hometownTrips.where((t) {
      if (t.startDateTime.year != targetYear) return false;
      final end = DateTime(t.endDateTime.year, t.endDateTime.month, t.endDateTime.day);
      return end.isBefore(today);
    }).length;
  }

  /// Tổng số ngày ở quê trong năm
  int totalDaysHomeInYear([int? year]) {
    final targetYear = year ?? DateTime.now().year;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return hometownTrips.where((t) {
      if (t.startDateTime.year != targetYear) return false;
      final end = DateTime(t.endDateTime.year, t.endDateTime.month, t.endDateTime.day);
      return end.isBefore(today);
    }).fold(0, (sum, t) => sum + t.durationInDays);
  }

  /// Số chuyến đi kế hoạch sắp tới trong năm
  int upcomingTripsInYear([int? year]) {
    final targetYear = year ?? DateTime.now().year;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return hometownTrips.where((t) {
      if (t.startDateTime.year != targetYear) return false;
      final start = DateTime(t.startDateTime.year, t.startDateTime.month, t.startDateTime.day);
      return !start.isBefore(today);
    }).length;
  }
}

class SavingsNotifier extends StateNotifier<SavingsState> {
  RealtimeChannel? _realtimeChannel;

  SavingsNotifier() : super(SavingsState(entries: [], wishlistGoals: [])) {
    _loadInitialData();
    _initRealtimeSubscription();
  }

  void _initRealtimeSubscription() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = SupabaseService.subscribeToRealtimeChanges(() {
      refreshFromCloud();
    });
  }

  Future<void> _loadInitialData() async {
    final localEntries = LocalStorageService.getEntries();
    final localGoals = LocalStorageService.getWishlistGoals();
    final localTrips = LocalStorageService.getHometownTrips();
    final savedGoal = LocalStorageService.getDailyGoal();
    state = state.copyWith(
      entries: localEntries,
      wishlistGoals: localGoals,
      hometownTrips: localTrips,
      dailyGoal: savedGoal,
    );

    await refreshFromCloud();
  }

  void _syncNotificationReminder() {
    if (kIsWeb) return;
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final hasSavedToday = state.entries.any((e) => e.date == todayStr && e.amount > 0);
      NotificationService().syncDailyReminderWithSavedStatus(hasSavedToday: hasSavedToday);
    } catch (e) {
      debugPrint('Sync notification error: $e');
    }
  }

  /// Tải lại toàn bộ dữ liệu mới nhất từ Supabase Cloud API
  Future<void> refreshFromCloud() async {
    try {
      final cloudEntries = await SupabaseService.fetchEntries();
      final cloudTrips = await SupabaseService.fetchHometownTripsFromCloud();
      state = state.copyWith(
        entries: cloudEntries,
        hometownTrips: cloudTrips,
      );
      
      // Xóa và ghi đè cache cũ bằng dữ liệu mới nhất từ cloud
      await LocalStorageService.clearAllUserData();
      for (var e in cloudEntries) {
        await LocalStorageService.saveEntry(e);
      }
      await LocalStorageService.saveAllHometownTrips(cloudTrips);
      _syncNotificationReminder();
    } catch (_) {}
  }

  /// Xóa sạch dữ liệu trong bộ nhớ và cache khi Đăng xuất
  Future<void> clearOnLogout() async {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    await LocalStorageService.clearAllUserData();
    state = SavingsState(
      entries: [],
      wishlistGoals: state.wishlistGoals,
      hometownTrips: [],
      dailyGoal: state.dailyGoal,
    );
  }

  /// Đăng ký lại Realtime khi Đăng nhập lại
  void rebindRealtimeOnLogin() {
    refreshFromCloud();
    _initRealtimeSubscription();
  }

  void updateDailyGoal(double newGoal) {
    state = state.copyWith(dailyGoal: newGoal);
    LocalStorageService.saveDailyGoal(newGoal);
  }

  Future<void> addOrUpdateEntry(SavingsEntry entry) async {
    final List<SavingsEntry> updated = List.from(state.entries);
    final idx = updated.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      updated[idx] = entry;
    } else {
      updated.insert(0, entry);
    }
    updated.sort((a, b) => b.date.compareTo(a.date));
    state = state.copyWith(entries: updated);

    await LocalStorageService.saveEntry(entry);
    await SupabaseService.syncSaveEntry(entry);
    _syncNotificationReminder();

    try {
      final cloudEntries = await SupabaseService.fetchEntries();
      if (cloudEntries.isNotEmpty) {
        state = state.copyWith(entries: cloudEntries);
        _syncNotificationReminder();
      }
    } catch (_) {}
  }

  Future<void> deleteEntry(String id) async {
    final updated = state.entries.where((e) => e.id != id).toList();
    state = state.copyWith(entries: updated);
    await LocalStorageService.deleteEntry(id);
    await SupabaseService.syncDeleteEntry(id);
    _syncNotificationReminder();

    try {
      final cloudEntries = await SupabaseService.fetchEntries();
      state = state.copyWith(entries: cloudEntries);
      _syncNotificationReminder();
    } catch (_) {}
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

  Future<void> resetDefaultWishlistGoals() async {
    await LocalStorageService.resetDefaultWishlistGoals();
    final refreshed = LocalStorageService.getWishlistGoals();
    state = state.copyWith(wishlistGoals: refreshed);
  }

  // --- HOMETOWN TRIPS ACTIONS ---

  Future<void> addOrUpdateHometownTrip(HometownTrip trip) async {
    final List<HometownTrip> updated = List.from(state.hometownTrips);
    final idx = updated.indexWhere((t) => t.id == trip.id);
    if (idx != -1) {
      updated[idx] = trip;
    } else {
      updated.add(trip);
    }
    state = state.copyWith(hometownTrips: updated);

    await LocalStorageService.saveHometownTrip(trip);
    await SupabaseService.syncSaveHometownTrip(trip);

    try {
      final cloudTrips = await SupabaseService.fetchHometownTripsFromCloud();
      if (cloudTrips.isNotEmpty) {
        state = state.copyWith(hometownTrips: cloudTrips);
        await LocalStorageService.saveAllHometownTrips(cloudTrips);
      }
    } catch (_) {}
  }

  Future<void> deleteHometownTrip(String id) async {
    final updated = state.hometownTrips.where((t) => t.id != id).toList();
    state = state.copyWith(hometownTrips: updated);

    await LocalStorageService.deleteHometownTrip(id);
    await SupabaseService.syncDeleteHometownTrip(id);

    try {
      final cloudTrips = await SupabaseService.fetchHometownTripsFromCloud();
      state = state.copyWith(hometownTrips: cloudTrips);
      await LocalStorageService.saveAllHometownTrips(cloudTrips);
    } catch (_) {}
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}

final savingsProvider =
    StateNotifierProvider<SavingsNotifier, SavingsState>((ref) {
  return SavingsNotifier();
});
