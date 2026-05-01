class Match {
  final String id;
  final String petId;
  final String adopterId;
  final String donorId;
  final String status;
  final double? compatibilityScore;
  final String? adopterMessage;
  final String? donorResponse;
  final DateTime? matchedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Match({
    required this.id,
    required this.petId,
    required this.adopterId,
    required this.donorId,
    required this.status,
    this.compatibilityScore,
    this.adopterMessage,
    this.donorResponse,
    this.matchedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'accepted':
        return 'Aceptado';
      case 'rejected':
        return 'Rechazado';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      adopterId: json['adopter_id'] as String,
      donorId: json['donor_id'] as String,
      status: json['status'] as String,
      compatibilityScore: (json['compatibility_score'] as num?)?.toDouble(),
      adopterMessage: json['adopter_message'] as String?,
      donorResponse: json['donor_response'] as String?,
      matchedAt: json['matched_at'] != null
          ? DateTime.parse(json['matched_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
