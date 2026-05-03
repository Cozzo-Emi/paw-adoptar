import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../widgets/pet_card.dart';
import 'filter_modal.dart';

class PetFeedScreen extends StatefulWidget {
  const PetFeedScreen({super.key});

  @override
  State<PetFeedScreen> createState() => _PetFeedScreenState();
}

class _PetFeedScreenState extends State<PetFeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetProvider>().loadPets(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<PetProvider>();
      if (!provider.isLoading && provider.hasMore) {
        provider.loadPets();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final petProvider = context.watch<PetProvider>();
    final hasActiveFilters = petProvider.speciesFilter != null ||
        petProvider.sizeFilter != null ||
        petProvider.ageMinFilter != null ||
        petProvider.ageMaxFilter != null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PAW', style: TextStyle(fontWeight: FontWeight.bold)),
            if (user?.city != null)
              Text(
                user!.city!,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.go('/profile');
                case 'logout':
                  context.read<AuthProvider>().logout();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'profile', child: ListTile(leading: Icon(Icons.person), title: Text('Mi Perfil'), dense: true)),
              const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Cerrar Sesión'), dense: true)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Chips de filtros rápidos
          _QuickFilters(
            hasActiveFilters: hasActiveFilters,
            onFilterTap: _showFilterModal,
            onClear: () => petProvider.clearFilters(),
          ),

          // Contenido principal
          Expanded(
            child: _buildBody(petProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(PetProvider petProvider) {
    if (petProvider.isLoading && petProvider.pets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (petProvider.error != null && petProvider.pets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              petProvider.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => petProvider.loadPets(refresh: true),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (petProvider.pets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay mascotas disponibles',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => petProvider.loadPets(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: petProvider.pets.length + (petProvider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= petProvider.pets.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final pet = petProvider.pets[index];
          return PetCard(
            pet: pet,
            onTap: () => context.go('/feed/${pet.id}'),
          );
        },
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const FilterModal(),
    );
  }
}

class _QuickFilters extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onFilterTap;
  final VoidCallback onClear;

  const _QuickFilters({
    required this.hasActiveFilters,
    required this.onFilterTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _QuickChip(
            icon: Icons.tune,
            label: hasActiveFilters ? 'Filtros activos' : 'Filtros',
            active: hasActiveFilters,
            onTap: onFilterTap,
          ),
          if (hasActiveFilters) ...[
            const SizedBox(width: 8),
            _QuickChip(
              icon: Icons.close,
              label: 'Limpiar',
              onTap: onClear,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: active
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: active ? Theme.of(context).colorScheme.primary : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? Theme.of(context).colorScheme.primary : Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
