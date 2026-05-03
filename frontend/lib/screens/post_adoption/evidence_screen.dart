import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../../models/match.dart';
import '../../providers/match_provider.dart';
import '../../services/api_client.dart';
import '../../services/cloudinary_service.dart';
import '../../services/pet_service.dart';

class EvidenceScreen extends StatefulWidget {
  final Match match;

  const EvidenceScreen({super.key, required this.match});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  final _imagePicker = ImagePicker();
  XFile? _photo;
  final _statusNoteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _statusNoteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _photo = file);
  }

  Future<void> _submit() async {
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subí una foto del animal')),
      );
      return;
    }

    if (_statusNoteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describí cómo está el animal')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = context.read<ApiClient>();
      final matchProvider = context.read<MatchProvider>();
      final cloudinaryService = CloudinaryService();
      final petService = PetService(client: apiClient);

      final signedParams = await petService.getSignedUploadParams();
      final bytes = await _photo!.readAsBytes();
      final uploadResult = await cloudinaryService.uploadImageBytes(
        bytes: bytes,
        filename: 'evidence.jpg',
        signedParams: signedParams,
      );

      final success = await matchProvider.submitEvidence(
        matchId: widget.match.id,
        photoUrl: uploadResult['cloudinary_url'] as String,
        cloudinaryPublicId: uploadResult['cloudinary_public_id'] as String,
        statusNote: _statusNoteController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Evidencia enviada. ¡Gracias!'),
              backgroundColor: Color(0xFF28A745),
            ),
          );
          context.go('/matches');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(matchProvider.error ?? 'Error al enviar'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        String msg = e.message ?? e.toString();
        if (e.response?.data != null) {
          msg = 'Error del servidor: ${e.response!.data}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento Post-Adopción')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.pets, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              '¿Cómo está tu nueva mascota?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Subí una foto reciente para confirmar su bienestar y sumá puntos de reputación.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // Photo picker
            if (_photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    _PhotoPreview(file: _photo!),
                    Positioned(
                      top: 8, right: 8,
                      child: IconButton(
                        onPressed: () => setState(() => _photo = null),
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.black38),
                      ),
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                    color: Colors.grey[50],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('Tocar para subir foto', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                ),
              ),
            if (_photo != null)
              TextButton(onPressed: _pickPhoto, child: const Text('Cambiar foto')),

            const SizedBox(height: 24),
            TextField(
              controller: _statusNoteController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '¿Cómo se está adaptando?',
                hintText: 'Contanos cómo está, si come bien, cómo se comporta...',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Enviar Evidencia'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final XFile file;
  const _PhotoPreview({required this.file});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(snapshot.data!, width: double.infinity, height: 250, fit: BoxFit.cover);
        }
        return Container(width: double.infinity, height: 250, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
      },
    );
  }
}
