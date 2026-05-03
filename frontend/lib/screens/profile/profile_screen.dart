import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user.fullName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Center(
            child: Text(
              user.email,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: _RoleBadge(role: user.role),
          ),
          const SizedBox(height: 32),

          // Info section
          _InfoTile(icon: Icons.email, label: 'Email', value: user.email),
          if (user.phone != null)
            _InfoTile(icon: Icons.phone, label: 'Teléfono', value: user.phone!),
          if (user.city != null)
            _InfoTile(
              icon: Icons.location_on,
              label: 'Ubicación',
              value: user.province != null
                  ? '${user.city}, ${user.province}'
                  : user.city!,
            ),
          _InfoTile(
            icon: Icons.star,
            label: 'Reputación',
            value: '${user.reputationScore.toStringAsFixed(1)} ★ (${user.reputationCount} valoraciones)',
          ),
          _InfoTile(
            icon: Icons.verified,
            label: 'Verificación',
            value: user.verificationLevel == 0 ? 'Sin verificar' : 'Nivel ${user.verificationLevel}',
          ),

          const SizedBox(height: 24),

          // Action buttons
          if (user.isAdopter)
            OutlinedButton.icon(
              onPressed: () => context.go('/profile/adopter'),
              icon: const Icon(Icons.tune),
              label: const Text('Editar Preferencias de Adopción'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('/role-selection'),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Cambiar Rol'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Cerrar Sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (role) {
      case 'adopter':
        label = 'Adoptante';
        color = const Color(0xFFFF6584);
      case 'donor':
        label = 'Tutor';
        color = const Color(0xFF6C63FF);
      case 'both':
        label = 'Adoptante & Tutor';
        color = const Color(0xFF28A745);
      case 'moderator':
        label = 'Moderador';
        color = Colors.orange;
      case 'admin':
        label = 'Admin';
        color = Colors.red;
      default:
        label = role;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
