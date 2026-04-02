import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class DungeonRoom extends PositionComponent {
  static const double tileSize = 32.0;

  List<List<String>> tiles = [];
  int roomWidth = 0;
  int roomHeight = 0;
  List<Map<String, dynamic>> doors = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(32, 56);
  }

  void updateFromServer(Map<String, dynamic> roomData) {
    final rawTiles = roomData['tiles'] as List<dynamic>? ?? [];
    tiles = rawTiles.map((row) {
      return (row as List<dynamic>).map((t) => t.toString()).toList();
    }).toList();
    roomWidth = roomData['width'] as int? ?? 0;
    roomHeight = roomData['height'] as int? ?? 0;
    doors = (roomData['doors'] as List<dynamic>? ?? [])
        .map((d) => d as Map<String, dynamic>)
        .toList();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (int y = 0; y < tiles.length; y++) {
      final row = tiles[y];
      for (int x = 0; x < row.length; x++) {
        final tile = row[x];
        final dst = Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize);

        // Styled tile rendering
        switch (tile) {
          case 'wall':
            canvas.drawRect(dst, Paint()..color = const Color(0xFF5c3d2e));
            // Brick pattern
            if ((x + y) % 2 == 0) {
              canvas.drawRect(dst, Paint()..color = const Color(0xFF4a3220));
            }
            // Dark edge
            canvas.drawRect(dst, Paint()
              ..color = const Color(0x33000000)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
          case 'floor':
            final shade = ((x + y) % 2 == 0) ? 0xFF3a3a4e : 0xFF2d2d3d;
            canvas.drawRect(dst, Paint()..color = Color(shade));
            // Subtle grid
            canvas.drawRect(dst, Paint()
              ..color = const Color(0x11ffffff)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.5);
          default:
            canvas.drawRect(dst, Paint()..color = const Color(0xFF1a1a2e));
        }
      }
    }

    // Draw doors with highlight
    for (final door in doors) {
      final dx = (door['x'] as int? ?? 0) * tileSize;
      final dy = (door['y'] as int? ?? 0) * tileSize;

      // Door glow
      canvas.drawRect(
        Rect.fromLTWH(dx, dy, tileSize, tileSize),
        Paint()
          ..color = const Color(0x44ffd700)
          ..style = PaintingStyle.fill,
      );
      // Door border
      canvas.drawRect(
        Rect.fromLTWH(dx, dy, tileSize, tileSize),
        Paint()
          ..color = const Color(0xFFc9a84c)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Door label
      final label = door['label'] as String? ?? '';
      if (label.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(color: Color(0xFFffd700), fontSize: 8),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: tileSize * 3);
        tp.paint(canvas, Offset(dx, dy - 10));
      }
    }
  }

}
