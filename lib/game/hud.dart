import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Hud extends PositionComponent with HasGameReference {
  String phase = 'exploring';
  int floor = 1;
  int roomsCleared = 0;
  int roomsUntilBoss = 5;
  int hp = 100;
  int maxHp = 100;
  int attack = 10;
  int defense = 5;
  List<Map<String, dynamic>> inventory = [];

  void updateFromState(Map<String, dynamic> state) {
    phase = state['phase'] as String? ?? phase;
    floor = state['floor'] as int? ?? floor;
    roomsCleared = state['rooms_cleared'] as int? ?? roomsCleared;
    roomsUntilBoss = state['rooms_until_boss'] as int? ?? roomsUntilBoss;

    final heroData = state['hero'] as Map<String, dynamic>? ?? {};
    hp = heroData['hp'] as int? ?? hp;
    maxHp = heroData['max_hp'] as int? ?? maxHp;
    attack = heroData['attack'] as int? ?? attack;
    defense = heroData['defense'] as int? ?? defense;

    inventory = (state['inventory'] as List<dynamic>? ?? [])
        .map((i) => i as Map<String, dynamic>)
        .toList();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final screenWidth = game.size.x;

    // Background bar
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenWidth, 48),
      Paint()..color = const Color(0xCC000000),
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // HP
    _drawText(canvas, textPainter, 'HP: $hp/$maxHp', 12, 8, const Color(0xFF4caf50));

    // Stats
    _drawText(canvas, textPainter, 'ATK: $attack  DEF: $defense', 12, 28, const Color(0xFFffc107));

    // Floor info (right side)
    final floorText = 'Floor $floor  Room $roomsCleared  Boss in $roomsUntilBoss';
    _drawText(canvas, textPainter, floorText, screenWidth - 300, 8, const Color(0xFFbbbbbb));

    // Phase
    final phaseColor = switch (phase) {
      'combat' => const Color(0xFFf44336),
      'voting' => const Color(0xFF9c27b0),
      'dead' => const Color(0xFF666666),
      _ => const Color(0xFF4fc3f7),
    };
    _drawText(canvas, textPainter, phase.toUpperCase(), screenWidth - 300, 28, phaseColor);

    // Inventory bar at bottom
    if (inventory.isNotEmpty) {
      final screenHeight = game.size.y;
      canvas.drawRect(
        Rect.fromLTWH(0, screenHeight - 36, screenWidth, 36),
        Paint()..color = const Color(0xCC000000),
      );
      for (int i = 0; i < inventory.length && i < 10; i++) {
        final item = inventory[i];
        final label = (item['label'] as String? ?? '?').substring(0, 1);
        _drawText(canvas, textPainter, '[$label]', 12.0 + i * 50, screenHeight - 28, const Color(0xFFc9a84c));
      }
    }
  }

  void _drawText(Canvas canvas, TextPainter tp, String text, double x, double y, Color color) {
    tp.text = TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: 14, fontFamily: 'monospace'),
    );
    tp.layout();
    tp.paint(canvas, Offset(x, y));
  }
}
