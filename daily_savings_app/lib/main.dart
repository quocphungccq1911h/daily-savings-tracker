import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/home_screen.dart';
import 'services/local_storage_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();
  await SupabaseService.init();

  runApp(
    const ProviderScope(
      child: DailySavingsApp(),
    ),
  );
}

class DailySavingsApp extends StatelessWidget {
  const DailySavingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sổ Tiết Kiệm Daily',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
