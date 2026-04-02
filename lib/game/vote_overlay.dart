import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class VoteOverlay extends PositionComponent with HasGameReference, TapCallbacks {
  final Map<String, dynamic> voteData;
  final void Function(String optionId) onVote;

  List<Map<String, dynamic>> options = [];
  Map<String, int> tallies = {};
  String? selectedOption;
  String? winner;
  int windowMs = 15000;
  double elapsed = 0;

  VoteOverlay({required this.voteData, required this.onVote}) {
    options = (voteData['options'] as List<dynamic>? ?? [])
        .map((o) => o as Map<String, dynamic>)
        .toList();
    windowMs = voteData['window_ms'] as int? ?? 15000;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (winner == null) {
      elapsed += dt * 1000;
    }
  }

  void updateTally(Map<String, dynamic> tallyData) {
    final rawTallies = tallyData['tallies'] as Map<String, dynamic>? ?? {};
    tallies = rawTallies.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  void showResult(Map<String, dynamic> result) {
    winner = result['winner'] as String?;
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (winner != null) return;

    final screenWidth = game.size.x;
    final cardWidth = 100.0;
    final totalWidth = options.length * (cardWidth + 16) - 16;
    final startX = (screenWidth - totalWidth) / 2;
    final cardY = game.size.y / 2 - 80;

    for (int i = 0; i < options.length; i++) {
      final cardX = startX + i * (cardWidth + 16);
      final cardRect = Rect.fromLTWH(cardX, cardY, cardWidth, 140);
      if (cardRect.contains(event.canvasPosition.toOffset())) {
        final optionId = options[i]['id'] as String;
        selectedOption = optionId;
        onVote(optionId);
        return;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final screenWidth = game.size.x;
    final screenHeight = game.size.y;

    // Dimmed background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenWidth, screenHeight),
      Paint()..color = const Color(0x99000000),
    );

    // Title
    final tp = TextPainter(textDirection: TextDirection.ltr);
    final title = winner != null ? 'VOTE RESULT' : 'VOTE NOW!';
    tp.text = TextSpan(
      text: title,
      style: const TextStyle(color: Colors.amber, fontSize: 28, fontWeight: FontWeight.bold),
    );
    tp.layout();
    tp.paint(canvas, Offset((screenWidth - tp.width) / 2, screenHeight / 2 - 130));

    // Timer bar
    if (winner == null) {
      final timerFraction = 1.0 - (elapsed / windowMs).clamp(0.0, 1.0);
      final barWidth = screenWidth * 0.6;
      final barX = (screenWidth - barWidth) / 2;
      canvas.drawRect(
        Rect.fromLTWH(barX, screenHeight / 2 - 100, barWidth, 6),
        Paint()..color = const Color(0xFF333333),
      );
      canvas.drawRect(
        Rect.fromLTWH(barX, screenHeight / 2 - 100, barWidth * timerFraction, 6),
        Paint()..color = Colors.amber,
      );
    }

    // Cards
    final cardWidth = 100.0;
    final cardHeight = 140.0;
    final totalWidth = options.length * (cardWidth + 16) - 16;
    final startX = (screenWidth - totalWidth) / 2;
    final cardY = screenHeight / 2 - 80;

    for (int i = 0; i < options.length; i++) {
      final option = options[i];
      final optionId = option['id'] as String;
      final label = option['label'] as String? ?? '???';
      final cardX = startX + i * (cardWidth + 16);

      final isSelected = selectedOption == optionId;
      final isWinner = winner == optionId;

      // Card background
      Color cardColor;
      if (isWinner) {
        cardColor = const Color(0xFFffd700);
      } else if (winner != null) {
        cardColor = const Color(0xFF333333);
      } else if (isSelected) {
        cardColor = const Color(0xFF6a1b9a);
      } else {
        cardColor = const Color(0xFF3e2723);
      }

      final cardRect = Rect.fromLTWH(cardX, cardY, cardWidth, cardHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(8)),
        Paint()..color = cardColor,
      );

      // Card border
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(8)),
        Paint()
          ..color = isWinner ? Colors.amber : const Color(0xFF8d6e63)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isWinner ? 3 : 1.5,
      );

      // Tarot name
      final tarot = option['tarot'] as String? ?? '';
      tp.text = TextSpan(
        text: tarot.toUpperCase(),
        style: TextStyle(
          color: isWinner ? Colors.black : const Color(0xFFc9a84c),
          fontSize: 10,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(cardX + (cardWidth - tp.width) / 2, cardY + 8));

      // Label (wrapped)
      tp.text = TextSpan(
        text: label,
        style: TextStyle(
          color: isWinner ? Colors.black : Colors.white,
          fontSize: 11,
        ),
      );
      tp.layout(maxWidth: cardWidth - 12);
      tp.paint(canvas, Offset(cardX + 6, cardY + 60));

      // Tally count
      final count = tallies[optionId] ?? 0;
      if (count > 0 || winner != null) {
        tp.text = TextSpan(
          text: '$count votes',
          style: TextStyle(
            color: isWinner ? Colors.black87 : const Color(0xFFaaaaaa),
            fontSize: 10,
          ),
        );
        tp.layout();
        tp.paint(canvas, Offset(cardX + (cardWidth - tp.width) / 2, cardY + cardHeight - 20));
      }
    }
  }
}
