import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});

  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final isDonor = user.isDonor;

    if (!isDonor) {
      return Scaffold(
        appBar: AppBar(title: const Text('Donante')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No tenés configurado tu perfil de donante.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/role-selection'),
                child: const Text('Configurar Rol'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Panel Donante')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '¡Hola ${user.fullName}!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          _StatCard(
            icon: Icons.pets,
            label: 'Mascotas Publicadas',
            value: '0',
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Icons.favorite,
            label: 'Matches Pendientes',
            value: '0',
            color: const Color(0xFFFF6584),
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Icons.celebration,
            label: 'Adopciones Completadas',
            value: '0',
            color: const Color(0xFF28A745),
          ),
          const SizedBox(height: 32),
          Text(
            'Publicar Mascota',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completá los pasos para crear una ficha de adopción',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/donor/publish'),
        icon: const Icon(Icons.add),
        label: const Text('Publicar Mascota'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 15)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
