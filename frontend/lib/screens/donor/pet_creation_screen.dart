import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/cloudinary_service.dart';
import '../../services/pet_service.dart';
import '../../widgets/loading_overlay.dart';

class PetCreationScreen extends StatefulWidget {
  const PetCreationScreen({super.key});

  @override
  State<PetCreationScreen> createState() => _PetCreationScreenState();
}

class _PetCreationScreenState extends State<PetCreationScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  final _imagePicker = ImagePicker();

  // Step 1: Photos
  final List<_PhotoEntry> _photos = [];

  // Step 2: Basic data
  final _nameController = TextEditingController();
  String _species = 'dog';
  final _breedController = TextEditingController();
  String _sex = 'male';
  String _size = 'medium';
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();

  // Step 3: Health & Behavior
  bool _isNeutered = false;
  bool _isVaccinated = false;
  final _vaccDetailsController = TextEditingController();
  final _healthController = TextEditingController();
  String _energyLevel = 'medium';
  bool? _goodWithKids;
  bool? _goodWithPets;
  final _descriptionController = TextEditingController();

  // Step 4: Requirements
  final _requirementsController = TextEditingController();
  bool _requiresYard = false;
  bool _requiresExperience = false;

  // Forms
  final _step2Key = GlobalKey<FormState>();
  final _step4Key = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    _vaccDetailsController.dispose();
    _healthController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final files = await _imagePicker.pickMultiImage(
      imageQuality: 80,
      limit: 5,
    );

    if (files.isEmpty) return;

    for (final file in files) {
      setState(() {
        _photos.add(_PhotoEntry(File(file.path)));
      });
    }
  }

  Future<void> _submit() async {
    if (_photos.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se requieren al menos 2 fotos')),
      );
      return;
    }

    final apiClient = context.read<ApiClient>();
    final petService = PetService(client: apiClient);

    setState(() => _isSubmitting = true);

    try {
      // Upload photos
      final cloudinaryService = CloudinaryService();
      final uploadedPhotos = <Map<String, dynamic>>[];

      final signedParams = await petService.getSignedUploadParams();

      for (int i = 0; i < _photos.length; i++) {
        final entry = _photos[i];
        final result = await cloudinaryService.uploadImage(
          imageFile: entry.file,
          signedParams: signedParams,
        );
        uploadedPhotos.add({
          'cloudinary_url': result['cloudinary_url'],
          'cloudinary_public_id': result['cloudinary_public_id'],
        });
      }

      // Build pet data
      final petData = {
        'name': _nameController.text.trim(),
        'species': _species,
        'breed': _breedController.text.trim().isEmpty
            ? null
            : _breedController.text.trim(),
        'age_months': int.parse(_ageController.text.trim()),
        'sex': _sex,
        'size': _size,
        'weight_kg': _weightController.text.trim().isEmpty
            ? null
            : double.parse(_weightController.text.trim()),
        'color': _colorController.text.trim().isEmpty
            ? null
            : _colorController.text.trim(),
        'is_neutered': _isNeutered,
        'is_vaccinated': _isVaccinated,
        'vaccination_details': _vaccDetailsController.text.trim().isEmpty
            ? null
            : _vaccDetailsController.text.trim(),
        'health_status': _healthController.text.trim().isEmpty
            ? null
            : _healthController.text.trim(),
        'energy_level': _energyLevel,
        'good_with_kids': _goodWithKids,
        'good_with_pets': _goodWithPets,
        'description': _descriptionController.text.trim(),
        'requirements': _requirementsController.text.trim().isEmpty
            ? null
            : _requirementsController.text.trim(),
        'requires_yard': _requiresYard,
        'requires_experience': _requiresExperience,
        'photos': uploadedPhotos,
      };

      await petService.createPet(petData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mascota publicada con éxito'),
            backgroundColor: Color(0xFF28A745),
          ),
        );
        context.go('/donor');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    setState(() => _isSubmitting = false);
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  bool get _step2Valid {
    return _nameController.text.trim().isNotEmpty &&
        _ageController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar Mascota'),
      ),
      body: LoadingOverlay(
        isLoading: _isSubmitting,
        message: 'Publicando...',
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep >= 3) {
              _submit();
              return;
            }
            if (_currentStep == 1 && !_step2Valid) {
              _step2Key.currentState?.validate();
              return;
            }
            setState(() => _currentStep++);
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text(
                      _currentStep >= 3 ? 'Publicar' : 'Siguiente',
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text(_currentStep == 0 ? 'Cancelar' : 'Anterior'),
                  ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Fotos'),
              subtitle: Text('${_photos.length}/5 (mín 2)'),
              isActive: _currentStep >= 0,
              state: _photos.length >= 2
                  ? StepState.complete
                  : StepState.indexed,
              content: _buildPhotoStep(),
            ),
            Step(
              title: const Text('Datos Básicos'),
              isActive: _currentStep >= 1,
              state: _step2Valid ? StepState.complete : StepState.indexed,
              content: _buildBasicDataStep(),
            ),
            Step(
              title: const Text('Salud y Comportamiento'),
              isActive: _currentStep >= 2,
              content: _buildHealthStep(),
            ),
            Step(
              title: const Text('Requisitos'),
              isActive: _currentStep >= 3,
              content: _buildRequirementsStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subí al menos 2 fotos de la mascota. La primera será la foto de portada.',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._photos.asMap().entries.map((entry) {
              final i = entry.key;
              final photo = entry.value;
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      photo.file,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(i),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  if (i == 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Portada',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
            if (_photos.length < 5)
              GestureDetector(
                onTap: _pickPhotos,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      style: BorderStyle.solid,
                    ),
                    color: Colors.grey[50],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, color: Colors.grey[400]),
                      const SizedBox(height: 4),
                      Text(
                        'Agregar',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBasicDataStep() {
    return Form(
      key: _step2Key,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nombre *'),
            textInputAction: TextInputAction.next,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _species,
            decoration: const InputDecoration(labelText: 'Especie *'),
            items: const [
              DropdownMenuItem(value: 'dog', child: Text('Perro')),
              DropdownMenuItem(value: 'cat', child: Text('Gato')),
            ],
            onChanged: (v) => setState(() => _species = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _breedController,
            decoration: const InputDecoration(labelText: 'Raza'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sex,
                  decoration: const InputDecoration(labelText: 'Sexo *'),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Macho')),
                    DropdownMenuItem(value: 'female', child: Text('Hembra')),
                  ],
                  onChanged: (v) => setState(() => _sex = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _size,
                  decoration: const InputDecoration(labelText: 'Tamaño *'),
                  items: const [
                    DropdownMenuItem(value: 'small', child: Text('Pequeño')),
                    DropdownMenuItem(value: 'medium', child: Text('Mediano')),
                    DropdownMenuItem(value: 'large', child: Text('Grande')),
                  ],
                  onChanged: (v) => setState(() => _size = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Edad (meses) *',
                    suffixText: 'meses',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    suffixText: 'kg',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _colorController,
            decoration: const InputDecoration(labelText: 'Color'),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStep() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Esterilizado'),
          value: _isNeutered,
          onChanged: (v) => setState(() => _isNeutered = v),
        ),
        SwitchListTile(
          title: const Text('Vacunado'),
          value: _isVaccinated,
          onChanged: (v) => setState(() => _isVaccinated = v),
        ),
        if (_isVaccinated) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _vaccDetailsController,
            decoration:
                const InputDecoration(labelText: 'Detalle de vacunas'),
            maxLines: 2,
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: _healthController,
          decoration: const InputDecoration(labelText: 'Estado de salud'),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _energyLevel,
          decoration: const InputDecoration(labelText: 'Nivel de energía'),
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Baja')),
            DropdownMenuItem(value: 'medium', child: Text('Media')),
            DropdownMenuItem(value: 'high', child: Text('Alta')),
          ],
          onChanged: (v) => setState(() => _energyLevel = v!),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: 'Descripción *'),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Bueno con:'),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text('Niños'),
              selected: _goodWithKids == true,
              selectedColor: Colors.green[100],
              onSelected: (v) {
                setState(() {
                  _goodWithKids = _goodWithKids == true ? null : true;
                });
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Mascotas'),
              selected: _goodWithPets == true,
              selectedColor: Colors.green[100],
              onSelected: (v) {
                setState(() {
                  _goodWithPets = _goodWithPets == true ? null : true;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirementsStep() {
    return Form(
      key: _step4Key,
      child: Column(
        children: [
          TextFormField(
            controller: _requirementsController,
            decoration: const InputDecoration(
              labelText: 'Requisitos para el adoptante',
              hintText: 'Ej: Tener espacio amplio, experiencia previa...',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Requiere patio'),
            subtitle: const Text('La mascota necesita espacio exterior'),
            value: _requiresYard,
            onChanged: (v) => setState(() => _requiresYard = v),
          ),
          SwitchListTile(
            title: const Text('Requiere experiencia previa'),
            subtitle: const Text('El adoptante debe tener experiencia con mascotas'),
            value: _requiresExperience,
            onChanged: (v) => setState(() => _requiresExperience = v),
          ),
        ],
      ),
    );
  }
}

class _PhotoEntry {
  final File file;
  const _PhotoEntry(this.file);
}
