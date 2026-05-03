import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService;

  List<Chat> _chats = [];
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Message>? _messageSubscription;

  ChatProvider({required ChatService chatService})
      : _chatService = chatService;

  List<Chat> get chats => _chats;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadChats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _chats = await _chatService.listChats();
    } catch (e) {
      _error = 'No se pudieron cargar los chats.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadChatHistory(String chatId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final history = await _chatService.getChatHistory(chatId);
      _messages = history.reversed.toList();
    } catch (e) {
      _error = 'No se pudo cargar el historial.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Chat?> createChat(String matchId) async {
    try {
      final chat = await _chatService.createChat(matchId);
      await loadChats();
      return chat;
    } catch (e) {
      return null;
    }
  }

  void connectToChat(String chatId) {
    _messageSubscription?.cancel();
    // Don't clear messages here — history is already loaded

    _messageSubscription = _chatService.connectToChat(chatId).listen(
      (message) {
        _messages = [..._messages, message];
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  void sendMessage(String text) {
    _chatService.sendMessage(text);
  }

  void disconnectChat() {
    _messageSubscription?.cancel();
    _chatService.disconnect();
    _messages = [];
    notifyListeners();
  }

  @override
  void dispose() {
    disconnectChat();
    super.dispose();
  }
}
