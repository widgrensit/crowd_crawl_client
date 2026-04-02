import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class DungeonRoom extends PositionComponent {
  static const double tileSize = 32.0;

  List<List<String>> tiles = [];
  int roomWidth = 0;
  int roomHeight = 0;
  List<Map<String, dynamic>> doors = [];
  List<Map<String, dynamic>> features = [];

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
    features = (roomData['features'] as List<dynamic>? ?? [])
        .map((f) => f as Map<String, dynamic>)
        .toList();
  }

  void updateFeatures(List<Map<String, dynamic>> newFeatures) {
    features = newFeatures;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (int y = 0; y < tiles.length; y++) {
      final row = tiles[y];
      for (int x = 0; x < row.length; x++) {
        final tile = row[x];
        final dst = Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize);

        switch (tile) {
          case 'wall':
            canvas.drawRect(dst, Paint()..color = const Color(0xFF5c3d2e));
            if ((x + y) % 2 == 0) {
              canvas.drawRect(dst, Paint()..color = const Color(0xFF4a3220));
            }
            canvas.drawRect(dst, Paint()
              ..color = const Color(0x33000000)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
          case 'floor':
            final shade = ((x + y) % 2 == 0) ? 0xFF3a3a4e : 0xFF2d2d3d;
            canvas.drawRect(dst, Paint()..color = Color(shade));
            canvas.drawRect(dst, Paint()
              ..color = const Color(0x11ffffff)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.5);
          default:
            canvas.drawRect(dst, Paint()..color = const Color(0xFF1a1a2e));
        }
      }
    }

    // Draw doors
    for (final door in doors) {
      final dx = (door['x'] as int? ?? 0) * tileSize;
      final dy = (door['y'] as int? ?? 0) * tileSize;

      canvas.drawRect(
        Rect.fromLTWH(dx, dy, tileSize, tileSize),
        Paint()
          ..color = const Color(0x44ffd700)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        Rect.fromLTWH(dx, dy, tileSize, tileSize),
        Paint()
          ..color = const Color(0xFFc9a84c)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

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

    // Draw features
    for (final feature in features) {
      _renderFeature(canvas, feature);
    }
  }

  void _renderFeature(Canvas canvas, Map<String, dynamic> feature) {
    final type = feature['type'] as String? ?? '';
    final fx = (feature['x'] as num?)?.toDouble() ?? 0;
    final fy = (feature['y'] as num?)?.toDouble() ?? 0;
    final cx = fx * tileSize + tileSize / 2;
    final cy = fy * tileSize + tileSize / 2;
    final half = tileSize * 0.35;

    switch (type) {
      case 'chest':
        final opened = feature['opened'] as bool? ?? false;
        final color = opened ? const Color(0xFF7a6633) : const Color(0xFFffd700);
        // Gold square
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: half * 2, height: half * 1.6),
          Paint()..color = color,
        );
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: half * 2, height: half * 1.6),
          Paint()
            ..color = opened ? const Color(0xFF5a4a22) : const Color(0xFFffeb3b)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        // Glow when unopened
        if (!opened) {
          canvas.drawRect(
            Rect.fromCenter(center: Offset(cx, cy), width: half * 2.4, height: half * 2.0),
            Paint()
              ..color = const Color(0x33ffd700)
              ..style = PaintingStyle.fill,
          );
        }

      case 'trap':
        final hidden = feature['hidden'] as bool? ?? true;
        if (hidden) return; // hidden traps are invisible
        final triggered = feature['triggered'] as bool? ?? false;
        final color = triggered ? const Color(0xFF666666) : const Color(0xFFf44336);
        // Red X
        final paint = Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(cx - half * 0.7, cy - half * 0.7), Offset(cx + half * 0.7, cy + half * 0.7), paint);
        canvas.drawLine(Offset(cx + half * 0.7, cy - half * 0.7), Offset(cx - half * 0.7, cy + half * 0.7), paint);

      case 'fountain':
        final used = feature['used'] as bool? ?? false;
        final color = used ? const Color(0xFF666666) : const Color(0xFF42a5f5);
        // Blue diamond
        final path = Path()
          ..moveTo(cx, cy - half)
          ..lineTo(cx + half * 0.7, cy)
          ..lineTo(cx, cy + half)
          ..lineTo(cx - half * 0.7, cy)
          ..close();
        canvas.drawPath(path, Paint()..color = color);
        canvas.drawPath(path, Paint()
          ..color = used ? const Color(0xFF444444) : const Color(0xFF90caf9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
        // Sparkle when unused
        if (!used) {
          canvas.drawCircle(Offset(cx, cy - half * 0.3), 2, Paint()..color = const Color(0xAAe3f2fd));
          canvas.drawCircle(Offset(cx + half * 0.3, cy + half * 0.2), 1.5, Paint()..color = const Color(0xAAbbdefb));
        }
    }
  }
}
