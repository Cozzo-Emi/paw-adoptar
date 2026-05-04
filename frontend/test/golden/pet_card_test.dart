import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paw/config/theme.dart';
import 'package:paw/widgets/pet_card.dart';
import 'package:paw/models/pet.dart';

void main() {
  group('PetCard golden', () {
    testWidgets('renders correctly with data', (tester) async {
      final pet = Pet(
        id: '1', donorId: '2', name: 'Firulais', species: 'dog',
        ageMonths: 24, sex: 'male', size: 'medium', isNeutered: true,
        isVaccinated: true, energyLevel: 'medium', description: 'Un perro muy leal',
        requiresYard: false, requiresExperience: false, status: 'available',
        city: 'Buenos Aires', createdAt: DateTime.now(), updatedAt: DateTime.now(),
        photos: [
          PetPhoto(id: 'p1', petId: '1', cloudinaryUrl: '', cloudinaryPublicId: '', isPrimary: true, order: 0, createdAt: DateTime.now()),
        ],
        compatibilityScore: 0.75,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: PetCard(pet: pet)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Firulais'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });
  });
}
