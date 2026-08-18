import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../services/sound_service.dart';

class FlappyPiggyDialog extends StatefulWidget {
  const FlappyPiggyDialog({super.key});

  @override
  State<FlappyPiggyDialog> createState() => _FlappyPiggyDialogState();
}

class _FlappyPiggyDialogState extends State<FlappyPiggyDialog> {
  static const double gravity = 0.45;
  static const double jumpStrength = -6.5;
  static const double boardWidth = 300;
  static const double boardHeight = 420;
  static const double pigX = 60;
  static const double pigRadius = 14;

  double pigY = boardHeight / 2;
  double velocity = 0;
  Timer? gameLoop;

  bool isStarted = false;
  bool isGameOver = false;
  int score = 0;
  int highScore = 0;

  List<Pipe> pipes = [];
  final Random random = Random();

  @override
  void dispose() {
    gameLoop?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      pigY = boardHeight / 2;
      velocity = jumpStrength;
      score = 0;
      isStarted = true;
      isGameOver = false;
      pipes.clear();
      _spawnPipe(boardWidth + 50);
      _spawnPipe(boardWidth + 220);
    });

    gameLoop?.cancel();
    gameLoop = Timer.periodic(const Duration(milliseconds: 24), (_) {
      if (!mounted) return;
      _updatePhysics();
    });
  }

  void _spawnPipe(double x) {
    double gap = 110;
    double minHeight = 50;
    double maxHeight = boardHeight - gap - minHeight;
    double topHeight = minHeight + random.nextDouble() * (maxHeight - minHeight);
    pipes.add(Pipe(x: x, topHeight: topHeight, gap: gap));
  }

  void _jump() {
    if (!isStarted || isGameOver) {
      _startGame();
      return;
    }
    if (!mounted) return;
    setState(() {
      velocity = jumpStrength;
    });
  }

  void _updatePhysics() {
    if (!mounted || !isStarted || isGameOver) return;

    setState(() {
      velocity += gravity;
      pigY += velocity;

      // Check Ground / Ceiling collision
      if (pigY - pigRadius <= 0 || pigY + pigRadius >= boardHeight) {
        _triggerGameOver();
        return;
      }

      // Update Pipes
      for (int i = 0; i < pipes.length; i++) {
        pipes[i].x -= 3.0;

        // Score increment
        if (!pipes[i].passed && pipes[i].x + Pipe.pipeWidth < pigX) {
          pipes[i].passed = true;
          score++;
          if (score > highScore) highScore = score;
          SoundService.playCoinSound();
        }

        // Pipe Collision check
        if (_checkPipeCollision(pipes[i])) {
          _triggerGameOver();
          return;
        }
      }

      // Recycle offscreen pipes
      if (pipes.isNotEmpty && pipes.first.x < -Pipe.pipeWidth) {
        pipes.removeAt(0);
        _spawnPipe(pipes.last.x + 170);
      }
    });
  }

  bool _checkPipeCollision(Pipe pipe) {
    double pipeLeft = pipe.x;
    double pipeRight = pipe.x + Pipe.pipeWidth;

    if (pigX + pigRadius > pipeLeft && pigX - pigRadius < pipeRight) {
      if (pigY - pigRadius < pipe.topHeight || pigY + pigRadius > pipe.topHeight + pipe.gap) {
        return true;
      }
    }
    return false;
  }

  void _triggerGameOver() {
    gameLoop?.cancel();
    setState(() {
      isGameOver = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = Theme.of(context).cardColor;
    final secondaryTextColor = isDark ? AppTheme.textMuted : const Color(0xFF64748B);

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.arrowUp)) {
          _jump();
        }
        return KeyEventResult.handled;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        child: Container(
          decoration: BoxDecoration(
            color: dialogBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.amberGoldLight.withValues(alpha: 0.6), width: 1.5),
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
                  // Game Header Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Text('🐷', style: TextStyle(fontSize: 22)),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GAME CHÚ LỢN BAY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  'Vỗ cánh nhặt xu vàng 🪙',
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
                        // Score Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('ĐIỂM: $score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.amberGoldLight)),
                            Text('KỶ LỤC: $highScore', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: secondaryTextColor)),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Game Canvas Container
                        GestureDetector(
                          onTap: _jump,
                          child: Container(
                            width: boardWidth,
                            height: boardHeight,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.amberGoldLight.withValues(alpha: 0.5), width: 1.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  CustomPaint(
                                    size: const Size(boardWidth, boardHeight),
                                    painter: FlappyPiggyPainter(
                                      pigY: pigY,
                                      pigX: pigX,
                                      pigRadius: pigRadius,
                                      pipes: pipes,
                                      velocity: velocity,
                                    ),
                                  ),

                                  if (!isStarted)
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.75),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('🐷 CHẠM ĐỂ BẮT ĐẦU', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.amberAccent)),
                                            SizedBox(height: 4),
                                            Text('Nhấn màn hình hoặc phím Space để Lợn vỗ cánh', style: TextStyle(fontSize: 10, color: Colors.white70)),
                                          ],
                                        ),
                                      ),
                                    ),

                                  if (isGameOver)
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.redAccent, width: 2),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('💥 GAME OVER', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.redAccent)),
                                            const SizedBox(height: 6),
                                            Text('Điểm số: $score', style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 12),
                                            ElevatedButton.icon(
                                              onPressed: _startGame,
                                              icon: const Icon(Icons.replay_rounded, color: Colors.white),
                                              label: const Text('Chơi Lại', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.emeraldPrimary,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('💡 Chạm màn hình hoặc bấm phím SPACE để nhảy', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Pipe {
  static const double pipeWidth = 44;
  double x;
  double topHeight;
  double gap;
  bool passed = false;

  Pipe({required this.x, required this.topHeight, required this.gap});
}

class FlappyPiggyPainter extends CustomPainter {
  final double pigY;
  final double pigX;
  final double pigRadius;
  final List<Pipe> pipes;
  final double velocity;

  FlappyPiggyPainter({
    required this.pigY,
    required this.pigX,
    required this.pigRadius,
    required this.pipes,
    required this.velocity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Pipes (Golden Pillars)
    Paint pipePaint = Paint()..color = const Color(0xFF10B981);
    Paint pipeCapPaint = Paint()..color = const Color(0xFF059669);

    for (var pipe in pipes) {
      // Top Pipe
      Rect topRect = Rect.fromLTWH(pipe.x, 0, Pipe.pipeWidth, pipe.topHeight);
      canvas.drawRect(topRect, pipePaint);
      canvas.drawRect(Rect.fromLTWH(pipe.x - 2, pipe.topHeight - 12, Pipe.pipeWidth + 4, 12), pipeCapPaint);

      // Bottom Pipe
      double bottomY = pipe.topHeight + pipe.gap;
      Rect bottomRect = Rect.fromLTWH(pipe.x, bottomY, Pipe.pipeWidth, size.height - bottomY);
      canvas.drawRect(bottomRect, pipePaint);
      canvas.drawRect(Rect.fromLTWH(pipe.x - 2, bottomY, Pipe.pipeWidth + 4, 12), pipeCapPaint);
    }

    // Draw Flying Piggy 🐷 Body
    canvas.save();
    canvas.translate(pigX, pigY);

    // Tilt pig body according to velocity
    double rotation = (velocity / 10).clamp(-0.5, 0.5);
    canvas.rotate(rotation);

    // Piggy Body (Pink Circle)
    Paint pigBodyPaint = Paint()..color = const Color(0xFFF472B6);
    canvas.drawCircle(Offset.zero, pigRadius, pigBodyPaint);

    // Piggy Snout
    Paint snoutPaint = Paint()..color = const Color(0xFFEC4899);
    canvas.drawOval(Rect.fromCenter(center: const Offset(6, 2), width: 8, height: 6), snoutPaint);

    // Piggy Eye
    Paint eyePaint = Paint()..color = Colors.black;
    canvas.drawCircle(const Offset(4, -4), 2, eyePaint);

    // Piggy Wing
    Paint wingPaint = Paint()..color = Colors.white;
    Path wingPath = Path()
      ..moveTo(-4, 0)
      ..quadraticBezierTo(-12, velocity < 0 ? -12 : 2, -4, 6)
      ..close();
    canvas.drawPath(wingPath, wingPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FlappyPiggyPainter oldDelegate) => true;
}
