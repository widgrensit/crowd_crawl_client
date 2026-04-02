import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../network/asobi_connection.dart';
import 'dungeon_room.dart';
import 'hero_component.dart';
import 'enemy_component.dart';
import 'hud.dart';
import 'vote_overlay.dart';
import 'combat_flash.dart';
import 'game_over_overlay.dart';

class CrowdCrawlFlameGame extends FlameGame with KeyboardEvents, HasCollisionDetection {
  final String token;
  final String playerId;
  final String matchId;
  final String serverUrl;
  final VoidCallback? onPlayAgain;

  late AsobiConnection connection;
  late DungeonRoom dungeonRoom;
  late HeroComponent hero;
  late Hud hud;
  VoteOverlay? voteOverlay;
  GameOverOverlay? gameOverOverlay;
  _FloorTransitionOverlay? _floorOverlay;

  Map<String, dynamic> gameState = {};
  List<EnemyComponent> enemies = [];
  StreamSubscription? _eventSub;

  int currentTarget = 0;
  int _lastFloor = 1;
  bool _gameOverShown = false;

  CrowdCrawlFlameGame({
    required this.token,
    required this.playerId,
    required this.matchId,
    required this.serverUrl,
    this.onPlayAgain,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.anchor = Anchor.topLeft;

    dungeonRoom = DungeonRoom();
    hero = HeroComponent();
    hud = Hud();

    await add(dungeonRoom);
    await add(hero);
    await add(hud);

    connection = AsobiConnection(serverUrl: serverUrl, token: token);
    await connection.connect();
    await connection.joinMatch(matchId);

    _eventSub = connection.events.listen(_handleEvent);
  }

  void _handleEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    final payload = event['payload'] as Map<String, dynamic>? ?? {};

    switch (type) {
      case 'match.state':
        _updateGameState(payload);
      case 'match.vote_start':
        _showVote(payload);
      case 'match.vote_tally':
        voteOverlay?.updateTally(payload);
      case 'match.vote_result':
        _hideVote(payload);
    }
  }

  int _lastHeroHp = 100;
  int _lastEnemyCount = 0;

  void _updateGameState(Map<String, dynamic> state) {
    gameState = state;

    final heroData = state['hero'] as Map<String, dynamic>? ?? {};
    final newHp = heroData['hp'] as int? ?? _lastHeroHp;
    final enemyList = state['enemies'] as List<dynamic>? ?? [];

    if (newHp < _lastHeroHp) {
      add(CombatFlash(color: const Color(0x44ff0000)));
    }
    if (enemyList.length < _lastEnemyCount) {
      add(CombatFlash(color: const Color(0x33ffffff), lifetime: 0.1));
    }
    _lastHeroHp = newHp;
    _lastEnemyCount = enemyList.length;

    hero.updateFromServer(heroData);
    hud.updateFromState(state);

    final roomData = state['room'] as Map<String, dynamic>?;
    if (roomData != null) {
      dungeonRoom.updateFromServer(roomData);
    }

    // Update features from top-level state (visible_features filtered by server)
    final features = (state['features'] as List<dynamic>? ?? [])
        .map((f) => f as Map<String, dynamic>)
        .toList();
    dungeonRoom.updateFeatures(features);

    _updateEnemies(enemyList);

    // Floor transition detection
    final newFloor = state['floor'] as int? ?? _lastFloor;
    if (newFloor > _lastFloor) {
      _showFloorTransition(newFloor);
    }
    _lastFloor = newFloor;

    // Clamp target index
    if (enemies.isNotEmpty) {
      currentTarget = currentTarget.clamp(0, enemies.length - 1);
    } else {
      currentTarget = 0;
    }
    _updateTargetIndicators();

    // Game over
    final phase = state['phase'] as String? ?? 'exploring';
    if ((phase == 'dead' || phase == 'won') && !_gameOverShown) {
      _showGameOver(state, phase == 'won');
    }
  }

  void _updateEnemies(List<dynamic> enemyData) {
    final serverIds = <int>{};
    for (final data in enemyData) {
      final d = data as Map<String, dynamic>;
      final id = d['id'] as int? ?? 0;
      serverIds.add(id);

      final existing = enemies.where((e) => e.enemyId == id).firstOrNull;
      if (existing != null) {
        existing.updateFromServer(d);
      } else {
        final enemy = EnemyComponent.fromServer(d, enemies.length);
        enemies.add(enemy);
        add(enemy);
      }
    }

    final dead = enemies.where((e) => !serverIds.contains(e.enemyId)).toList();
    for (final e in dead) {
      e.removeFromParent();
      enemies.remove(e);
    }
  }

