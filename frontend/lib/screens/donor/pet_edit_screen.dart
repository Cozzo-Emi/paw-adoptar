import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/cloudinary_service.dart';
import '../../services/pet_service.dart';

import '../../models/pet.dart';
import '../../providers/pet_provider.dart';

class PetEditScreen extends StatefulWidget {
  final String petId;
  const PetEditScreen({super.key, required this.petId});

  @override
  State<PetEditScreen> createState() => _PetEditScreenState();
}

class _PetEditScreenState extends State<PetEditScreen> {
  int _step = 0;
  bool _submitting = false;
  String? _error;

  // Photos
  final _picker = ImagePicker();
  final List<XFile> _photos = [];

  // Basic
  final _nameCtrl = TextEditingController();
  String _species = 'dog';
  final _breedCtrl = TextEditingController();
  String _sex = 'male';
  String _size = 'medium';
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();

  // Health
  bool _neutered = false;
  bool _vaccinated = false;
  final _vaccCtrl = TextEditingController();
  final _healthCtrl = TextEditingController();
  String _energy = 'medium';
  bool? _kids;
  bool? _pets;
  final _descCtrl = TextEditingController();

  // Requirements
  final _reqCtrl = TextEditingController();
  bool _reqYard = false;
  bool _reqExp = false;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPetData();
  }

  Future<void> _loadPetData() async {
    try {
      final api = context.read<ApiClient>();
      final petSvc = PetService(client: api);
      final pet = await petSvc.fetchPet(widget.petId);

      _nameCtrl.text = pet.name;
      _species = pet.species;
      _breedCtrl.text = pet.breed ?? '';
      _sex = pet.sex;
      _size = pet.size;
      _ageCtrl.text = pet.ageMonths.toString();
      _weightCtrl.text = pet.weightKg?.toString() ?? '';
      _colorCtrl.text = pet.color ?? '';

      _neutered = pet.isNeutered;
      _vaccinated = pet.isVaccinated;
      _vaccCtrl.text = pet.vaccinationDetails ?? '';
      _healthCtrl.text = pet.healthStatus ?? '';
      _energy = pet.energyLevel;
      _kids = pet.goodWithKids;
      _pets = pet.goodWithPets;
      _descCtrl.text = pet.description;

      _reqCtrl.text = pet.requirements ?? '';
      _reqYard = pet.requiresYard;
      _reqExp = pet.requiresExperience;

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() { _error = 'Error cargando mascota'; _loading = false; });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _breedCtrl.dispose(); _ageCtrl.dispose();
    _weightCtrl.dispose(); _colorCtrl.dispose(); _vaccCtrl.dispose();
    _healthCtrl.dispose(); _descCtrl.dispose(); _reqCtrl.dispose();
    super.dispose();
  }

  // ── SUBMIT ──────────────────────────────────────
  Future<void> _submit() async {
    setState(() { _submitting = true; _error = null; });

    try {
      final provider = context.read<PetProvider>();
      final success = await provider.updatePet(widget.petId, {
        'name': _nameCtrl.text.trim(),
        'species': _species,
        'breed': _breedCtrl.text.trim().isEmpty ? null : _breedCtrl.text.trim(),
        'age_months': int.tryParse(_ageCtrl.text.trim()) ?? 1,
        'sex': _sex,
        'size': _size,
        'weight_kg': double.tryParse(_weightCtrl.text.trim()),
        'color': _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
        'is_neutered': _neutered,
        'is_vaccinated': _vaccinated,
        'vaccination_details': _vaccCtrl.text.trim().isEmpty ? null : _vaccCtrl.text.trim(),
        'health_status': _healthCtrl.text.trim().isEmpty ? null : _healthCtrl.text.trim(),
        'energy_level': _energy,
        'good_with_kids': _kids,
        'good_with_pets': _pets,
        'description': _descCtrl.text.trim().isEmpty ? 'Sin descripción' : _descCtrl.text.trim(),
        'requirements': _reqCtrl.text.trim().isEmpty ? null : _reqCtrl.text.trim(),
        'requires_yard': _reqYard,
        'requires_experience': _reqExp,
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Actualizado! 🎉'), backgroundColor: Color(0xFF28A745)));
        context.pop(); // Go back
      }
    } on DioException catch (e) {
      if (mounted) {
        String msg = e.message ?? e.toString();
        if (e.response?.data != null) {
          msg = 'Error del servidor: ${e.response!.data}';
        }
        setState(() => _error = msg);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _submitting = false);
  }

  // ── UI ──────────────────────────────────────────
  String _stepTitle(int i) => ['Datos básicos', 'Salud & Comportamiento', 'Requisitos del tutor'][i];

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final theme = Theme.of(context);
    final children = <Widget>[
      _basicStep(),
      _healthStep(),
      _requirementsStep(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Mascota')),
      body: Column(
        children: [
          // Step indicator
          SizedBox(
            height: 56,
            child: Row(
              children: List.generate(3, (i) {
                final active = i <= _step;
                return Expanded(
                  child: GestureDetector(
                    onTap: i < _step ? () => setState(() => _step = i) : null,
                    child: Container(
                      color: _step == i ? theme.colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: active ? theme.colorScheme.primary : Colors.grey[400])),
                          Text(_stepTitle(i), style: TextStyle(fontSize: 10, color: active ? theme.colorScheme.primary : Colors.grey[400])),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          if (_error != null)
            Container(width: double.infinity, padding: const EdgeInsets.all(12), color: theme.colorScheme.error.withValues(alpha: 0.1), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13))),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: children[_step],
            ),
          ),

          // Buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => _step == 0 ? context.pop() : setState(() => _step--),
                      child: Text(_step == 0 ? 'Cancelar' : 'Atrás'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : () => _step >= 2 ? _submit() : setState(() => _step++),
                      child: _submitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_step >= 2 ? 'Guardar' : 'Siguiente'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP: BASIC ─────────────────────────────────
  Widget _basicStep() {
    return Column(children: [
      _tf(_nameCtrl, 'Nombre *'),
      _gap(),
      _dropdown('Especie *', _species, {'Perro': 'dog', 'Gato': 'cat'}, (v) => _species = v),
      _gap(),
      _tf(_breedCtrl, 'Raza'),
      _gap(),
      Row(children: [
        Expanded(child: _dropdown('Sexo *', _sex, {'Macho': 'male', 'Hembra': 'female'}, (v) => _sex = v)),
        const SizedBox(width: 12),
        Expanded(child: _dropdown('Tamaño *', _size, {'Pequeño': 'small', 'Mediano': 'medium', 'Grande': 'large'}, (v) => _size = v)),
      ]),
      _gap(),
      Row(children: [Expanded(child: _tf(_ageCtrl, 'Edad (meses)', number: true)), const SizedBox(width: 12), Expanded(child: _tf(_weightCtrl, 'Peso (kg)', number: true))]),
      _gap(),
      _tf(_colorCtrl, 'Color'),
    ]);
  }

  // ── STEP: HEALTH ────────────────────────────────
  Widget _healthStep() {
    return Column(children: [
      SwitchListTile(title: const Text('Esterilizado'), value: _neutered, onChanged: (v) => setState(() => _neutered = v)),
      SwitchListTile(title: const Text('Vacunado'), value: _vaccinated, onChanged: (v) => setState(() => _vaccinated = v)),
      if (_vaccinated) _tf(_vaccCtrl, 'Detalle vacunas', maxLines: 2),
      _gap(),
      _tf(_healthCtrl, 'Estado de salud', maxLines: 2),
      _gap(),
      _dropdown('Nivel de energía', _energy, {'Baja': 'low', 'Media': 'medium', 'Alta': 'high'}, (v) => _energy = v),
      _gap(),
      _tf(_descCtrl, 'Descripción', maxLines: 3),
      _gap(),
      Row(children: [
        const Text('Bueno con: '),
        ChoiceChip(label: const Text('Niños'), selected: _kids == true, selectedColor: Colors.green[100], onSelected: (_) => setState(() => _kids = _kids == true ? null : true)),
        const SizedBox(width: 8),
        ChoiceChip(label: const Text('Mascotas'), selected: _pets == true, selectedColor: Colors.green[100], onSelected: (_) => setState(() => _pets = _pets == true ? null : true)),
      ]),
    ]);
  }

  // ── STEP: REQUIREMENTS ──────────────────────────
  Widget _requirementsStep() {
    return Column(children: [
      _tf(_reqCtrl, 'Requisitos para el adoptante', hint: 'Ej: Tener espacio amplio...', maxLines: 3),
      _gap(),
      SwitchListTile(title: const Text('Requiere patio'), subtitle: const Text('Espacio exterior necesario'), value: _reqYard, onChanged: (v) => setState(() => _reqYard = v)),
      SwitchListTile(title: const Text('Requiere experiencia'), subtitle: const Text('Experiencia previa con mascotas'), value: _reqExp, onChanged: (v) => setState(() => _reqExp = v)),
    ]);
  }

  // ── HELPERS ─────────────────────────────────────
  Widget _gap() => const SizedBox(height: 14);

  Widget _tf(TextEditingController ctrl, String label, {String? hint, bool number = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, hintText: hint),
      keyboardType: number ? TextInputType.number : null,
      maxLines: maxLines,
    );
  }

  Widget _dropdown(String label, String value, Map<String, String> items, Function(String) onChange) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key))).toList(),
      onChanged: (v) { if (v != null) { onChange(v); setState(() {}); }},
    );
  }
}
