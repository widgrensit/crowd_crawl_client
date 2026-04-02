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
  int gold = 0;
  int score = 0;
  int enemiesKilled = 0;
  bool isBossRoom = false;
  Map<String, dynamic> equipment = {};
  List<Map<String, dynamic>> inventory = [];

  void updateFromState(Map<String, dynamic> state) {
    phase = state['phase'] as String? ?? phase;
    floor = state['floor'] as int? ?? floor;
    roomsCleared = state['rooms_cleared'] as int? ?? roomsCleared;
    roomsUntilBoss = state['rooms_until_boss'] as int? ?? roomsUntilBoss;
    gold = state['gold'] as int? ?? gold;
    score = state['score'] as int? ?? score;
    enemiesKilled = state['enemies_killed'] as int? ?? enemiesKilled;
    isBossRoom = state['is_boss_room'] as bool? ?? isBossRoom;

    final heroData = state['hero'] as Map<String, dynamic>? ?? {};
    hp = heroData['hp'] as int? ?? hp;
    maxHp = heroData['max_hp'] as int? ?? maxHp;
    attack = heroData['attack'] as int? ?? attack;
    defense = heroData['defense'] as int? ?? defense;

    equipment = state['equipment'] as Map<String, dynamic>? ?? equipment;

    inventory = (state['inventory'] as List<dynamic>? ?? [])
        .map((i) => i as Map<String, dynamic>)
        .toList();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final screenWidth = game.size.x;
    final screenHeight = game.size.y;

    // Top bar background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenWidth, 48),
      Paint()..color = const Color(0xCC000000),
    );

    final tp = TextPainter(textDirection: TextDirection.ltr);

    // HP
    _drawText(canvas, tp, 'HP: $hp/$maxHp', 12, 4, const Color(0xFF4caf50));

    // Stats
    _drawText(canvas, tp, 'ATK: $attack  DEF: $defense', 12, 20, const Color(0xFFffc107));

    // Gold + Score + Kills (center area)
    final centerX = screenWidth * 0.35;
    _drawText(canvas, tp, '\u2B50$score', centerX, 4, const Color(0xFFffd700));
    _drawText(canvas, tp, '\u{1FA99}$gold  \u2620$enemiesKilled', centerX, 20, const Color(0xFFe0e0e0));

    // Floor info (right side)
    final rightX = screenWidth - 260;
    final floorLabel = 'FLOOR $floor';
    _drawText(canvas, tp, floorLabel, rightX, 4, const Color(0xFFe0e0e0), fontSize: 16, bold: true);

    if (isBossRoom) {
      _drawText(canvas, tp, '  BOSS', rightX + 80, 4, const Color(0xFFf44336), fontSize: 16, bold: true);
    }

    _drawText(canvas, tp, 'Room $roomsCleared  Boss in $roomsUntilBoss', rightX, 24, const Color(0xFF999999));

    // Phase indicator (far right)
    final phaseColor = switch (phase) {
      'combat' => const Color(0xFFf44336),
      'voting' => const Color(0xFF9c27b0),
      'dead' => const Color(0xFF666666),
      'won' => const Color(0xFFffd700),
      _ => const Color(0xFF4fc3f7),
    };
    _drawText(canvas, tp, phase.toUpperCase(), screenWidth - 90, 4, phaseColor, fontSize: 12);

    // Equipment row (below top bar)
    final equipY = 52.0;
    final weapon = equipment['weapon'];
    final armor = equipment['armor'];
    final accessory = equipment['accessory'];
    if (weapon != null && weapon != 'none' ||
        armor != null && armor != 'none' ||
        accessory != null && accessory != 'none') {
      canvas.drawRect(
        Rect.fromLTWH(0, equipY - 2, screenWidth, 18),
        Paint()..color = const Color(0x88000000),
      );
      var eqX = 12.0;
      if (weapon != null && weapon != 'none') {
        _drawText(canvas, tp, '\u2694$weapon', eqX, equipY, const Color(0xFFef5350), fontSize: 10);
        eqX += tp.width + 16;
      }
      if (armor != null && armor != 'none') {
        _drawText(canvas, tp, '\u{1F6E1}$armor', eqX, equipY, const Color(0xFF42a5f5), fontSize: 10);
        eqX += tp.width + 16;
      }
      if (accessory != null && accessory != 'none') {
        _drawText(canvas, tp, '\u{1F48D}$accessory', eqX, equipY, const Color(0xFFab47bc), fontSize: 10);
      }
    }

    // Inventory bar at bottom
    if (inventory.isNotEmpty) {
      canvas.drawRect(
        Rect.fromLTWH(0, screenHeight - 40, screenWidth, 40),
        Paint()..color = const Color(0xCC000000),
      );
      for (int i = 0; i < inventory.length && i < 10; i++) {
        final item = inventory[i];
        final label = item['label'] as String? ?? '?';
        final kind = item['kind'] as String? ?? 'passive';
        final rarity = item['rarity'] as String? ?? 'common';
        final shortLabel = label.length > 6 ? label.substring(0, 6) : label;

        final rarityColor = _rarityColor(rarity);
        final kindPrefix = kind == 'active' ? '\u25B6' : '\u25CF';

        final x = 8.0 + i * 72;
        final y = screenHeight - 32;

        // Rarity-colored border
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x - 2, y - 4, 66, 26), const Radius.circular(3)),
          Paint()
            ..color = rarityColor.withAlpha(80)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x - 2, y - 4, 66, 26), const Radius.circular(3)),
          Paint()
            ..color = rarityColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );

        _drawText(canvas, tp, '$kindPrefix$shortLabel', x + 2, y, rarityColor, fontSize: 11);
      }
    }
  }

  static Color _rarityColor(String rarity) {
    return switch (rarity) {
      'rare' => const Color(0xFF42a5f5),
      'legendary' => const Color(0xFFffd700),
      _ => const Color(0xFFe0e0e0),
    };
  }

  void _drawText(
    Canvas canvas,
    TextPainter tp,
    String text,
    double x,
    double y,
    Color color, {
    double fontSize = 14,
    bool bold = false,
  }) {
    tp.text = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontFamily: 'monospace',
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset(x, y));
  }
}
