import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/constants.dart';
import '../models/chat.dart';
import 'api_client.dart';

class ChatService {
  final ApiClient _client;
  final FlutterSecureStorage _storage;
  WebSocketChannel? _channel;
  StreamController<Message>? _messageController;

  ChatService({
    required ApiClient client,
    required FlutterSecureStorage storage,
  })  : _client = client,
        _storage = storage;

  Future<Chat> createChat(String matchId) async {
    final response = await _client.dio.post(
      '/chats',
      queryParameters: {'match_id': matchId},
    );
    return Chat.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Chat>> listChats() async {
    final response = await _client.dio.get('/chats');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => Chat.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Message>> getChatHistory(String chatId,
      {int limit = 50, int offset = 0}) async {
    final response = await _client.dio.get(
      '/chats/$chatId/messages',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((json) => Message.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Stream<Message> connectToChat(String chatId) {
    _messageController = StreamController<Message>.broadcast();

    _initWebSocket(chatId);

    return _messageController!.stream;
  }

  Future<void> _initWebSocket(String chatId) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;

    final baseUrl = AppConstants.apiBaseUrl.replaceFirst('http', 'ws');
    final wsUrl = Uri.parse('$baseUrl/chats/$chatId/ws?token=$token');

    _channel = WebSocketChannel.connect(wsUrl);

    _channel!.stream.listen(
      (data) {
        if (_messageController == null || _messageController!.isClosed) return;
        final json = jsonDecode(data as String) as Map<String, dynamic>;
        _messageController!.add(Message.fromJson(json));
      },
      onError: (error) {
        if (_messageController != null && !_messageController!.isClosed) {
          _messageController!.addError(error);
        }
      },
      onDone: () {
        if (_messageController != null && !_messageController!.isClosed) {
          _messageController!.close();
        }
      },
    );
  }

  void sendMessage(String text) {
    _channel?.sink.add(text);
  }

  void disconnect() {
    _channel?.sink.close();
    _messageController?.close();
    _channel = null;
    _messageController = null;
  }
}
