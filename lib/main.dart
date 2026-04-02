import 'dart:convert';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'game/crowd_crawl_game.dart';
import 'ui/login_screen.dart';

void main() {
  runApp(const CrowdCrawlApp());
}

class CrowdCrawlApp extends StatelessWidget {
  const CrowdCrawlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crowd Crawl',
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.deepPurple,
        ),
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameScreen extends StatefulWidget {
  final String token;
  final String playerId;
  final String matchId;
  final String serverUrl;

  const GameScreen({
    super.key,
    required this.token,
    required this.playerId,
    required this.matchId,
    required this.serverUrl,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late CrowdCrawlFlameGame _game;

  @override
  void initState() {
    super.initState();
    _game = _createGame(widget.matchId);
  }

  CrowdCrawlFlameGame _createGame(String matchId) {
    return CrowdCrawlFlameGame(
      token: widget.token,
      playerId: widget.playerId,
      matchId: matchId,
      serverUrl: widget.serverUrl,
      onPlayAgain: _handlePlayAgain,
    );
  }

  Future<void> _handlePlayAgain() async {
    try {
      final resp = await http.post(
        Uri.parse('${widget.serverUrl}/api/v1/crowd_crawl/match'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (resp.statusCode == 200) {
        final matchData = jsonDecode(resp.body) as Map<String, dynamic>;
        final newMatchId = matchData['match_id'] as String;
        setState(() {
          _game = _createGame(newMatchId);
        });
      }
    } catch (_) {
      // Stay on game over screen if match creation fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(game: _game),
    );
  }
}
