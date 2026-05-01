class User {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final bool isActive;
  final bool isVerifiedEmail;
  final bool isVerifiedPhone;
  final int verificationLevel;
  final double reputationScore;
  final int reputationCount;
  final String? city;
  final String? province;
  final String? fcmToken;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.isActive,
    required this.isVerifiedEmail,
    required this.isVerifiedPhone,
    required this.verificationLevel,
    required this.reputationScore,
    required this.reputationCount,
    this.city,
    this.province,
    this.fcmToken,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      isVerifiedEmail: json['is_verified_email'] as bool,
      isVerifiedPhone: json['is_verified_phone'] as bool,
      verificationLevel: json['verification_level'] as int,
      reputationScore: (json['reputation_score'] as num).toDouble(),
      reputationCount: json['reputation_count'] as int,
      city: json['city'] as String?,
      province: json['province'] as String?,
      fcmToken: json['fcm_token'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'is_active': isActive,
      'is_verified_email': isVerifiedEmail,
      'is_verified_phone': isVerifiedPhone,
      'verification_level': verificationLevel,
      'reputation_score': reputationScore,
      'reputation_count': reputationCount,
      'city': city,
      'province': province,
      'fcm_token': fcmToken,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isAdopter => role == 'adopter' || role == 'both';
  bool get isDonor => role == 'donor' || role == 'both';
}

class AuthToken {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  const AuthToken({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
    };
  }
}

class AdopterProfile {
  final String id;
  final String userId;
  final String? housingType;
  final bool hasYard;
  final String? yardSize;
  final bool hasOtherPets;
  final String? otherPetsDetails;
  final bool hasChildren;
  final String? childrenAges;
  final int? dailyHoursAlone;
  final String? experienceLevel;
  final String? preferredSpecies;
  final String? preferredSize;
  final int? preferredAgeMin;
  final int? preferredAgeMax;
  final String? preferredEnergyLevel;
  final int maxDistanceKm;
  final String? additionalNotes;
  final DateTime createdAt;

  const AdopterProfile({
    required this.id,
    required this.userId,
    this.housingType,
    required this.hasYard,
    this.yardSize,
    required this.hasOtherPets,
    this.otherPetsDetails,
    required this.hasChildren,
    this.childrenAges,
    this.dailyHoursAlone,
    this.experienceLevel,
    this.preferredSpecies,
    this.preferredSize,
    this.preferredAgeMin,
    this.preferredAgeMax,
    this.preferredEnergyLevel,
    required this.maxDistanceKm,
    this.additionalNotes,
    required this.createdAt,
  });

  factory AdopterProfile.fromJson(Map<String, dynamic> json) {
    return AdopterProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      housingType: json['housing_type'] as String?,
      hasYard: json['has_yard'] as bool,
      yardSize: json['yard_size'] as String?,
      hasOtherPets: json['has_other_pets'] as bool,
      otherPetsDetails: json['other_pets_details'] as String?,
      hasChildren: json['has_children'] as bool,
      childrenAges: json['children_ages'] as String?,
      dailyHoursAlone: json['daily_hours_alone'] as int?,
      experienceLevel: json['experience_level'] as String?,
      preferredSpecies: json['preferred_species'] as String?,
      preferredSize: json['preferred_size'] as String?,
      preferredAgeMin: json['preferred_age_min'] as int?,
      preferredAgeMax: json['preferred_age_max'] as int?,
      preferredEnergyLevel: json['preferred_energy_level'] as String?,
      maxDistanceKm: json['max_distance_km'] as int,
      additionalNotes: json['additional_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class DonorProfile {
  final String id;
  final String userId;
  final bool isOrganization;
  final String? organizationName;
  final String? bio;
  final int totalPetsDonated;
  final DateTime createdAt;

  const DonorProfile({
    required this.id,
    required this.userId,
    required this.isOrganization,
    this.organizationName,
    this.bio,
    required this.totalPetsDonated,
    required this.createdAt,
  });

  factory DonorProfile.fromJson(Map<String, dynamic> json) {
    return DonorProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      isOrganization: json['is_organization'] as bool,
      organizationName: json['organization_name'] as String?,
      bio: json['bio'] as String?,
      totalPetsDonated: json['total_pets_donated'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
