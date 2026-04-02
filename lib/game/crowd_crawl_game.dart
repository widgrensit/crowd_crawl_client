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

class CrowdCrawlFlameGame extends FlameGame with KeyboardEvents, HasCollisionDetection {
  final String token;
  final String playerId;
  final String matchId;
  final String serverUrl;

  late AsobiConnection connection;
  late DungeonRoom dungeonRoom;
  late HeroComponent hero;
  late Hud hud;
  VoteOverlay? voteOverlay;

  Map<String, dynamic> gameState = {};
  List<EnemyComponent> enemies = [];
  StreamSubscription? _eventSub;

  CrowdCrawlFlameGame({
    required this.token,
    required this.playerId,
    required this.matchId,
    required this.serverUrl,
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

  void _updateGameState(Map<String, dynamic> state) {
    gameState = state;

    final heroData = state['hero'] as Map<String, dynamic>? ?? {};
    hero.updateFromServer(heroData);
    hud.updateFromState(state);

    final roomData = state['room'] as Map<String, dynamic>?;
    if (roomData != null) {
      dungeonRoom.updateFromServer(roomData);
    }

    _updateEnemies(state['enemies'] as List<dynamic>? ?? []);
  }

  void _updateEnemies(List<dynamic> enemyData) {
    for (final e in enemies) {
      e.removeFromParent();
    }
    enemies.clear();

    for (final data in enemyData) {
      final enemy = EnemyComponent.fromServer(data as Map<String, dynamic>);
      enemies.add(enemy);
      add(enemy);
    }
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
    if (event is KeyDownEvent) {
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
      } else if (keysPressed.contains(LogicalKeyboardKey.space)) {
        connection.sendInput({'action': 'attack'});
        return KeyEventResult.handled;
      }

      if (direction != null) {
        connection.sendInput({'action': 'move', 'direction': direction});
        return KeyEventResult.handled;
      }
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
