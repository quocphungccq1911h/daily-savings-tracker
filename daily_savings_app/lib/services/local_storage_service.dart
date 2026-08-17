import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/savings_entry.dart';
import '../../models/wishlist_goal.dart';
import '../core/constants/app_constants.dart';

class LocalStorageService {
  static const String _entriesBoxName = 'savings_entries_box_v1';
  static const String _wishlistBoxName = 'wishlist_goals_box_v1';
  static const String _settingsBoxName = 'settings_box_v1';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_entriesBoxName);
    await Hive.openBox(_wishlistBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  // Savings Entries
  static List<SavingsEntry> getEntries() {
    final box = Hive.box(_entriesBoxName);
    final List<SavingsEntry> list = [];
    for (var key in box.keys) {
      final String? jsonStr = box.get(key);
      if (jsonStr != null) {
        list.add(SavingsEntry.fromMap(jsonDecode(jsonStr)));
      }
    }
    return list;
  }

  static Future<void> saveEntry(SavingsEntry entry) async {
    final box = Hive.box(_entriesBoxName);
    await box.put(entry.id, jsonEncode(entry.toMap()));
  }

  static Future<void> deleteEntry(String id) async {
    final box = Hive.box(_entriesBoxName);
    await box.delete(id);
  }

  // Wishlist Goals
  static List<WishlistGoal> getWishlistGoals() {
    final box = Hive.box(_wishlistBoxName);
    if (box.isEmpty) {
      // Seed initial 3 default wishlist goals
      final defaults = AppConstants.defaultWishlistGoals
          .map((m) => WishlistGoal.fromMap(m))
          .toList();
      for (var goal in defaults) {
        saveWishlistGoal(goal);
      }
      return defaults;
    }

    final List<WishlistGoal> list = [];
    for (var key in box.keys) {
      final String? jsonStr = box.get(key);
      if (jsonStr != null) {
        list.add(WishlistGoal.fromMap(jsonDecode(jsonStr)));
      }
    }
    return list;
  }

  static Future<void> saveWishlistGoal(WishlistGoal goal) async {
    final box = Hive.box(_wishlistBoxName);
    await box.put(goal.id, jsonEncode(goal.toMap()));
  }

  static Future<void> deleteWishlistGoal(String id) async {
    final box = Hive.box(_wishlistBoxName);
    await box.delete(id);
  }

  // Auth Credentials (Remember Me)
  static Future<void> saveSavedCredentials(
      String email, String password, bool remember) async {
    final box = Hive.box(_settingsBoxName);
    await box.put('remember_me', remember);
    if (remember) {
      await box.put('saved_email', email);
      await box.put('saved_password', password);
    } else {
      await box.delete('saved_email');
      await box.delete('saved_password');
    }
  }

  static Map<String, dynamic> getSavedCredentials() {
    final box = Hive.box(_settingsBoxName);
    final bool remember = box.get('remember_me', defaultValue: true);
    final String email = box.get('saved_email', defaultValue: 'quocphungccq1911h@gmail.com');
    final String password = box.get('saved_password', defaultValue: '');
    return {
      'remember': remember,
      'email': email,
      'password': password,
    };
  }

  // Daily Goal Persistence
  static double getDailyGoal() {
    final box = Hive.box(_settingsBoxName);
    return (box.get('daily_goal', defaultValue: AppConstants.defaultDailyGoal) as num).toDouble();
  }

  static Future<void> saveDailyGoal(double goal) async {
    final box = Hive.box(_settingsBoxName);
    await box.put('daily_goal', goal);
  }

  // Theme Mode Persistence ('dark' or 'light')
  static String getThemeMode() {
    final box = Hive.box(_settingsBoxName);
    return box.get('theme_mode', defaultValue: 'dark') as String;
  }

  static Future<void> saveThemeMode(String mode) async {
    final box = Hive.box(_settingsBoxName);
    await box.put('theme_mode', mode);
  }
}

