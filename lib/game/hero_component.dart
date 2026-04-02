import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'dungeon_room.dart';

class HeroComponent extends PositionComponent {
  static const double renderSize = 32.0;
  static const int frameW = 26;
  static const int frameH = 36;

  // Dwarf1 is first character in the sheet (top-left block)
  // Character block at (0,0), each block is 78x144
  // 3 frames across, 4 directions down: down=0, left=1, right=2, up=3
  static const int charX = 0;
  static const int charY = 0;

  double serverX = 2.0;
  double serverY = 2.0;
  int hp = 100;
  int maxHp = 100;

  ui.Image? spriteSheet;
  int direction = 0; // 0=down, 1=left, 2=right, 3=up
  int frame = 1; // 0,1,2 walk cycle (1 = idle)
  double animTimer = 0;
  String lastDir = '';

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

    // Determine direction from movement
    final dx = newX - serverX;
    final dy = newY - serverY;
    if (dx.abs() > 0.1 || dy.abs() > 0.1) {
      if (dx.abs() > dy.abs()) {
        direction = dx > 0 ? 2 : 1; // right : left
      } else {
        direction = dy > 0 ? 0 : 3; // down : up
      }
      // Advance walk cycle
      frame = (frame + 1) % 3;
    } else {
      frame = 1; // idle
    }

    serverX = newX;
    serverY = newY;
    hp = heroData['hp'] as int? ?? hp;
    maxHp = heroData['max_hp'] as int? ?? maxHp;
    _updatePosition();
  }

  void _updatePosition() {
    position = Vector2(
      32 + serverX * DungeonRoom.tileSize + DungeonRoom.tileSize / 2,
      56 + serverY * DungeonRoom.tileSize + DungeonRoom.tileSize / 2,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

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
  }
}
