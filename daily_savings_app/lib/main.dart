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
import 'services/biometric_service.dart';
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

class _RootGateState extends ConsumerState<RootGate> with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isBiometricLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _isBiometricLocked = LocalStorageService.getBiometricsEnabled();
    if (_isBiometricLocked) {
      _checkBiometrics();
    }

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && LocalStorageService.getBiometricsEnabled()) {
      setState(() {
        _isBiometricLocked = true;
      });
      _checkBiometrics();
    }
  }

  void _checkBiometrics() async {
    final ok = await BiometricService.authenticate();
    if (ok && mounted) {
      setState(() {
        _isBiometricLocked = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

    if (_isBiometricLocked) {
      return BiometricLockScreen(onUnlock: _checkBiometrics);
    }

    return const HomeScreen();
  }
}

class BiometricLockScreen extends StatelessWidget {
  final VoidCallback onUnlock;
  const BiometricLockScreen({super.key, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgApp : AppTheme.bgAppLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fingerprint_rounded, size: 72, color: AppTheme.emeraldPrimary),
              ),
              const SizedBox(height: 20),
              Text(
                'Ứng Dụng Đang Được Khóa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng quét Vân Tay / FaceID để truy cập sổ tiết kiệm',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onUnlock,
                icon: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 18),
                label: const Text('Mở Khóa Ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
