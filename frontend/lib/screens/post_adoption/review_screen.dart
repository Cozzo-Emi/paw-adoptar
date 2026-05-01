import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/match.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_provider.dart';

class ReviewScreen extends StatefulWidget {
  final Match match;

  const ReviewScreen({super.key, required this.match});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String get _reviewedId {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    return widget.match.adopterId == userId
        ? widget.match.donorId
        : widget.match.adopterId;
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccioná una puntuación')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<MatchProvider>();
    final success = await provider.submitReview(
      matchId: widget.match.id,
      reviewedId: _reviewedId,
      rating: _rating,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Valoración enviada!'),
            backgroundColor: Color(0xFF28A745),
          ),
        );
        context.go('/matches');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Error al enviar'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dejar Valoración')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Cómo fue tu experiencia?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu valoración ayuda a construir confianza en la comunidad',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // Star rating
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    onPressed: () => setState(() => _rating = i + 1),
                    icon: Icon(
                      i < _rating ? Icons.star : Icons.star_outline,
                      color: Colors.amber,
                      size: 48,
                    ),
                  );
                }),
              ),
            ),
            if (_rating > 0)
              Center(
                child: Text(
                  _rating == 5
                      ? '¡Excelente!'
                      : _rating == 4
                          ? 'Muy buena'
                          : _rating == 3
                              ? 'Buena'
                              : _rating == 2
                                  ? 'Regular'
                                  : 'Mala',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 32),

            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
                hintText: 'Compartí tu experiencia...',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Enviar Valoración'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
