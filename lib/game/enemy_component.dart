import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dungeon_room.dart';

class EnemyComponent extends PositionComponent {
  static const double spriteSize = 24.0;
  final String name;
  int hp;
  final int maxHp;

  EnemyComponent({required this.name, required this.hp, required this.maxHp});

  factory EnemyComponent.fromServer(Map<String, dynamic> data) {
    return EnemyComponent(
      name: data['name'] as String? ?? 'Enemy',
      hp: data['hp'] as int? ?? 10,
      maxHp: data['hp'] as int? ?? 10,
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(spriteSize);
    anchor = Anchor.center;
    // Position randomly in room for now — server should send positions
    position = Vector2(
      32 + 3 * DungeonRoom.tileSize + DungeonRoom.tileSize / 2,
      32 + 3 * DungeonRoom.tileSize + DungeonRoom.tileSize / 2,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Enemy body (red)
    final bodyPaint = Paint()..color = const Color(0xFFe53935);
    canvas.drawRect(
      Rect.fromLTWH(2, 2, spriteSize - 4, spriteSize - 4),
      bodyPaint,
    );

    // Outline
    final outlinePaint = Paint()
      ..color = const Color(0xFFff8a80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(
      Rect.fromLTWH(2, 2, spriteSize - 4, spriteSize - 4),
      outlinePaint,
    );

    // HP bar
    final hpFraction = maxHp > 0 ? hp / maxHp : 0.0;
    canvas.drawRect(
      Rect.fromLTWH(0, -6, spriteSize, 3),
      Paint()..color = const Color(0xFF333333),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, -6, spriteSize * hpFraction, 3),
      Paint()..color = const Color(0xFFf44336),
    );
  }
}
