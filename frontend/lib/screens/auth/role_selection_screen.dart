import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isAdopter = false;
  bool _isDonor = false;
  bool _isLoading = false;

  bool get _selectionValid => _isAdopter || _isDonor;

  Future<void> _continue() async {
    if (!_selectionValid) return;

    final role = _isAdopter && _isDonor
        ? 'both'
        : _isDonor
            ? 'donor'
            : 'adopter';

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().updateProfile(role: role);
    } catch (_) {
      // Role persisted or not, proceed anyway
    }

    if (mounted) {
      context.go('/feed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                '¿Cuál es tu rol?',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Podés elegir ambos si querés adoptar y también dar en adopción.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Column(
                  children: [
                    _RoleCard(
                      icon: Icons.favorite,
                      color: const Color(0xFFFF6584),
                      title: 'Quiero Adoptar',
                      subtitle: 'Buscá y conectá con mascotas que necesitan un hogar',
                      isSelected: _isAdopter,
                      onTap: () {
                        setState(() => _isAdopter = !_isAdopter);
                      },
                    ),
                    const SizedBox(height: 16),
                    _RoleCard(
                      icon: Icons.home,
                      color: const Color(0xFF6C63FF),
                      title: 'Tengo mascotas para dar en adopción',
                      subtitle: 'Publicá fichas y encontrá el mejor hogar para ellas',
                      isSelected: _isDonor,
                      onTap: () {
                        setState(() => _isDonor = !_isDonor);
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectionValid && !_isLoading ? _continue : null,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 28),
          ],
        ),
      ),
    );
  }
}
