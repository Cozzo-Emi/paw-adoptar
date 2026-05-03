import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/pet.dart';
import '../../providers/match_provider.dart';
import '../../providers/pet_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/loading_overlay.dart';

class PetDetailScreen extends StatefulWidget {
  final String petId;

  const PetDetailScreen({super.key, required this.petId});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  final _pageController = PageController();
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<PetProvider>().loadPetDetail(widget.petId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PetProvider>();
    final pet = provider.selectedPet;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (pet != null)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag, color: Colors.white, size: 20),
              ),
              onPressed: () => _showReportDialog(pet),
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: provider.isLoading,
        child: pet == null
            ? _buildError(provider.error)
            : _buildContent(pet),
      ),
      bottomNavigationBar: pet != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => _expressInterest(pet),
                  icon: const Icon(Icons.favorite),
                  label: const Text('Expresar Interés'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildError(String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message ?? 'No se pudo cargar la mascota'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<PetProvider>().loadPetDetail(widget.petId),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Pet pet) {
    return CustomScrollView(
      slivers: [
        // Carrusel de fotos
        SliverToBoxAdapter(
          child: SizedBox(
            height: 360,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPhotoIndex = index);
                  },
                  itemCount: pet.photos.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      pet.photos[index].cloudinaryUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.pets, size: 64, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
                // Indicador de página
                if (pet.photos.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pet.photos.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _currentPhotoIndex ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentPhotoIndex
                                ? Colors.white
                                : Colors.white54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Datos de la mascota
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet.name,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pet.speciesLabel} · ${pet.sexLabel} · ${pet.ageFormatted}',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (pet.city != null)
                      Chip(
                        avatar: const Icon(Icons.location_on, size: 18),
                        label: Text(pet.city!),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Descripción
                Text(pet.description, style: const TextStyle(fontSize: 15, height: 1.5)),
                const SizedBox(height: 24),

                // Salud y vacunas
                _SectionTile(
                  icon: Icons.health_and_safety,
                  title: 'Salud',
                  initiallyExpanded: true,
                  children: [
                    _InfoRow(
                      label: 'Esterilizado',
                      value: pet.isNeutered ? 'Sí' : 'No',
                    ),
                    _InfoRow(
                      label: 'Vacunado',
                      value: pet.isVaccinated ? 'Sí' : 'No',
                    ),
                    if (pet.vaccinationDetails != null)
                      _InfoRow(
                        label: 'Detalle vacunas',
                        value: pet.vaccinationDetails!,
                      ),
                    if (pet.healthStatus != null)
                      _InfoRow(label: 'Estado', value: pet.healthStatus!),
                  ],
                ),

                // Comportamiento
                _SectionTile(
                  icon: Icons.emoji_emotions,
                  title: 'Comportamiento',
                  children: [
                    _InfoRow(
                      label: 'Energía',
                      value: _energyLabel(pet.energyLevel),
                    ),
                    if (pet.goodWithKids != null)
                      _InfoRow(
                        label: 'Bueno con niños',
                        value: pet.goodWithKids! ? 'Sí' : 'No',
                      ),
                    if (pet.goodWithPets != null)
                      _InfoRow(
                        label: 'Bueno con mascotas',
                        value: pet.goodWithPets! ? 'Sí' : 'No',
                      ),
                  ],
                ),

                // Requisitos
                if (pet.requiresYard || pet.requiresExperience || pet.requirements != null)
                  _SectionTile(
                    icon: Icons.checklist,
                    title: 'Requisitos del donante',
                    children: [
                      if (pet.requiresYard)
                        const _InfoRow(label: 'Patio', value: 'Requerido'),
                      if (pet.requiresExperience)
                        const _InfoRow(label: 'Experiencia', value: 'Requerida'),
                      if (pet.requirements != null)
                        _InfoRow(label: 'Notas', value: pet.requirements!),
                    ],
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showReportDialog(Pet pet) {
    final reasonController = TextEditingController();
    String selectedReason = 'inappropriate';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reportar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('¿Por qué querés reportar esta publicación?'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                items: const [
                  DropdownMenuItem(value: 'inappropriate', child: Text('Contenido inapropiado')),
                  DropdownMenuItem(value: 'fake_listing', child: Text('Publicación falsa')),
                  DropdownMenuItem(value: 'fraud', child: Text('Fraude')),
                  DropdownMenuItem(value: 'abuse', child: Text('Abuso')),
                  DropdownMenuItem(value: 'other', child: Text('Otro')),
                ],
                onChanged: (v) => setDialogState(() => selectedReason = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Explicá brevemente...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await context.read<ApiClient>().dio.post('/moderation/reports', data: {
                    'reported_pet_id': pet.id,
                    'reason': selectedReason,
                    'description': reasonController.text.trim().isEmpty ? 'Reporte' : reasonController.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reporte enviado. Gracias.'), backgroundColor: Color(0xFF28A745)),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }

  String _energyLabel(String level) {
    switch (level) {
      case 'low':
        return 'Baja';
      case 'medium':
        return 'Media';
      case 'high':
        return 'Alta';
      default:
        return level;
    }
  }

  void _expressInterest(Pet pet) async {
    final matchProvider = context.read<MatchProvider>();
    final success = await matchProvider.createMatch(petId: pet.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Interés expresado por ${pet.name}'),
          backgroundColor: const Color(0xFF28A745),
        ),
      );
      context.go('/matches');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(matchProvider.error ?? 'Error al expresar interés'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _SectionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  const _SectionTile({
    required this.icon,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  State<_SectionTile> createState() => _SectionTileState();
}

class _SectionTileState extends State<_SectionTile> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Column(children: widget.children),
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
