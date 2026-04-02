import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'dungeon_room.dart';

/// Maps enemy sprite names to sheet file + character index (0-7)
const _enemySprites = {
  'slime': ('characters/animals1.png', 0),     // wolf/cat
  'bat': ('characters/animals1.png', 4),        // fox
  'skeleton': ('characters/military.png', 0),   // soldier
  'goblin': ('characters/elf.png', 4),          // dark elf
  'knight': ('characters/military.png', 4),     // armored
};

class EnemyComponent extends PositionComponent {
  static const double renderSize = 28.0;
  static const int frameW = 26;
  static const int frameH = 36;

  final String name;
  final String spriteName;
  int hp;
  final int maxHp;
  final int enemyId;
  final int serverX;
  final int serverY;

  ui.Image? spriteSheet;
  int frame = 1;
  double animTimer = 0;

  EnemyComponent({
    required this.name,
    required this.spriteName,
    required this.hp,
    required this.maxHp,
    required this.enemyId,
    required this.serverX,
    required this.serverY,
  });

  factory EnemyComponent.fromServer(Map<String, dynamic> data, int idx) {
    return EnemyComponent(
      name: data['name'] as String? ?? 'Enemy',
      spriteName: data['sprite'] as String? ?? 'slime',
      hp: data['hp'] as int? ?? 10,
      maxHp: data['hp'] as int? ?? 10,
      enemyId: data['id'] as int? ?? idx,
      serverX: data['x'] as int? ?? (3 + idx * 2),
      serverY: data['y'] as int? ?? (1 + idx % 2),
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final entry = _enemySprites[spriteName] ?? _enemySprites['slime']!;
    spriteSheet = await Flame.images.load(entry.$1);
    size = Vector2.all(renderSize);
    anchor = Anchor.center;
    _positionInRoom();
  }

  void _positionInRoom() {
    position = Vector2(
      32 + serverX * DungeonRoom.tileSize + DungeonRoom.tileSize / 2,
      56 + serverY * DungeonRoom.tileSize + DungeonRoom.tileSize / 2,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    animTimer += dt;
    if (animTimer > 0.4) {
      animTimer = 0;
      frame = (frame + 1) % 3;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (spriteSheet != null) {
      final entry = _enemySprites[spriteName] ?? _enemySprites['slime']!;
      final charIdx = entry.$2;
      // Character position in sheet: 4 columns, 2 rows of characters
      final charCol = charIdx % 4;
      final charRow = charIdx ~/ 4;
      final blockW = spriteSheet!.width ~/ 4;
      final blockH = spriteSheet!.height ~/ 2;
      final fW = blockW ~/ 3;
      final fH = blockH ~/ 4;

      final srcX = (charCol * blockW + frame * fW).toDouble();
      final srcY = (charRow * blockH).toDouble(); // face down
      final src = Rect.fromLTWH(srcX, srcY, fW.toDouble(), fH.toDouble());
      final dst = Rect.fromCenter(
        center: Offset(renderSize / 2, renderSize / 2),
        width: renderSize,
        height: renderSize * (fH / fW),
      );
      canvas.drawImageRect(spriteSheet!, src, dst, Paint());
    }

    // HP bar
    final hpFraction = maxHp > 0 ? hp / maxHp : 0.0;
    canvas.drawRect(
      Rect.fromLTWH(0, -8, renderSize, 3),
      Paint()..color = const Color(0xFF333333),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, -8, renderSize * hpFraction, 3),
      Paint()..color = const Color(0xFFf44336),
    );

    // Name
    final tp = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(color: Colors.white70, fontSize: 8),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset((renderSize - tp.width) / 2, -16));
  }
}
