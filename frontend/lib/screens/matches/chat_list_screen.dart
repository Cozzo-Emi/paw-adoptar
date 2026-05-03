import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChatProvider>().loadChats();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id ?? '';
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: _buildBody(provider, userId),
    );
  }

  Widget _buildBody(ChatProvider provider, String userId) {
    if (provider.isLoading && provider.chats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.chats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tenés chats activos',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Aceptá un match para empezar a chatear',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadChats(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.chats.length,
        itemBuilder: (context, index) {
          final chat = provider.chats[index];
          final isAdopter = chat.adopterId == userId;
          final label = isAdopter ? 'Tutor' : 'Adoptante';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(Icons.person,
                  color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(label),
            subtitle: Text(
              chat.isActive ? 'Activo' : 'Finalizado',
              style: TextStyle(
                color: chat.isActive ? Colors.green : Colors.grey,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/chat/${chat.id}'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
}
