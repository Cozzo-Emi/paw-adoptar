import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/cloudinary_service.dart';
import '../../services/pet_service.dart';

class PetCreationScreen extends StatefulWidget {
  const PetCreationScreen({super.key});

  @override
  State<PetCreationScreen> createState() => _PetCreationScreenState();
}

class _PetCreationScreenState extends State<PetCreationScreen> {
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

  @override
  void dispose() {
    _nameCtrl.dispose(); _breedCtrl.dispose(); _ageCtrl.dispose();
    _weightCtrl.dispose(); _colorCtrl.dispose(); _vaccCtrl.dispose();
    _healthCtrl.dispose(); _descCtrl.dispose(); _reqCtrl.dispose();
    super.dispose();
  }

  // ── PHOTOS ──────────────────────────────────────
  Future<void> _pickPhotos() async {
    try {
      final files = await _picker.pickMultiImage(imageQuality: 80, limit: 5);
      if (files.isNotEmpty) {
        setState(() {
          _photos.addAll(files);
          if (_photos.length > 5) _photos.removeRange(5, _photos.length);
        });
      }
    } catch (_) {}
  }

  void _removePhoto(int i) => setState(() => _photos.removeAt(i));

  // ── SUBMIT ──────────────────────────────────────
  Future<void> _submit() async {
    if (_photos.length < 2) {
      setState(() => _error = 'Subí al menos 2 fotos');
      return;
    }

    setState(() { _submitting = true; _error = null; });

    try {
      final api = context.read<ApiClient>();
      final petSvc = PetService(client: api);
      final cloud = CloudinaryService();
      final signed = await petSvc.getSignedUploadParams();

      final uploaded = <Map<String, dynamic>>[];
      for (int i = 0; i < _photos.length; i++) {
        final bytes = await _photos[i].readAsBytes();
        final r = await cloud.uploadImageBytes(bytes: bytes, filename: 'pet_$i.jpg', signedParams: signed);
        uploaded.add({'cloudinary_url': r['cloudinary_url'], 'cloudinary_public_id': r['cloudinary_public_id']});
      }

      await petSvc.createPet({
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
        'photos': uploaded,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Publicado! 🎉'), backgroundColor: Color(0xFF28A745)));
        context.go('/donor');
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
  String _stepTitle(int i) => ['Fotos', 'Datos básicos', 'Salud & Comportamiento', 'Requisitos del tutor'][i];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[
      _photoStep(),
      _basicStep(),
      _healthStep(),
      _requirementsStep(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Publicar Mascota')),
      body: Column(
        children: [
          // Step indicator
          SizedBox(
            height: 56,
            child: Row(
              children: List.generate(4, (i) {
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
                      onPressed: _submitting ? null : () => _step == 0 ? context.go('/donor') : setState(() => _step--),
                      child: Text(_step == 0 ? 'Cancelar' : 'Atrás'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : () => _step >= 3 ? _submit() : setState(() => _step++),
                      child: _submitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_step >= 3 ? 'Publicar' : 'Siguiente'),
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

  // ── STEP: PHOTOS ────────────────────────────────
  Widget _photoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subí al menos 2 fotos. La primera será la portada.', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ...List.generate(_photos.length, (i) => _photoTile(i)),
          if (_photos.length < 5)
            GestureDetector(
              onTap: _pickPhotos,
              child: Container(width: 100, height: 100, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!), color: Colors.grey[50]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate, color: Colors.grey[400]), Text('Agregar', style: TextStyle(fontSize: 11, color: Colors.grey[500]))])),
            ),
        ]),
      ],
    );
  }

  Widget _photoTile(int i) {
    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FutureBuilder(
          future: _photos[i].readAsBytes(),
          builder: (_, snap) => snap.hasData ? Image.memory(snap.data!, width: 100, height: 100, fit: BoxFit.cover) : Container(width: 100, height: 100, color: Colors.grey[200]),
        ),
      ),
      Positioned(top: 2, right: 2, child: GestureDetector(onTap: () => _removePhoto(i), child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white)))),
      if (i == 0) Positioned(bottom: 2, left: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(6)), child: const Text('Portada', style: TextStyle(color: Colors.white, fontSize: 9)))),
    ]);
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
