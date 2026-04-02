import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'dungeon_room.dart';

class HeroComponent extends PositionComponent {
  static const double renderSize = 32.0;
  static const int frameW = 26;
  static const int frameH = 36;

  static const int charX = 0;
  static const int charY = 0;

  double serverX = 2.0;
  double serverY = 2.0;
  int hp = 100;
  int maxHp = 100;
  int gold = 0;
  List<String> buffs = [];
  Map<String, dynamic> equipment = {};

  ui.Image? spriteSheet;
  int direction = 0;
  int frame = 1;

  // Gold pickup float text
  double _goldFloatTimer = 0;
  int _goldDelta = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    spriteSheet = await Flame.images.load('characters/hero.png');
    size = Vector2.all(renderSize);
    anchor = Anchor.center;
    _updatePosition();
  }

  void updateFromServer(Map<String, dynamic> heroData) {
    final newX = (heroData['x'] as num?)?.toDouble() ?? serverX;
    final newY = (heroData['y'] as num?)?.toDouble() ?? serverY;

    final dx = newX - serverX;
    final dy = newY - serverY;
    if (dx.abs() > 0.1 || dy.abs() > 0.1) {
      if (dx.abs() > dy.abs()) {
        direction = dx > 0 ? 2 : 1;
      } else {
        direction = dy > 0 ? 0 : 3;
      }
      frame = (frame + 1) % 3;
    } else {
      frame = 1;
    }

    serverX = newX;
    serverY = newY;
    hp = heroData['hp'] as int? ?? hp;
    maxHp = heroData['max_hp'] as int? ?? maxHp;

    final newGold = heroData['gold'] as int? ?? gold;
    if (newGold > gold && gold > 0) {
      _goldDelta = newGold - gold;
      _goldFloatTimer = 1.2;
    }
    gold = newGold;

    buffs = (heroData['buffs'] as List<dynamic>? ?? [])
        .map((b) => b.toString())
        .toList();
    equipment = heroData['equipment'] as Map<String, dynamic>? ?? equipment;

    _updatePosition();
  }

  void _updatePosition() {
    position = Vector2(
      32 + serverX * DungeonRoom.tileSize + DungeonRoom.tileSize / 2,
      56 + serverY * DungeonRoom.tileSize + DungeonRoom.tileSize / 2,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_goldFloatTimer > 0) {
      _goldFloatTimer -= dt;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Buff auras
    for (final buff in buffs) {
      final auraColor = switch (buff) {
        'rage' => const Color(0x33f44336),
        'shield' => const Color(0x3342a5f5),
        'haste' => const Color(0x3366bb6a),
        _ => const Color(0x22ffffff),
      };
      canvas.drawCircle(
        Offset(renderSize / 2, renderSize / 2),
        renderSize * 0.7,
        Paint()..color = auraColor,
      );
    }

    // Weapon glow
    final weapon = equipment['weapon'];
    if (weapon != null && weapon != 'none') {
      canvas.drawCircle(
        Offset(renderSize * 0.8, renderSize * 0.3),
        4,
        Paint()..color = const Color(0x55ffab40),
      );
    }

    if (spriteSheet != null) {
      final srcX = (charX + frame * frameW).toDouble();
      final srcY = (charY + direction * frameH).toDouble();
      final src = Rect.fromLTWH(srcX, srcY, frameW.toDouble(), frameH.toDouble());
      final dst = Rect.fromCenter(
        center: Offset(renderSize / 2, renderSize / 2),
        width: renderSize,
        height: renderSize * (frameH / frameW),
      );
      canvas.drawImageRect(spriteSheet!, src, dst, Paint());
    }

    // HP bar
    final hpFraction = maxHp > 0 ? hp / maxHp : 0.0;
    final barY = -12.0;
    canvas.drawRect(
      Rect.fromLTWH(0, barY, renderSize, 4),
      Paint()..color = const Color(0xFF333333),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, barY, renderSize * hpFraction, 4),
      Paint()..color = hpFraction > 0.3 ? const Color(0xFF4caf50) : const Color(0xFFf44336),
    );

    // Gold pickup float text
    if (_goldFloatTimer > 0) {
      final alpha = (_goldFloatTimer / 1.2 * 255).clamp(0, 255).toInt();
      final floatY = -20.0 - (1.2 - _goldFloatTimer) * 20;
      final tp = TextPainter(
        text: TextSpan(
          text: '+${_goldDelta}g',
          style: TextStyle(
            color: Color.fromARGB(alpha, 255, 215, 0),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset((renderSize - tp.width) / 2, floatY));
    }
  }
}
