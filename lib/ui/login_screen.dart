import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _serverUrl = 'http://localhost:8083';
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });

    try {
      final server = _serverUrl;
      final resp = await http.post(
        Uri.parse('$server/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        _enterGame(
          server,
          body['session_token'] as String,
          body['player_id'] as String,
        );
      } else {
        setState(() => _error = 'Login failed: ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    setState(() { _loading = true; _error = null; });

    try {
      final server = _serverUrl;
      final resp = await http.post(
        Uri.parse('$server/api/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        _enterGame(
          server,
          body['session_token'] as String,
          body['player_id'] as String,
        );
      } else {
        setState(() => _error = 'Register failed: ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _enterGame(String server, String token, String playerId) async {
    setState(() { _loading = true; _error = null; });

    try {
      // Create a new match on the server
      final resp = await http.post(
        Uri.parse('$server/api/v1/crowd_crawl/match'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode != 200) {
        setState(() => _error = 'Failed to create match: ${resp.statusCode}');
        return;
      }

      final matchData = jsonDecode(resp.body) as Map<String, dynamic>;
      final matchId = matchData['match_id'] as String;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameScreen(
            token: token,
            playerId: playerId,
            matchId: matchId,
            serverUrl: server,
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
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CROWD CRAWL',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The crowd decides your fate',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                      child: const Text('LOGIN', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : _register,
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.amber)),
                      child: const Text('REGISTER', style: TextStyle(color: Colors.amber)),
                    ),
                  ),
                ],
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(color: Colors.amber),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
