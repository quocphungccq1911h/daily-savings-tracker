import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../providers/savings_provider.dart';
import 'local_storage_service.dart';

class GeminiService {
  static const String _defaultApiKey = '';

  static String get apiKey {
    final customKey = LocalStorageService.getCustomGeminiKey();
    if (customKey.isNotEmpty) return customKey;
    return _defaultApiKey;
  }

  /// Gọi API Google Gemini 1.5 Flash với Live App Context
  static Future<String> askGemini({
    required String userPrompt,
    required SavingsState savingsState,
    List<Map<String, String>> chatHistory = const [],
  }) async {
    try {
      final now = DateTime.now();
      final todayStr = '${now.day}/${now.month}/${now.year}';

      // Tính toán dữ liệu tài chính thời gian thực của người dùng
      final String todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      double todayAmount = 0;
      for (var e in savingsState.entries) {
        if (e.date == todayKey) todayAmount += e.amount;
      }

      final double remainingTarget = savingsState.dailyGoal - todayAmount;
      final bool isTargetAchieved = todayAmount >= savingsState.dailyGoal;

      // Đếm ngược Tết
      final tetDate = DateTime(2027, 2, 6); // Mùng 1 Tết Đinh Mùi 2027
      final daysLeftToTet = max(0, tetDate.difference(now).inDays);
      final estimatedTetFund =
          savingsState.lifetimeTotal + (daysLeftToTet * savingsState.dailyGoal);

      // System Prompt đóng gói Live Context
      final String systemInstruction = '''
Bạn là "Trợ Lý AI Tiết Kiệm" thông minh, thân thiện và giàu năng lượng trong ứng dụng "Sổ Tiết Kiệm Daily".
Nhiệm vụ của bạn là giải đáp câu hỏi của người dùng và đưa ra lời khuyên tài chính cá nhân dựa TRỰC TIẾP trên dữ liệu thời gian thực sau đây của họ:

--- DỮ LIỆU HIỆN TẠI CỦA NGƯỜI DÙNG ---
- Hôm nay (Dương lịch): $todayStr
- Mục tiêu tiết kiệm hằng ngày: ${savingsState.dailyGoal.toInt()} VNĐ/ngày
- Số tiền đã nạp tiết kiệm HÔM NAY: ${todayAmount.toInt()} VNĐ
- Trạng thái mục tiêu hôm nay: ${isTargetAchieved ? 'ĐÃ ĐẠT TARGET 🎉' : 'CHƯA ĐẠT (Còn thiếu ' + (remainingTarget > 0 ? remainingTarget.toInt().toString() : '0') + ' VNĐ)'}
- Chuỗi ngày tích lũy liên tục (Streak): ${savingsState.streakCount} ngày 🔥
- Tổng tích lũy từ trước đến nay: ${savingsState.lifetimeTotal.toInt()} VNĐ
- Tổng tiết kiệm tháng này: ${savingsState.currentMonthTotal.toInt()} VNĐ
- Đếm ngược đến Mùng 1 Tết Nguyên Đán (Đinh Mùi): còn $daysLeftToTet ngày 🧧
- Dự tính quỹ ăn Tết: ${estimatedTetFund.toInt()} VNĐ

--- QUY TẮC TRẢ LỜI ---
1. Trả lời ngắn gọn (trong khoảng 2 - 4 câu), đúng trọng tâm, hào hứng và dùng emoji phù hợp.
2. Khi người dùng hỏi về target/mục tiêu hôm nay, số tiền còn thiếu hay số ngày tới Tết, hãy dùng CHÍNH XÁC con số trong dữ liệu trên để trả lời.
3. Luôn động viên người dùng duy trì thói quen tích lũy hằng ngày!
''';

      // Tạo cấu trúc tin nhắn cho Gemini API
      final List<Map<String, dynamic>> contents = [];

      // Thêm lịch sử hội thoại gần đây (tối đa 4 tin nhắn)
      for (var msg in chatHistory.take(4)) {
        contents.add({
          'role': msg['sender'] == 'user' ? 'user' : 'model',
          'parts': [
            {'text': msg['text'] ?? ''}
          ],
        });
      }

      // Thêm câu hỏi mới nhất của user kèm System Context
      final fullUserMessage =
          '$systemInstruction\n\n[CÂU HỎI NGƯỜI DÙNG]: $userPrompt';
      contents.add({
        'role': 'user',
        'parts': [
          {'text': fullUserMessage}
        ],
      });

      // Thử model mới nhất Google Gemini 3.6 Flash (theo phản hồi từ Google API server)
      final modelsToTry = [
        'gemini-3.6-flash',
        'gemini-1.5-flash-latest',
        'gemini-2.0-flash-exp',
        'gemini-flash',
      ];

      for (var modelName in modelsToTry) {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
        );

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': contents,
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 2048,
            },
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Log số lượng token tiêu hao thực tế
          final usage = data['usageMetadata'];
          if (usage != null) {
            debugPrint('📊 [Gemini API Usage] Prompt: ${usage['promptTokenCount']} | Response: ${usage['candidatesTokenCount']} | Total: ${usage['totalTokenCount']} tokens');
          }

          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              // Tìm part chứa câu trả lời chữ đầy đủ nhất
              String fullText = '';
              for (var part in parts) {
                final txt = part['text'] as String?;
                if (txt != null && txt.isNotEmpty) {
                  fullText += '$txt ';
                }
              }
              if (fullText.trim().isNotEmpty) {
                return fullText.trim();
              }
            }
          }
          return 'Dạ, tôi chưa hiểu rõ ý bạn. Bạn có thể hỏi lại về target tiết kiệm hay đếm ngược Tết không ạ? 🐷';
        } else {
          debugPrint(
              'Gemini API ($modelName) Status: ${response.statusCode} - ${response.body}');
        }
      }

      return _fallbackOfflineAnswer(userPrompt, savingsState, todayAmount,
          remainingTarget, isTargetAchieved, daysLeftToTet);
    } catch (e) {
      debugPrint('Gemini Exception: $e');
      final now = DateTime.now();
      final String todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      double todayAmount = 0;
      for (var e in savingsState.entries) {
        if (e.date == todayKey) todayAmount += e.amount;
      }
      final double remainingTarget = savingsState.dailyGoal - todayAmount;
      final bool isTargetAchieved = todayAmount >= savingsState.dailyGoal;
      final tetDate = DateTime(2027, 2, 6);
      final daysLeftToTet = max(0, tetDate.difference(now).inDays);
      return _fallbackOfflineAnswer(userPrompt, savingsState, todayAmount,
          remainingTarget, isTargetAchieved, daysLeftToTet);
    }
  }

  /// Trả lời thông minh ngoại tuyến nếu chưa cấu hình API Key hoặc mất mạng
  static String _fallbackOfflineAnswer(
    String prompt,
    SavingsState state,
    double todayAmount,
    double remainingTarget,
    bool isTargetAchieved,
    int daysLeftToTet,
  ) {
    final lower = prompt.toLowerCase();

    if (lower.contains('target') ||
        lower.contains('mục tiêu') ||
        lower.contains('bao nhiêu tiền') ||
        lower.contains('còn thiếu')) {
      if (isTargetAchieved) {
        return '🎉 Chúc mừng bạn! Hôm nay bạn đã đạt target ${state.dailyGoal.toInt()}đ (đã nạp ${todayAmount.toInt()}đ) rồi nhé! Tiếp tục phát huy nào! 💪';
      } else {
        final remainingStr =
            remainingTarget > 0 ? '${remainingTarget.toInt()}đ' : '0đ';
        return '📌 Hôm nay bạn đã nạp ${todayAmount.toInt()}đ. Bạn cần tích lũy thêm **$remainingStr** nữa để đạt target ${state.dailyGoal.toInt()}đ/ngày hôm nay nhé! 🐷';
      }
    }

    if (lower.contains('tết') ||
        lower.contains('đếm ngược') ||
        lower.contains('ngày nữa')) {
      return '🧧 Còn đúng **$daysLeftToTet ngày** nữa là đến Mùng 1 Tết Âm Lịch (Tết Đinh Mùi)! Dự kiến quỹ Tết của bạn sẽ đạt **${(state.lifetimeTotal + daysLeftToTet * state.dailyGoal).toInt()}đ** đó! 🍊';
    }

    if (lower.contains('hôm nay') || lower.contains('ngày')) {
      final now = DateTime.now();
      return '📅 Hôm nay là ngày ${now.day}/${now.month}/${now.year} (Dương Lịch). Đừng quên cập nhật sổ tiết kiệm nhé!';
    }

    if (lower.contains('lời khuyên') ||
        lower.contains('tư vấn') ||
        lower.contains('mẹo')) {
      return '💡 Mẹo tiết kiệm: Hãy trích 10% thu nhập ngay khi nhận tiền, và duy trì chuỗi ${state.streakCount} ngày tích lũy liên tục nhé!';
    }

    return '🤖 Trợ Lý AI Tiết Kiệm đây ạ! Hôm nay bạn đã nạp ${todayAmount.toInt()}đ / target ${state.dailyGoal.toInt()}đ. Còn $daysLeftToTet ngày nữa là tới Tết rồi, cố lên nhé! ✨';
  }
}
