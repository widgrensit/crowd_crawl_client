import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class AsobiConnection {
  final String serverUrl;
  final String token;
  WebSocketChannel? _channel;
  int _cidCounter = 0;
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  final Map<String, Completer<Map<String, dynamic>>> _pending = {};
  Timer? _heartbeat;

  AsobiConnection({required this.serverUrl, required this.token});

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  Future<void> connect() async {
    final wsUrl = serverUrl.replaceFirst('http', 'ws');
    _channel = WebSocketChannel.connect(Uri.parse('$wsUrl/ws'));

    _channel!.stream.listen(
      (data) => _handleMessage(jsonDecode(data as String)),
      onError: (e) => _eventController.addError(e),
      onDone: () => _eventController.add({'type': 'disconnected'}),
    );

    await authenticate();
    _startHeartbeat();
  }

  Future<Map<String, dynamic>> authenticate() async {
    return sendAndWait('session.connect', {'token': token});
  }

  Future<Map<String, dynamic>> joinMatch(String matchId) async {
    return sendAndWait('match.join', {'match_id': matchId});
  }

  void sendInput(Map<String, dynamic> input) {
    send('match.input', {'data': input});
  }

  void castVote(String voteId, String optionId) {
    send('vote.cast', {'vote_id': voteId, 'option_id': optionId});
  }

  void send(String type, Map<String, dynamic> payload) {
    final msg = {'type': type, 'payload': payload};
    _channel?.sink.add(jsonEncode(msg));
  }

  Future<Map<String, dynamic>> sendAndWait(
    String type,
    Map<String, dynamic> payload, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    final cid = (++_cidCounter).toString();
    final completer = Completer<Map<String, dynamic>>();
    _pending[cid] = completer;

    final msg = {'type': type, 'payload': payload, 'cid': cid};
    _channel?.sink.add(jsonEncode(msg));

    return completer.future.timeout(timeout, onTimeout: () {
      _pending.remove(cid);
      throw TimeoutException('$type timed out');
    });
  }

  void _handleMessage(Map<String, dynamic> msg) {
    final cid = msg['cid'] as String?;
    if (cid != null && _pending.containsKey(cid)) {
      _pending.remove(cid)!.complete(msg);
    }
    _eventController.add(msg);
  }

  void _startHeartbeat() {
    _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
      send('session.heartbeat', {});
    });
  }

  void disconnect() {
    _heartbeat?.cancel();
    _channel?.sink.close();
    _eventController.close();
  }
}
