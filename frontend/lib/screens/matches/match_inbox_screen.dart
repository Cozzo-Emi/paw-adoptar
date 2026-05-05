import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/match.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/match_provider.dart';

class MatchInboxScreen extends StatefulWidget {
  const MatchInboxScreen({super.key});

  @override
  State<MatchInboxScreen> createState() => _MatchInboxScreenState();
}

class _MatchInboxScreenState extends State<MatchInboxScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MatchProvider>().loadMatches();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id ?? '';
    final provider = context.watch<MatchProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: _buildBody(provider, userId),
    );
  }

  Widget _buildBody(MatchProvider provider, String userId) {
    if (provider.isLoading && provider.matches.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(provider.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadMatches(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (provider.matches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tenés matches todavía',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Explorá mascotas y expresá interés para empezar',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final pending =
        provider.matches.where((m) => m.isPending && m.donorId == userId).toList();
    final others = provider.matches
        .where((m) => !(m.isPending && m.donorId == userId))
        .toList();

    return RefreshIndicator(
      onRefresh: () => provider.loadMatches(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pending.isNotEmpty) ...[
            Text(
              'Pendientes de respuesta',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
              ...pending.map((m) => _MatchCard(
                    match: m,
                    userId: userId,
                    onAccept: () => _handleAccept(m.id),
                    onReject: () => _handleReject(m.id),
                    onChat: null,
                    onEvidence: null,
                    onReview: null,
                  )),
            if (others.isNotEmpty) const SizedBox(height: 24),
          ],
          if (others.isNotEmpty) ...[
            Text(
              'Historial',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ...others.map((m) => _MatchCard(
                  match: m,
                  userId: userId,
                  onAccept: null,
                  onReject: null,
                  onChat: m.isAccepted ? () => _handleGoToChat(m.id) : null,
                  onEvidence: m.isAccepted || m.isCompleted
                      ? () => context.go('/evidence/${m.id}')
                      : null,
                  onReview: m.isAccepted || m.isCompleted
                      ? () => context.go('/review/${m.id}')
                      : null,
                )),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAccept(String matchId) async {
    final matchProvider = context.read<MatchProvider>();
    final success = await matchProvider.acceptMatch(matchId);
    if (success && mounted) {
      await context.read<ChatProvider>().createChat(matchId);
    }
  }

  Future<void> _handleReject(String matchId) async {
    context.read<MatchProvider>().rejectMatch(matchId);
  }

  void _handleGoToChat(String matchId) async {
    final chatProvider = context.read<ChatProvider>();
    final matchProvider = context.read<MatchProvider>();
    final userId = context.read<AuthProvider>().user?.id ?? '';
    
    final match = matchProvider.matches
        .where((m) => m.id == matchId)
        .firstOrNull;
    final otherName = match?.adopterId == userId ? match?.donorName : match?.adopterName;

    var chat = chatProvider.chats
        .where((c) => c.matchId == matchId)
        .firstOrNull;

    if (chat == null) {
      final newChat = await chatProvider.createChat(matchId);
      chat = newChat;
    }
    
    if (chat != null && mounted) {
      final nameParam = otherName != null ? '?name=${Uri.encodeComponent(otherName)}' : '';
      context.go('/chat/${chat.id}$nameParam');
    }
  }
}

class _MatchCard extends StatelessWidget {
  final Match match;
  final String userId;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onChat;
  final VoidCallback? onEvidence;
  final VoidCallback? onReview;

  const _MatchCard({
    required this.match,
    required this.userId,
    this.onAccept,
    this.onReject,
    this.onChat,
    this.onEvidence,
    this.onReview,
  });

  String get _otherName {
    if (match.adopterId == userId) {
      return match.donorName ?? 'Tutor';
    }
    return match.adopterName ?? 'Adoptante';
  }

  Color _statusColor() {
    switch (match.status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    match.statusLabel,
                    style: TextStyle(
                      color: _statusColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (match.compatibilityScore != null)
                  Text(
                    '${(match.compatibilityScore! * 100).round()}% match',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
              ],
            ),
            if (match.petName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.pets, size: 16, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 4),
                  Text(
                    match.petName!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _otherName,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            if (match.adopterMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                match.adopterMessage!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (onAccept != null || onReject != null || onChat != null || onEvidence != null || onReview != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onReject != null)
                    OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Rechazar'),
                    ),
                  if (onAccept != null)
                    ElevatedButton(
                      onPressed: onAccept,
                      child: const Text('Aceptar'),
                    ),
                  if (onChat != null)
                    ElevatedButton.icon(
                      onPressed: onChat,
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('Chat'),
                    ),
                  if (onEvidence != null)
                    OutlinedButton.icon(
                      onPressed: onEvidence,
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Evidencia'),
                    ),
                  if (onReview != null)
                    OutlinedButton.icon(
                      onPressed: onReview,
                      icon: const Icon(Icons.star, size: 18),
                      label: const Text('Valorar'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
