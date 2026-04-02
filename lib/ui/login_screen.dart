import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static String get _serverUrl {
    final base = Uri.base;
    if (base.host == 'localhost' || base.host == '127.0.0.1') {
      return 'http://localhost:8083';
    }
    return '${base.scheme}://${base.host}';
  }
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _autoStart();
  }

  Future<void> _autoStart() async {
    setState(() { _loading = true; _error = null; });

    try {
      // Generate random guest name
      final guest = 'hero_${Random().nextInt(999999)}';
      final password = 'guest_${Random().nextInt(999999)}';

      // Try register (ignore if already exists)
      final regResp = await http.post(
        Uri.parse('$_serverUrl/api/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': guest, 'password': password}),
      );

      String token;
      String playerId;

      if (regResp.statusCode == 200) {
        final body = jsonDecode(regResp.body) as Map<String, dynamic>;
        token = body['session_token'] as String;
        playerId = body['player_id'] as String;
      } else {
        setState(() => _error = 'Failed to connect: ${regResp.statusCode}');
        return;
      }

      // Create match
      final matchResp = await http.post(
        Uri.parse('$_serverUrl/api/v1/crowd_crawl/match'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (matchResp.statusCode != 200) {
        setState(() => _error = 'Failed to create match: ${matchResp.statusCode}');
        return;
      }

      final matchData = jsonDecode(matchResp.body) as Map<String, dynamic>;
      final matchId = matchData['match_id'] as String;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameScreen(
            token: token,
            playerId: playerId,
            matchId: matchId,
            serverUrl: _serverUrl,
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CROWD CRAWL',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The crowd decides your fate',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 48),
            if (_loading)
              const Column(
                children: [
                  CircularProgressIndicator(color: Colors.amber),
                  SizedBox(height: 16),
                  Text('Entering dungeon...', style: TextStyle(color: Colors.white38)),
                ],
              ),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _autoStart,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: const Text('RETRY', style: TextStyle(color: Colors.black)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
