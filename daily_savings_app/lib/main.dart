import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/observers/app_provider_observer.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'services/local_storage_service.dart';
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

class DailySavingsApp extends StatelessWidget {
  const DailySavingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sổ Tiết Kiệm Daily',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const RootGate(),
    );
  }
}

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  @override
  void initState() {
    super.initState();
    // Stream auth state changes
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    if (user == null) {
      return LoginScreen(
        onLoginSuccess: () {
          setState(() {});
        },
      );
    }
    return const HomeScreen();
  }
}
