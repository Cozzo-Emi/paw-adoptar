import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/pet.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/pet_provider.dart';

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});

  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || !user.isDonor) return;

    await Future.wait([
      context.read<PetProvider>().loadPets(refresh: true, donorId: user.id),
      context.read<MatchProvider>().loadMatches(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!user.isDonor) {
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

    final petProvider = context.watch<PetProvider>();
    final matchProvider = context.watch<MatchProvider>();
    final pets = petProvider.pets;
    final matches = matchProvider.matches;

    final pendingMatches = matches.where((m) => m.isPending).length;
    final completedMatches = matches.where((m) => m.isCompleted).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Panel Donante')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
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
              value: '${pets.length}',
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _StatCard(
              icon: Icons.favorite,
              label: 'Matches Pendientes',
              value: '$pendingMatches',
              color: const Color(0xFFFF6584),
            ),
            const SizedBox(height: 12),
            _StatCard(
              icon: Icons.celebration,
              label: 'Adopciones Completadas',
              value: '$completedMatches',
              color: const Color(0xFF28A745),
            ),
            const SizedBox(height: 32),

            if (pets.isNotEmpty) ...[
              Text(
                'Mis Mascotas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              ...pets.map((pet) => _DonorPetTile(pet: pet)),
              const SizedBox(height: 16),
            ],

            if (pets.isEmpty && !petProvider.isLoading)
              Card(
                color: Colors.grey[50],
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.pets, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No tenés mascotas publicadas todavía.',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/donor/publish'),
                icon: const Icon(Icons.add),
                label: const Text('Publicar Mascota'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _DonorPetTile extends StatelessWidget {
  final Pet pet;

  const _DonorPetTile({required this.pet});

  Color _statusColor() {
    switch (pet.status) {
      case 'available':
        return Colors.green;
      case 'matched':
        return Colors.orange;
      case 'adopted':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel() {
    switch (pet.status) {
      case 'available':
        return 'Disponible';
      case 'matched':
        return 'En proceso';
      case 'adopted':
        return 'Adoptado';
      case 'removed':
        return 'Removido';
      default:
        return pet.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: pet.coverImage.isNotEmpty
                  ? Image.network(
                      pet.coverImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.pets, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.pets, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${pet.speciesLabel} · ${pet.ageFormatted}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusLabel(),
                style: TextStyle(
                  color: _statusColor(),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
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
