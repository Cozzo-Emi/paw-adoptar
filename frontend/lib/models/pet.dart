class Pet {
  final String id;
  final String donorId;
  final String name;
  final String species;
  final String? breed;
  final int ageMonths;
  final String sex;
  final String size;
  final double? weightKg;
  final String? color;
  final bool isNeutered;
  final bool isVaccinated;
  final String? vaccinationDetails;
  final String? healthStatus;
  final String energyLevel;
  final bool? goodWithKids;
  final bool? goodWithPets;
  final String description;
  final String? requirements;
  final bool requiresYard;
  final bool requiresExperience;
  final String status;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? province;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PetPhoto> photos;
  final double? compatibilityScore;

  const Pet({
    required this.id,
    required this.donorId,
    required this.name,
    required this.species,
    this.breed,
    required this.ageMonths,
    required this.sex,
    required this.size,
    this.weightKg,
    this.color,
    required this.isNeutered,
    required this.isVaccinated,
    this.vaccinationDetails,
    this.healthStatus,
    required this.energyLevel,
    this.goodWithKids,
    this.goodWithPets,
    required this.description,
    this.requirements,
    required this.requiresYard,
    required this.requiresExperience,
    required this.status,
    this.latitude,
    this.longitude,
    this.city,
    this.province,
    required this.createdAt,
    required this.updatedAt,
    this.photos = const [],
    this.compatibilityScore,
  });

  String get coverImage =>
      photos.isNotEmpty ? _optimizeUrl(photos.first.cloudinaryUrl) : '';

  String get coverImageOptimized =>
      photos.isNotEmpty ? _optimizeUrl(photos.first.cloudinaryUrl) : '';

  static String _optimizeUrl(String url) {
    if (url.contains('cloudinary.com') && url.contains('/upload/')) {
      return url.replaceFirst('/upload/', '/upload/q_auto:eco,f_auto/');
    }
    return url;
  }

  String get ageFormatted {
    if (ageMonths < 12) {
      return ageMonths == 1 ? '1 mes' : '$ageMonths meses';
    }
    final years = ageMonths ~/ 12;
    final months = ageMonths % 12;
    if (months == 0) return years == 1 ? '1 año' : '$years años';
    return '$years a. ${months}m.';
  }

  String get speciesLabel => species == 'dog' ? 'Perro' : 'Gato';

  String get sexLabel => sex == 'male' ? 'Macho' : 'Hembra';

  factory Pet.fromJson(Map<String, dynamic> json) {
    final photosList = (json['photos'] as List<dynamic>?)
            ?.map((p) => PetPhoto.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    return Pet(
      id: json['id'] as String,
      donorId: json['donor_id'] as String,
      name: json['name'] as String,
      species: json['species'] as String,
      breed: json['breed'] as String?,
      ageMonths: json['age_months'] as int,
      sex: json['sex'] as String,
      size: json['size'] as String,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      color: json['color'] as String?,
      isNeutered: json['is_neutered'] as bool,
      isVaccinated: json['is_vaccinated'] as bool,
      vaccinationDetails: json['vaccination_details'] as String?,
      healthStatus: json['health_status'] as String?,
      energyLevel: json['energy_level'] as String,
      goodWithKids: json['good_with_kids'] as bool?,
      goodWithPets: json['good_with_pets'] as bool?,
      description: json['description'] as String,
      requirements: json['requirements'] as String?,
      requiresYard: json['requires_yard'] as bool,
      requiresExperience: json['requires_experience'] as bool,
      status: json['status'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      city: json['city'] as String?,
      province: json['province'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      photos: photosList,
      compatibilityScore: (json['compatibility_score'] as num?)?.toDouble(),
    );
  }
}

class PetPhoto {
  final String id;
  final String petId;
  final String cloudinaryUrl;
  final String cloudinaryPublicId;
  final bool isPrimary;
  final int order;
  final DateTime createdAt;

  const PetPhoto({
    required this.id,
    required this.petId,
    required this.cloudinaryUrl,
    required this.cloudinaryPublicId,
    required this.isPrimary,
    required this.order,
    required this.createdAt,
  });

  String get optimizedUrl {
    if (cloudinaryUrl.contains('cloudinary.com') && cloudinaryUrl.contains('/upload/')) {
      return cloudinaryUrl.replaceFirst('/upload/', '/upload/q_auto:eco,f_auto/');
    }
    return cloudinaryUrl;
  }

  factory PetPhoto.fromJson(Map<String, dynamic> json) {
    return PetPhoto(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      cloudinaryUrl: json['cloudinary_url'] as String? ?? '',
      cloudinaryPublicId: json['cloudinary_public_id'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
