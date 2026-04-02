import 'package:flame/game.dart';
import 'package:flutter/material.dart';
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

class GameScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final game = CrowdCrawlFlameGame(
      token: token,
      playerId: playerId,
      matchId: matchId,
      serverUrl: serverUrl,
    );

    return Scaffold(
      body: GameWidget(game: game),
    );
  }
}
