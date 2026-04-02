import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dungeon_room.dart';

class HeroComponent extends PositionComponent {
  static const double spriteSize = 28.0;
  double serverX = 4.0;
  double serverY = 4.0;
  int hp = 100;
  int maxHp = 100;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(spriteSize);
    anchor = Anchor.center;
    _updatePosition();
  }

  void updateFromServer(Map<String, dynamic> heroData) {
    serverX = (heroData['x'] as num?)?.toDouble() ?? serverX;
    serverY = (heroData['y'] as num?)?.toDouble() ?? serverY;
    hp = heroData['hp'] as int? ?? hp;
    maxHp = heroData['max_hp'] as int? ?? maxHp;
    _updatePosition();
  }

  void _updatePosition() {
    // Offset by room position (32,32) + half tile for centering
    position = Vector2(
      32 + serverX * DungeonRoom.tileSize + DungeonRoom.tileSize / 2,
      32 + serverY * DungeonRoom.tileSize + DungeonRoom.tileSize / 2,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Hero body
    final bodyPaint = Paint()..color = const Color(0xFF4fc3f7);
    canvas.drawCircle(
      Offset(spriteSize / 2, spriteSize / 2),
      spriteSize / 2 - 2,
      bodyPaint,
    );

    // Hero outline
    final outlinePaint = Paint()
      ..color = const Color(0xFFffffff)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      Offset(spriteSize / 2, spriteSize / 2),
      spriteSize / 2 - 2,
      outlinePaint,
    );

    // HP bar above hero
    final hpBarWidth = spriteSize;
    final hpFraction = maxHp > 0 ? hp / maxHp : 0.0;
    final barY = -8.0;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, barY, hpBarWidth, 4),
      Paint()..color = const Color(0xFF333333),
    );
    // Fill
    canvas.drawRect(
      Rect.fromLTWH(0, barY, hpBarWidth * hpFraction, 4),
      Paint()..color = hpFraction > 0.3 ? const Color(0xFF4caf50) : const Color(0xFFf44336),
    );
  }
}
