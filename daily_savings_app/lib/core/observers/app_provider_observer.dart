import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AppProviderObserver - Bộ soi và log dữ liệu State tự động trên Chrome F12 Console & Terminal
class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;

    final providerName = provider.name ?? provider.runtimeType.toString();
    debugPrint('--------------------------------------------------');
    debugPrint('🔄 [Riverpod State Updated] ➔ $providerName');
    debugPrint('   📦 Data mới: $newValue');
    debugPrint('--------------------------------------------------');
  }

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;

    final providerName = provider.name ?? provider.runtimeType.toString();
    debugPrint('🟢 [Riverpod Provider Initialized] ➔ $providerName');
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;

    final providerName = provider.name ?? provider.runtimeType.toString();
    debugPrint('❌ [Riverpod Provider Error] ➔ $providerName');
    debugPrint('   ⚠️ Lỗi: $error');
  }
}
