import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Brief screen flash when attacking or taking damage
class CombatFlash extends PositionComponent with HasGameReference {
  final Color color;
  double lifetime;
  double elapsed = 0;

  CombatFlash({this.color = const Color(0x44ff0000), this.lifetime = 0.15});

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    if (elapsed >= lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final opacity = (1.0 - elapsed / lifetime).clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      Paint()..color = color.withValues(alpha: color.a / 255 * opacity),
    );
  }
}
