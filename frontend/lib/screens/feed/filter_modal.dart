import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/pet_provider.dart';

class FilterModal extends StatefulWidget {
  const FilterModal({super.key});

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  String? _species;
  String? _size;
  int? _ageMin;
  int? _ageMax;

  final _ageMinController = TextEditingController();
  final _ageMaxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<PetProvider>();
    _species = provider.speciesFilter;
    _size = provider.sizeFilter;
    _ageMin = provider.ageMinFilter;
    _ageMax = provider.ageMaxFilter;
    if (_ageMin != null) _ageMinController.text = _ageMin.toString();
    if (_ageMax != null) _ageMaxController.text = _ageMax.toString();
  }

  @override
  void dispose() {
    _ageMinController.dispose();
    _ageMaxController.dispose();
    super.dispose();
  }

  void _apply() {
    context.read<PetProvider>().applyFilters(
          species: _species,
          size: _size,
          ageMin: _ageMin,
          ageMax: _ageMax,
        );
    Navigator.pop(context);
  }

  void _clear() {
    context.read<PetProvider>().clearFilters();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Filtros',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Especie
            _FilterSection(
              title: 'Especie',
              children: [
                _FilterChip(
                  label: 'Perros',
                  icon: Icons.pets,
                  selected: _species == 'dog',
                  onTap: () => setState(() => _species = _species == 'dog' ? null : 'dog'),
                ),
                _FilterChip(
                  label: 'Gatos',
                  icon: Icons.pets,
                  selected: _species == 'cat',
                  onTap: () => setState(() => _species = _species == 'cat' ? null : 'cat'),
                ),
              ],
            ),

            // Tamaño
            _FilterSection(
              title: 'Tamaño',
              children: [
                _FilterChip(
                  label: 'Pequeño',
                  selected: _size == 'small',
                  onTap: () => setState(() => _size = _size == 'small' ? null : 'small'),
                ),
                _FilterChip(
                  label: 'Mediano',
                  selected: _size == 'medium',
                  onTap: () => setState(() => _size = _size == 'medium' ? null : 'medium'),
                ),
                _FilterChip(
                  label: 'Grande',
                  selected: _size == 'large',
                  onTap: () => setState(() => _size = _size == 'large' ? null : 'large'),
                ),
              ],
            ),

            // Edad
            _FilterSection(
              title: 'Edad (meses)',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageMinController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Desde',
                          hintText: '0',
                        ),
                        onChanged: (v) {
                          _ageMin = int.tryParse(v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _ageMaxController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Hasta',
                          hintText: '...',
                        ),
                        onChanged: (v) {
                          _ageMax = int.tryParse(v);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clear,
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _apply,
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FilterSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: children),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 18, color: selected ? Colors.white : Colors.grey[600]),
            if (icon != null) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey[800],
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
