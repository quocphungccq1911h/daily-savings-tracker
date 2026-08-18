import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/sound_service.dart';

class DartsGameDialog extends StatefulWidget {
  const DartsGameDialog({super.key});

  @override
  State<DartsGameDialog> createState() => _DartsGameDialogState();
}

class _DartsGameDialogState extends State<DartsGameDialog> {
  static const double boardWidth = 300;
  static const double boardHeight = 360;

  double targetX = boardWidth / 2;
  double targetY = 120;
  double targetDir = 2.5;

  double aimX = boardWidth / 2;
  double aimDir = 3.0;

  double power = 0.0;
  bool powerIncreasing = true;

  int dartsLeft = 5;
  int totalScore = 0;
  int highScore = 0;
  String lastHitText = '';

  Timer? gameTimer;
  bool isFlying = false;
  Offset? dartLandPos;
  bool isGameOver = false;

  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      if (!mounted || isGameOver) return;

      setState(() {
        // Move Target horizontally
        targetX += targetDir;
        if (targetX < 60 || targetX > boardWidth - 60) {
          targetDir = -targetDir;
        }

        // Oscillate Aim Line
        aimX += aimDir;
        if (aimX < 40 || aimX > boardWidth - 40) {
          aimDir = -aimDir;
        }

        // Oscillate Power Bar
        if (powerIncreasing) {
          power += 0.03;
          if (power >= 1.0) {
            power = 1.0;
            powerIncreasing = false;
          }
        } else {
          power -= 0.03;
          if (power <= 0.0) {
            power = 0.0;
            powerIncreasing = true;
          }
        }
      });
    });
  }

  void _throwDart() {
    if (isFlying || dartsLeft <= 0 || isGameOver) return;

    setState(() {
      isFlying = true;
      dartsLeft--;

      // Calculate landing spot with power & aim accuracy
      double landX = aimX + (random.nextDouble() * 12 - 6);
      double landY = targetY + (1.0 - power) * 80 - 40;
      dartLandPos = Offset(landX, landY);

      // Distance to target center
      double dist = sqrt(pow(landX - targetX, 2) + pow(landY - targetY, 2));

      int pts = 0;
      if (dist < 12) {
        pts = 100;
        lastHitText = '🎯 BULLSEYE! +100 ĐIỂM';
        SoundService.playCoinSound();
      } else if (dist < 28) {
        pts = 50;
        lastHitText = '🌟 VÒNG VÀNG! +50 ĐIỂM';
        SoundService.playCoinSound();
      } else if (dist < 48) {
        pts = 30;
        lastHitText = '🔵 VÒNG XANH! +30 ĐIỂM';
      } else if (dist < 68) {
        pts = 10;
        lastHitText = '⚪ VÒNG NGOÀI! +10 ĐIỂM';
      } else {
        pts = 0;
        lastHitText = '❌ TRỤT BIA! 0 ĐIỂM';
      }

      totalScore += pts;
      if (totalScore > highScore) highScore = totalScore;
    });

    // Reset dart flying state after 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          isFlying = false;
          if (dartsLeft <= 0) {
            isGameOver = true;
          }
        });
      }
    });
  }

  void _restartGame() {
    setState(() {
      dartsLeft = 5;
      totalScore = 0;
      lastHitText = '';
      dartLandPos = null;
      isGameOver = false;
      isFlying = false;
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = Theme.of(context).cardColor;
    final secondaryTextColor = isDark ? AppTheme.textMuted : const Color(0xFF64748B);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text('🎯', style: TextStyle(fontSize: 22)),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PHI TIÊU GIẢI TỎA CĂNG THẲNG',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                'Ngắm bắn trúng tâm Bullseye 🎯',
                                style: TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    children: [
                      // Score & Darts Left Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text('ĐIỂM SỐ', style: TextStyle(fontSize: 10, color: secondaryTextColor, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('$totalScore', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.redAccent)),
                            ],
                          ),
                          Column(
                            children: [
                              Text('MŨI TIÊU', style: TextStyle(fontSize: 10, color: secondaryTextColor, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('🎯 x $dartsLeft', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.amberGoldLight)),
                            ],
                          ),
                          Column(
                            children: [
                              Text('KỶ LỤC', style: TextStyle(fontSize: 10, color: secondaryTextColor, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('$highScore', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: secondaryTextColor)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Darts Board Canvas Area
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: boardWidth,
                            height: boardHeight,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
                            ),
                            child: CustomPaint(
                              painter: DartsPainter(
                                targetX: targetX,
                                targetY: targetY,
                                aimX: aimX,
                                power: power,
                                dartLandPos: dartLandPos,
                                isFlying: isFlying,
                              ),
                            ),
                          ),

                          if (isGameOver)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.redAccent, width: 2),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🎯 HOÀN THÀNH LƯỢT PHI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.amberAccent)),
                                  const SizedBox(height: 8),
                                  Text('Tổng điểm: $totalScore ĐIỂM', style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    onPressed: _restartGame,
                                    icon: const Icon(Icons.replay_rounded, color: Colors.white),
                                    label: const Text('Bắn Lại', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (lastHitText.isNotEmpty)
                        Text(lastHitText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.amberGoldLight)),
                      const SizedBox(height: 10),

                      // Throw Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: (isFlying || dartsLeft <= 0 || isGameOver) ? null : _throwDart,
                          icon: const Icon(Icons.ads_click_rounded, color: Colors.white, size: 20),
                          label: const Text('PHI TIÊU NGAY 🎯', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DartsPainter extends CustomPainter {
  final double targetX;
  final double targetY;
  final double aimX;
  final double power;
  final Offset? dartLandPos;
  final bool isFlying;

  DartsPainter({
    required this.targetX,
    required this.targetY,
    required this.aimX,
    required this.power,
    required this.dartLandPos,
    required this.isFlying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Target Concentric Circles (Bullseye)
    Offset center = Offset(targetX, targetY);

    // Outer Ring 10pts (White)
    canvas.drawCircle(center, 68, Paint()..color = Colors.white.withValues(alpha: 0.9));
    // Ring 30pts (Blue)
    canvas.drawCircle(center, 48, Paint()..color = const Color(0xFF0284C7));
    // Ring 50pts (Gold)
    canvas.drawCircle(center, 28, Paint()..color = const Color(0xFFF59E0B));
    // Bullseye 100pts (Red)
    canvas.drawCircle(center, 12, Paint()..color = const Color(0xFFEF4444));

    // Target Border Outline
    canvas.drawCircle(
      center,
      68,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Draw Aim Crosshair Line
    Paint aimLinePaint = Paint()
      ..color = Colors.amberAccent.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(aimX, 0), Offset(aimX, size.height), aimLinePaint);

    // Draw Power Bar on Left Side
    double powerBarHeight = 120;
    double powerBarX = 14;
    double powerBarY = 200;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(powerBarX, powerBarY, 10, powerBarHeight), const Radius.circular(5)),
      Paint()..color = Colors.white24,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(powerBarX, powerBarY + powerBarHeight * (1.0 - power), 10, powerBarHeight * power), const Radius.circular(5)),
      Paint()..color = Colors.redAccent,
    );

    // Draw Landed Dart
    if (dartLandPos != null) {
      Paint dartPaint = Paint()..color = Colors.amberAccent;
      canvas.drawCircle(dartLandPos!, 5, dartPaint);
      canvas.drawLine(dartLandPos!, dartLandPos! + const Offset(10, 15), Paint()..color = Colors.redAccent..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(covariant DartsPainter oldDelegate) => true;
}
