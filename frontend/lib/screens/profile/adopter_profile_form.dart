import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';


import '../../services/api_client.dart';

class AdopterProfileForm extends StatefulWidget {
  const AdopterProfileForm({super.key});

  @override
  State<AdopterProfileForm> createState() => _AdopterProfileFormState();
}

class _AdopterProfileFormState extends State<AdopterProfileForm> {
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;

  // Vivienda
  String? _housingType;
  bool _hasYard = false;
  String? _yardSize;
  int? _dailyHoursAlone;

  // Convivencia
  bool _hasOtherPets = false;
  final _otherPetsController = TextEditingController();
  bool _hasChildren = false;
  final _childrenAgesController = TextEditingController();

  // Experiencia y preferencias
  String? _experienceLevel;
  String _preferredSpecies = 'both';
  String _preferredSize = 'any';
  int? _preferredAgeMin;
  int? _preferredAgeMax;
  String _preferredEnergy = 'any';
  int _maxDistanceKm = 50;

  final _notesController = TextEditingController();

  @override
  void dispose() {
    _otherPetsController.dispose();
    _childrenAgesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final apiClient = context.read<ApiClient>();
      await apiClient.dio.post('/users/me/adopter-profile', data: {
        'housing_type': _housingType,
        'has_yard': _hasYard,
        'yard_size': _yardSize,
        'has_other_pets': _hasOtherPets,
        'other_pets_details': _otherPetsController.text.trim().isEmpty
            ? null
            : _otherPetsController.text.trim(),
        'has_children': _hasChildren,
        'children_ages': _childrenAgesController.text.trim().isEmpty
            ? null
            : _childrenAgesController.text.trim(),
        'daily_hours_alone': _dailyHoursAlone,
        'experience_level': _experienceLevel,
        'preferred_species': _preferredSpecies,
        'preferred_size': _preferredSize,
        'preferred_age_min': _preferredAgeMin,
        'preferred_age_max': _preferredAgeMax,
        'preferred_energy_level': _preferredEnergy,
        'max_distance_km': _maxDistanceKm,
        'additional_notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil guardado. ¡Ahora los matches serán más precisos!'),
            backgroundColor: Color(0xFF28A745),
          ),
        );
        context.go('/profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preferencias de Adopción')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Completá tu perfil para que el algoritmo encuentre tu match ideal',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Vivienda
            Text('Vivienda',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Tipo de vivienda'),
              initialValue: _housingType,
              items: const [
                DropdownMenuItem(value: 'house', child: Text('Casa')),
                DropdownMenuItem(value: 'apartment', child: Text('Departamento')),
                DropdownMenuItem(value: 'rural', child: Text('Rural')),
              ],
              onChanged: (v) => setState(() => _housingType = v),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('¿Tenés patio o jardín?'),
              value: _hasYard,
              onChanged: (v) => setState(() => _hasYard = v),
            ),
            if (_hasYard)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tamaño del patio'),
                initialValue: _yardSize,
                items: const [
                  DropdownMenuItem(value: 'small', child: Text('Pequeño')),
                  DropdownMenuItem(value: 'medium', child: Text('Mediano')),
                  DropdownMenuItem(value: 'large', child: Text('Grande')),
                ],
                onChanged: (v) => setState(() => _yardSize = v),
              ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Horas solo por día',
                hintText: 'Horas que la mascota estaría sola',
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => _dailyHoursAlone = int.tryParse(v),
            ),

            const SizedBox(height: 24),
            // Convivencia
            Text('Convivencia',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('¿Tenés otras mascotas?'),
              value: _hasOtherPets,
              onChanged: (v) => setState(() => _hasOtherPets = v),
            ),
            if (_hasOtherPets)
              TextFormField(
                controller: _otherPetsController,
                decoration: const InputDecoration(labelText: 'Describí tus mascotas'),
              ),
            SwitchListTile(
              title: const Text('¿Hay niños en casa?'),
              value: _hasChildren,
              onChanged: (v) => setState(() => _hasChildren = v),
            ),
            if (_hasChildren)
              TextFormField(
                controller: _childrenAgesController,
                decoration: const InputDecoration(labelText: 'Edades de los niños'),
              ),

            const SizedBox(height: 24),
            // Experiencia
            Text('Experiencia y Preferencias',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Experiencia con mascotas'),
              initialValue: _experienceLevel,
              items: const [
                DropdownMenuItem(value: 'first_time', child: Text('Primera vez')),
                DropdownMenuItem(value: 'some', child: Text('Alguna experiencia')),
                DropdownMenuItem(value: 'experienced', child: Text('Experimentado')),
              ],
              onChanged: (v) => setState(() => _experienceLevel = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Especie preferida'),
              initialValue: _preferredSpecies,
              items: const [
                DropdownMenuItem(value: 'dog', child: Text('Perro')),
                DropdownMenuItem(value: 'cat', child: Text('Gato')),
                DropdownMenuItem(value: 'both', child: Text('Ambos')),
              ],
              onChanged: (v) => setState(() => _preferredSpecies = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Tamaño preferido'),
              initialValue: _preferredSize,
              items: const [
                DropdownMenuItem(value: 'small', child: Text('Pequeño')),
                DropdownMenuItem(value: 'medium', child: Text('Mediano')),
                DropdownMenuItem(value: 'large', child: Text('Grande')),
                DropdownMenuItem(value: 'any', child: Text('Cualquiera')),
              ],
              onChanged: (v) => setState(() => _preferredSize = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Nivel de energía'),
              initialValue: _preferredEnergy,
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Baja')),
                DropdownMenuItem(value: 'medium', child: Text('Media')),
                DropdownMenuItem(value: 'high', child: Text('Alta')),
                DropdownMenuItem(value: 'any', child: Text('Cualquiera')),
              ],
              onChanged: (v) => setState(() => _preferredEnergy = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Edad mín (meses)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _preferredAgeMin = int.tryParse(v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Edad máx (meses)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _preferredAgeMax = int.tryParse(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Distancia máxima (km)',
                hintText: '50',
              ),
              keyboardType: TextInputType.number,
              initialValue: '50',
              onChanged: (v) => _maxDistanceKm = int.tryParse(v) ?? 50,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notas adicionales'),
              maxLines: 3,
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar Perfil'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
