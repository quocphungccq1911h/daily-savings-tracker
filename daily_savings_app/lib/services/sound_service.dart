import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SoundService {
  /// Phát âm thanh va chạm kim loại "Keng Keng" & Rung Haptic khi bỏ lợn tiết kiệm
  static void playCoinSound() {
    try {
      // 1. Kích hoạt phản hồi rung Haptic tactile kim loại mạnh mẽ
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 120), () {
        HapticFeedback.mediumImpact();
      });

      // 2. Phát âm thanh click kim loại hệ thống
      SystemSound.play(SystemSoundType.click);
    } catch (e) {
      debugPrint('SoundService error: $e');
    }
  }
}
