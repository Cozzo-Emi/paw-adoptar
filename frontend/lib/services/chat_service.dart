import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/constants.dart';
import '../models/chat.dart';
import 'api_client.dart';

class ChatService {
  final ApiClient _client;
  WebSocketChannel? _channel;
  StreamController<Message>? _messageController;

  ChatService({required ApiClient client}) : _client = client;

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

  void _initWebSocket(String chatId) {
    final token = _client.lastToken;
    if (token == null || token.isEmpty) {
      debugPrint('[ChatService] No token available for WebSocket');
      return;
    }

    final base = AppConstants.apiBaseUrl;
    final wsBase = base.startsWith('https') ? base.replaceFirst('https', 'wss') : base.replaceFirst('http', 'ws');
    final wsUrl = Uri.parse('$wsBase/chats/$chatId/ws?token=$token');

    debugPrint('[ChatService] Connecting to $wsBase/chats/$chatId/ws');
    _channel = WebSocketChannel.connect(wsUrl);

    _channel!.stream.listen(
      (data) {
        if (_messageController == null || _messageController!.isClosed) return;
        try {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          _messageController!.add(Message.fromJson(json));
        } catch (e) {
          debugPrint('[ChatService] Error parsing message: $e');
        }
      },
      onError: (error) {
        debugPrint('[ChatService] WebSocket error: $error');
        if (_messageController != null && !_messageController!.isClosed) {
          _messageController!.addError(error);
        }
      },
      onDone: () {
        debugPrint('[ChatService] WebSocket closed');
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
