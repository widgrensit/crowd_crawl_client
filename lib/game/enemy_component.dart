import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'dungeon_room.dart';

const _enemySprites = {
  'slime': ('characters/animals1.png', 0),
  'bat': ('characters/animals1.png', 4),
  'skeleton': ('characters/military.png', 0),
  'goblin': ('characters/elf.png', 4),
  'knight': ('characters/military.png', 4),
};

class EnemyComponent extends PositionComponent {
  static const double baseRenderSize = 28.0;

  final String name;
  final String spriteName;
  final String behavior;
  final bool isBoss;
  int hp;
  final int maxHp;
  final int enemyId;
  int serverX;
  int serverY;
  bool isTargeted = false;

  ui.Image? spriteSheet;
  int frame = 1;
  double animTimer = 0;
  double targetPulse = 0;

  double get renderSize => isBoss ? baseRenderSize * 1.5 : baseRenderSize;

  EnemyComponent({
    required this.name,
    required this.spriteName,
    required this.behavior,
    required this.isBoss,
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
      behavior: data['behavior'] as String? ?? 'melee',
      isBoss: data['is_boss'] as bool? ?? false,
      hp: data['hp'] as int? ?? 10,
      maxHp: data['hp'] as int? ?? 10,
      enemyId: data['id'] as int? ?? idx,
      serverX: data['x'] as int? ?? (3 + idx * 2),
      serverY: data['y'] as int? ?? (1 + idx % 2),
    );
  }

  void updateFromServer(Map<String, dynamic> data) {
    hp = data['hp'] as int? ?? hp;
    serverX = data['x'] as int? ?? serverX;
    serverY = data['y'] as int? ?? serverY;
    _positionInRoom();
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
    targetPulse += dt * 4;
  }

  Color get _behaviorColor => switch (behavior) {
    'ranged' => const Color(0xFFce93d8),
    'tank' => const Color(0xFF90a4ae),
    _ => const Color(0xFFef5350),
  };

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rs = renderSize;

    // Target indicator
    if (isTargeted) {
      final pulse = 0.8 + 0.2 * (1 + (targetPulse % 6.28 - 3.14).abs() / 3.14);
      final radius = rs * 0.6 * pulse;
      canvas.drawCircle(
        Offset(rs / 2, rs / 2),
        radius,
        Paint()
          ..color = const Color(0x44ffeb3b)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(rs / 2, rs / 2),
        radius,
        Paint()
          ..color = const Color(0xCCffeb3b)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Behavior color tint behind sprite
    canvas.drawCircle(
      Offset(rs / 2, rs / 2),
      rs * 0.3,
      Paint()..color = _behaviorColor.withAlpha(40),
    );

    if (spriteSheet != null) {
      final entry = _enemySprites[spriteName] ?? _enemySprites['slime']!;
      final charIdx = entry.$2;
      final charCol = charIdx % 4;
      final charRow = charIdx ~/ 4;
      final blockW = spriteSheet!.width ~/ 4;
      final blockH = spriteSheet!.height ~/ 2;
      final fW = blockW ~/ 3;
      final fH = blockH ~/ 4;

      final srcX = (charCol * blockW + frame * fW).toDouble();
      final srcY = (charRow * blockH).toDouble();
      final src = Rect.fromLTWH(srcX, srcY, fW.toDouble(), fH.toDouble());
      final dst = Rect.fromCenter(
        center: Offset(rs / 2, rs / 2),
        width: rs,
        height: rs * (fH / fW),
      );
      canvas.drawImageRect(spriteSheet!, src, dst, Paint());
    }

    // Boss crown indicator
    if (isBoss) {
      final tp = TextPainter(
        text: const TextSpan(
          text: '\u{1F451}',
          style: TextStyle(fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset((rs - tp.width) / 2, -22));
    }

    // HP bar
    final hpFraction = maxHp > 0 ? hp / maxHp : 0.0;
    final barY = isBoss ? -10.0 : -8.0;
    final barW = rs;
    canvas.drawRect(
      Rect.fromLTWH(0, barY, barW, 3),
      Paint()..color = const Color(0xFF333333),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, barY, barW * hpFraction, 3),
      Paint()..color = const Color(0xFFf44336),
    );

    // Name + behavior label
    final nameLabel = isBoss ? '\u2605 $name' : name;
    final tp = TextPainter(
      text: TextSpan(
        text: nameLabel,
        style: TextStyle(color: _behaviorColor, fontSize: isBoss ? 10.0 : 8.0),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset((rs - tp.width) / 2, barY - 12));
  }
}
