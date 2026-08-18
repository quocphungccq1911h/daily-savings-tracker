import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../services/sound_service.dart';

class TetrisGameDialog extends StatefulWidget {
  const TetrisGameDialog({super.key});

  @override
  State<TetrisGameDialog> createState() => _TetrisGameDialogState();
}

class _TetrisGameDialogState extends State<TetrisGameDialog> {
  static const int rows = 20;
  static const int cols = 10;

  late List<List<Color?>> board;
  Timer? timer;
  bool isPlaying = false;
  bool isPaused = false;
  bool isGameOver = false;

  int score = 0;
  int linesCleared = 0;
  int level = 1;

  late List<List<int>> currentPiece;
  late Color currentPieceColor;
  int pieceRow = 0;
  int pieceCol = 3;

  late List<List<int>> nextPiece;
  late Color nextPieceColor;

  final Random random = Random();

  final List<Map<String, dynamic>> shapes = [
    {
      'color': const Color(0xFF06B6D4), // I - Cyan
      'shape': [
        [1, 1, 1, 1]
      ]
    },
    {
      'color': const Color(0xFFEAB308), // O - Yellow
      'shape': [
        [1, 1],
        [1, 1]
      ]
    },
    {
      'color': const Color(0xFFA855F7), // T - Purple
      'shape': [
        [0, 1, 0],
        [1, 1, 1]
      ]
    },
    {
      'color': const Color(0xFF22C55E), // S - Green
      'shape': [
        [0, 1, 1],
        [1, 1, 0]
      ]
    },
    {
      'color': const Color(0xFFEF4444), // Z - Red
      'shape': [
        [1, 1, 0],
        [0, 1, 1]
      ]
    },
    {
      'color': const Color(0xFF3B82F6), // J - Blue
      'shape': [
        [1, 0, 0],
        [1, 1, 1]
      ]
    },
    {
      'color': const Color(0xFFF97316), // L - Orange
      'shape': [
        [0, 0, 1],
        [1, 1, 1]
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _resetBoard();
    _generateNextPiece();
    _spawnPiece();
    _startGame();
  }

  void _resetBoard() {
    board = List.generate(rows, (_) => List.generate(cols, (_) => null));
    score = 0;
    linesCleared = 0;
    level = 1;
    isGameOver = false;
    isPaused = false;
  }

  void _generateNextPiece() {
    final idx = random.nextInt(shapes.length);
    nextPiece = shapes[idx]['shape'] as List<List<int>>;
    nextPieceColor = shapes[idx]['color'] as Color;
  }

  void _spawnPiece() {
    currentPiece = nextPiece;
    currentPieceColor = nextPieceColor;
    pieceRow = 0;
    pieceCol = (cols - currentPiece[0].length) ~/ 2;
    _generateNextPiece();

    if (_checkCollision(pieceRow, pieceCol, currentPiece)) {
      _gameOver();
    }
  }

  void _startGame() {
    isPlaying = true;
    timer?.cancel();
    int speed = max(100, 600 - (level - 1) * 50);
    timer = Timer.periodic(Duration(milliseconds: speed), (_) {
      if (!mounted) return;
      if (!isPaused && !isGameOver) {
        _moveDown();
      }
    });
  }

  void _gameOver() {
    timer?.cancel();
    if (!mounted) return;
    setState(() {
      isGameOver = true;
      isPlaying = false;
    });
  }

  bool _checkCollision(int r, int c, List<List<int>> piece) {
    for (int i = 0; i < piece.length; i++) {
      for (int j = 0; j < piece[i].length; j++) {
        if (piece[i][j] != 0) {
          int newRow = r + i;
          int newCol = c + j;

          if (newRow >= rows || newCol < 0 || newCol >= cols) {
            return true;
          }
          if (newRow >= 0 && board[newRow][newCol] != null) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void _moveLeft() {
    if (isGameOver || isPaused) return;
    if (!_checkCollision(pieceRow, pieceCol - 1, currentPiece)) {
      setState(() {
        pieceCol--;
      });
    }
  }

  void _moveRight() {
    if (isGameOver || isPaused) return;
    if (!_checkCollision(pieceRow, pieceCol + 1, currentPiece)) {
      setState(() {
        pieceCol++;
      });
    }
  }

  void _rotate() {
    if (isGameOver || isPaused) return;
    List<List<int>> rotated = List.generate(
      currentPiece[0].length,
      (i) => List.generate(currentPiece.length, (j) => currentPiece[currentPiece.length - 1 - j][i]),
    );

    if (!_checkCollision(pieceRow, pieceCol, rotated)) {
      setState(() {
        currentPiece = rotated;
      });
    }
  }

  void _moveDown() {
    if (isGameOver || isPaused) return;
    if (!_checkCollision(pieceRow + 1, pieceCol, currentPiece)) {
      setState(() {
        pieceRow++;
      });
    } else {
      _lockPiece();
    }
  }

  void _dropFast() {
    if (isGameOver || isPaused) return;
    while (!_checkCollision(pieceRow + 1, pieceCol, currentPiece)) {
      pieceRow++;
    }
    _lockPiece();
  }

  void _lockPiece() {
    for (int i = 0; i < currentPiece.length; i++) {
      for (int j = 0; j < currentPiece[i].length; j++) {
        if (currentPiece[i][j] != 0) {
          int r = pieceRow + i;
          int c = pieceCol + j;
          if (r >= 0 && r < rows) {
            board[r][c] = currentPieceColor;
          }
        }
      }
    }

    _clearLines();
    _spawnPiece();
    setState(() {});
  }

  void _clearLines() {
    int cleared = 0;
    for (int r = rows - 1; r >= 0; r--) {
      if (board[r].every((cell) => cell != null)) {
        board.removeAt(r);
        board.insert(0, List.generate(cols, (_) => null));
        cleared++;
        r++; // Recheck same row
      }
    }

    if (cleared > 0) {
      SoundService.playCoinSound();
      setState(() {
        linesCleared += cleared;
        score += cleared * 100 * level;
        level = (linesCleared ~/ 10) + 1;
      });
      _startGame(); // Update speed
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = Theme.of(context).cardColor;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? AppTheme.textMuted : const Color(0xFF64748B);
    final cardBorder = isDark ? AppTheme.borderColor : AppTheme.borderColorLight;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) _moveLeft();
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) _moveRight();
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) _rotate();
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) _dropFast();
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
            border: Border.all(color: AppTheme.skyBlueAccent.withValues(alpha: 0.6), width: 1.5),
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
                        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Text('🧱', style: TextStyle(fontSize: 22)),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TETRIS GAME CỔ ĐIỂN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  'Xếp gạch giải trí xả stress 🎮',
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
                        // Stats & Next Piece Row
                        Row(
                          children: [
                            // Score Board
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.bgApp : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Text('ĐIỂM SỐ', style: TextStyle(fontSize: 10, color: secondaryTextColor, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text('$score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.amberGoldLight)),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text('LEVEL', style: TextStyle(fontSize: 10, color: secondaryTextColor, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text('$level', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.skyBlueAccent)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Main Game Board Stack
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.skyBlueAccent.withValues(alpha: 0.5), width: 1.5),
                              ),
                              child: AspectRatio(
                                aspectRatio: cols / rows,
                                child: CustomPaint(
                                  painter: TetrisBoardPainter(
                                    board: board,
                                    currentPiece: currentPiece,
                                    pieceRow: pieceRow,
                                    pieceCol: pieceCol,
                                    currentPieceColor: currentPieceColor,
                                    rows: rows,
                                    cols: cols,
                                  ),
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
                                    const Text('💥 GAME OVER', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.redAccent)),
                                    const SizedBox(height: 8),
                                    Text('Tổng điểm: $score', style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _resetBoard();
                                          _spawnPiece();
                                          _startGame();
                                        });
                                      },
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
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Touch Controls D-Pad
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildControlButton(
                              icon: Icons.arrow_back_rounded,
                              label: 'Trái',
                              color: AppTheme.skyBlueAccent,
                              onPressed: _moveLeft,
                            ),
                            _buildControlButton(
                              icon: Icons.rotate_right_rounded,
                              label: 'Xoay',
                              color: AppTheme.amberGoldLight,
                              onPressed: _rotate,
                            ),
                            _buildControlButton(
                              icon: Icons.arrow_forward_rounded,
                              label: 'Phải',
                              color: AppTheme.skyBlueAccent,
                              onPressed: _moveRight,
                            ),
                            _buildControlButton(
                              icon: Icons.south_rounded,
                              label: 'Thả',
                              color: Colors.redAccent,
                              onPressed: _dropFast,
                            ),
                          ],
                        ),
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

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class TetrisBoardPainter extends CustomPainter {
  final List<List<Color?>> board;
  final List<List<int>> currentPiece;
  final int pieceRow;
  final int pieceCol;
  final Color currentPieceColor;
  final int rows;
  final int cols;

  TetrisBoardPainter({
    required this.board,
    required this.currentPiece,
    required this.pieceRow,
    required this.pieceCol,
    required this.currentPieceColor,
    required this.rows,
    required this.cols,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double cellWidth = size.width / cols;
    double cellHeight = size.height / rows;

    Paint gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke;

    // Draw Grid Background lines
    for (int r = 0; r <= rows; r++) {
      canvas.drawLine(Offset(0, r * cellHeight), Offset(size.width, r * cellHeight), gridPaint);
    }
    for (int c = 0; c <= cols; c++) {
      canvas.drawLine(Offset(c * cellWidth, 0), Offset(c * cellWidth, size.height), gridPaint);
    }

    // Draw Locked Board Cells
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c] != null) {
          _drawBlock(canvas, c * cellWidth, r * cellHeight, cellWidth, cellHeight, board[r][c]!);
        }
      }
    }

    // Draw Active Current Falling Piece
    for (int i = 0; i < currentPiece.length; i++) {
      for (int j = 0; j < currentPiece[i].length; j++) {
        if (currentPiece[i][j] != 0) {
          int r = pieceRow + i;
          int c = pieceCol + j;
          if (r >= 0 && r < rows && c >= 0 && c < cols) {
            _drawBlock(canvas, c * cellWidth, r * cellHeight, cellWidth, cellHeight, currentPieceColor);
          }
        }
      }
    }
  }

  void _drawBlock(Canvas canvas, double x, double y, double w, double h, Color color) {
    Paint fillPaint = Paint()..color = color;
    RRect rrect = RRect.fromRectAndRadius(Rect.fromLTWH(x + 1, y + 1, w - 2, h - 2), const Radius.circular(3));
    canvas.drawRRect(rrect, fillPaint);

    Paint borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant TetrisBoardPainter oldDelegate) => true;
}
