import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/observers/app_provider_observer.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/savings_provider.dart';
import 'providers/theme_provider.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Triệt tiêu lỗi assertion ViewInsets của Flutter Web engine khi resize trình duyệt
    FlutterError.onError = (FlutterErrorDetails details) {
      final exceptionStr = details.exception.toString();
      if (exceptionStr.contains('_viewInsets.isNonNegative') ||
          exceptionStr.contains('ViewInsets cannot be negative')) {
        return;
      }
      FlutterError.presentError(details);
    };

    await LocalStorageService.init();
    await SupabaseService.init();
    
    // Tự động khởi tạo & đặt lịch nhắc nhở nạp tiền tiết kiệm lúc 20:00 tối hàng ngày
    try {
      final notifService = NotificationService();
      await notifService.init();
      await notifService.scheduleDailyReminder(hour: 20, minute: 0);
    } catch (e) {
      debugPrint('Notification init warning: $e');
    }

    runApp(
      const ProviderScope(
        observers: [AppProviderObserver()],
        child: DailySavingsApp(),
      ),
    );
  }, (error, stackTrace) {
    final errStr = error.toString();
    if (errStr.contains('_viewInsets.isNonNegative') ||
        errStr.contains('ViewInsets cannot be negative')) {
      return;
    }
  });
}

class DailySavingsApp extends ConsumerWidget {
  const DailySavingsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Sổ Tiết Kiệm Daily',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const RootGate(),
    );
  }
}


class RootGate extends ConsumerStatefulWidget {
  const RootGate({super.key});

  @override
  ConsumerState<RootGate> createState() => _RootGateState();
}

class _RootGateState extends ConsumerState<RootGate> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        ref.read(savingsProvider.notifier).clearOnLogout();
      } else if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        ref.read(savingsProvider.notifier).rebindRealtimeOnLogin();
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    if (user == null) {
      return LoginScreen(
        onLoginSuccess: () {
          ref.read(savingsProvider.notifier).rebindRealtimeOnLogin();
          if (mounted) setState(() {});
        },
      );
    }
    return const HomeScreen();
  }
}
