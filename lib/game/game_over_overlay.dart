import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class GameOverOverlay extends PositionComponent with HasGameReference, TapCallbacks {
  final bool victory;
  final int score;
  final int floorsCleared;
  final int roomsCleared;
  final int enemiesKilled;
  final int gold;
  final int boonsCollected;
  final VoidCallback onPlayAgain;

  GameOverOverlay({
    required this.victory,
    required this.score,
    required this.floorsCleared,
    required this.roomsCleared,
    required this.enemiesKilled,
    required this.gold,
    required this.boonsCollected,
    required this.onPlayAgain,
  });

  Rect? _buttonRect;

  @override
  void onTapUp(TapUpEvent event) {
    if (_buttonRect != null &&
        _buttonRect!.contains(event.canvasPosition.toOffset())) {
      onPlayAgain();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = game.size.x;
    final h = game.size.y;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xDD000000),
    );

    final tp = TextPainter(textDirection: TextDirection.ltr);

    // Title
    final titleText = victory ? 'VICTORY!' : 'DEFEATED';
    final titleColor = victory ? const Color(0xFFffd700) : const Color(0xFFf44336);
    tp.text = TextSpan(
      text: titleText,
      style: TextStyle(color: titleColor, fontSize: 42, fontWeight: FontWeight.bold),
    );
    tp.layout();
    tp.paint(canvas, Offset((w - tp.width) / 2, h * 0.15));

    // Score
    tp.text = TextSpan(
      text: 'SCORE: $score',
      style: const TextStyle(color: Colors.amber, fontSize: 28, fontWeight: FontWeight.bold),
    );
    tp.layout();
    tp.paint(canvas, Offset((w - tp.width) / 2, h * 0.28));

    // Stats
    final stats = [
      ('Floors Cleared', '$floorsCleared'),
      ('Rooms Cleared', '$roomsCleared'),
      ('Enemies Killed', '$enemiesKilled'),
      ('Gold Collected', '$gold'),
      ('Boons Collected', '$boonsCollected'),
    ];

    var statY = h * 0.38;
    for (final (label, value) in stats) {
      tp.text = TextSpan(
        text: '$label: $value',
        style: const TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'monospace'),
      );
      tp.layout();
      tp.paint(canvas, Offset((w - tp.width) / 2, statY));
      statY += 28;
    }

    // Play Again button
    final btnW = 200.0;
    final btnH = 48.0;
    final btnX = (w - btnW) / 2;
    final btnY = h * 0.72;
    _buttonRect = Rect.fromLTWH(btnX, btnY, btnW, btnH);

    canvas.drawRRect(
      RRect.fromRectAndRadius(_buttonRect!, const Radius.circular(8)),
      Paint()..color = const Color(0xFFffd700),
    );
    tp.text = const TextSpan(
      text: 'PLAY AGAIN',
      style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
    );
    tp.layout();
    tp.paint(canvas, Offset(btnX + (btnW - tp.width) / 2, btnY + (btnH - tp.height) / 2));
  }
}
