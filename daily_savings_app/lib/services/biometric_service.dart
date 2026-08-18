import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Kiểm tra thiết bị có phần cứng Vân tay / FaceID hay không
  static Future<bool> isBiometricsAvailable() async {
    if (kIsWeb) return true;
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Biometric Availability Error: $e');
      return true;
    }
  }

  /// Yêu cầu người dùng Quét Vân Tay / FaceID để mở khóa ứng dụng
  static Future<bool> authenticate() async {
    if (kIsWeb) return true;
    try {
      final bool isSupported = await _auth.isDeviceSupported();
      final bool canCheck = await _auth.canCheckBiometrics;

      if (!isSupported && !canCheck) {
        return true; // Giả lập hoặc thiết bị không có phần cứng vân tay -> cho qua
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Vui lòng quét Vân Tay / FaceID để mở khóa Sổ Tiết Kiệm Daily',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Biometric Authenticate Error: $e');
      return true; // Fallback cho qua nếu có lỗi hệ thống không hỗ trợ
    } catch (e) {
      debugPrint('Biometric General Error: $e');
      return true;
    }
  }
}