  void _updateTargetIndicators() {
    for (int i = 0; i < enemies.length; i++) {
      enemies[i].isTargeted = (i == currentTarget);
    }
  }

  void _showFloorTransition(int newFloor) {
    _floorOverlay?.removeFromParent();
    _floorOverlay = _FloorTransitionOverlay(floor: newFloor);
    add(_floorOverlay!);
  }

  void _showGameOver(Map<String, dynamic> state, bool victory) {
    _gameOverShown = true;
    gameOverOverlay?.removeFromParent();
    gameOverOverlay = GameOverOverlay(
      victory: victory,
      score: state['score'] as int? ?? 0,
      floorsCleared: (state['floor'] as int? ?? 1) - 1,
      roomsCleared: state['rooms_cleared'] as int? ?? 0,
      enemiesKilled: state['enemies_killed'] as int? ?? 0,
      gold: state['gold'] as int? ?? 0,
      boonsCollected: (state['inventory'] as List<dynamic>? ?? []).length,
      onPlayAgain: () {
        onPlayAgain?.call();
      },
    );
    add(gameOverOverlay!);
  }

  void _showVote(Map<String, dynamic> payload) {
    voteOverlay?.removeFromParent();
    voteOverlay = VoteOverlay(
      voteData: payload,
      onVote: (optionId) {
        final voteId = payload['vote_id'] as String;
        connection.castVote(voteId, optionId);
      },
    );
    add(voteOverlay!);
  }

  void _hideVote(Map<String, dynamic> result) {
    voteOverlay?.showResult(result);
    Future.delayed(const Duration(seconds: 3), () {
      voteOverlay?.removeFromParent();
      voteOverlay = null;
    });
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_gameOverShown) return KeyEventResult.ignored;

    // Movement
    String? direction;
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      direction = 'up';
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
        keysPressed.contains(LogicalKeyboardKey.keyS)) {
      direction = 'down';
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA)) {
      direction = 'left';
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD)) {
      direction = 'right';
    }

    if (direction != null) {
      connection.sendInput({'action': 'move', 'direction': direction});
      return KeyEventResult.handled;
    }

    // Attack (space) — with current target
    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      connection.sendInput({'action': 'attack', 'target': currentTarget});
      return KeyEventResult.handled;
    }

    // Interact (E) — chests, fountains
    if (keysPressed.contains(LogicalKeyboardKey.keyE)) {
      connection.sendInput({'action': 'interact'});
      return KeyEventResult.handled;
    }

    // Heal (H)
    if (keysPressed.contains(LogicalKeyboardKey.keyH)) {
      connection.sendInput({'action': 'heal'});
      return KeyEventResult.handled;
    }

    // Dodge (Q)
    if (keysPressed.contains(LogicalKeyboardKey.keyQ)) {
      connection.sendInput({'action': 'dodge'});
      return KeyEventResult.handled;
    }

    // Target specific enemy (1-5)
    for (int i = 0; i < 5; i++) {
      final key = [
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.digit3,
        LogicalKeyboardKey.digit4,
        LogicalKeyboardKey.digit5,
      ][i];
      if (keysPressed.contains(key)) {
        if (i < enemies.length) {
          currentTarget = i;
          _updateTargetIndicators();
        }
        return KeyEventResult.handled;
      }
    }

    // Cycle target (Tab)
    if (keysPressed.contains(LogicalKeyboardKey.tab)) {
      if (enemies.isNotEmpty) {
        currentTarget = (currentTarget + 1) % enemies.length;
        _updateTargetIndicators();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void onRemove() {
    _eventSub?.cancel();
    connection.disconnect();
    super.onRemove();
  }

  @override
  Color backgroundColor() => const Color(0xFF1a1a2e);
}

class _FloorTransitionOverlay extends PositionComponent with HasGameReference {
  final int floor;
  double elapsed = 0;
  static const double duration = 2.0;

  _FloorTransitionOverlay({required this.floor});

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    if (elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final alpha = (1.0 - elapsed / duration).clamp(0.0, 1.0);
    final w = game.size.x;
    final h = game.size.y;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = Color.fromARGB((alpha * 180).toInt(), 0, 0, 0),
    );

    final tp = TextPainter(
      text: TextSpan(
        text: 'FLOOR $floor',
        style: TextStyle(
          color: Color.fromARGB((alpha * 255).toInt(), 255, 215, 0),
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset((w - tp.width) / 2, h * 0.4));

    final tp2 = TextPainter(
      text: TextSpan(
        text: 'Cleared!',
        style: TextStyle(
          color: Color.fromARGB((alpha * 200).toInt(), 255, 255, 255),
          fontSize: 24,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp2.layout();
    tp2.paint(canvas, Offset((w - tp2.width) / 2, h * 0.4 + 56));
  }
}
