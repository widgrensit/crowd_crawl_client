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
    position = Vector2(32, 32);
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
        final rect = Rect.fromLTWH(
          x * tileSize,
          y * tileSize,
          tileSize,
          tileSize,
        );

        final paint = Paint();
        switch (tile) {
          case 'wall':
            paint.color = const Color(0xFF4a3728);
          case 'floor':
            paint.color = const Color(0xFF2d2d3d);
          default:
            paint.color = const Color(0xFF1a1a2e);
        }
        canvas.drawRect(rect, paint);

        // Grid lines
        final gridPaint = Paint()
          ..color = const Color(0x22ffffff)
          ..style = PaintingStyle.stroke;
        canvas.drawRect(rect, gridPaint);
      }
    }

    // Draw doors
    final doorPaint = Paint()..color = const Color(0xFFc9a84c);
    for (final door in doors) {
      final dx = (door['x'] as int? ?? 0) * tileSize;
      final dy = (door['y'] as int? ?? 0) * tileSize;
      canvas.drawRect(
        Rect.fromLTWH(dx, dy, tileSize, tileSize),
        doorPaint,
      );
    }
  }
}
