import 'dart:typed_data';

enum UserRole { patient, therapist }

class AccessibilityPreferences {
  const AccessibilityPreferences({
    this.largerText = true,
    this.reducedMotion = false,
    this.repeatInstructions = true,
  });

  final bool largerText;
  final bool reducedMotion;
  final bool repeatInstructions;

  Map<String, bool> toJson() => {
    'largerText': largerText,
    'reducedMotion': reducedMotion,
    'repeatInstructions': repeatInstructions,
  };

  factory AccessibilityPreferences.fromJson(Map<String, dynamic>? json) =>
      AccessibilityPreferences(
        largerText: json?['largerText'] is bool
            ? json!['largerText'] as bool
            : true,
        reducedMotion: json?['reducedMotion'] is bool
            ? json!['reducedMotion'] as bool
            : false,
        repeatInstructions: json?['repeatInstructions'] is bool
            ? json!['repeatInstructions'] as bool
            : true,
      );
}

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
    UserRole.patient => 'Paciente',
    UserRole.therapist => 'Fisioterapeuta',
  };
}

class UserProfile {
  const UserProfile({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.professionalRegistration,
    this.affectedSide,
    this.strokeType,
    this.mobility,
    this.ageRange,
    this.monthsSinceStroke,
    this.dominantSide,
    this.assistiveDevice,
    this.participantContext = 'not_informed',
    this.accessibilityPreferences = const AccessibilityPreferences(),
    this.photoBytes,
  });

  final String? id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? professionalRegistration;
  final String? affectedSide;
  final String? strokeType;
  final String? mobility;
  final String? ageRange;
  final int? monthsSinceStroke;
  final String? dominantSide;
  final String? assistiveDevice;
  final String participantContext;
  final AccessibilityPreferences accessibilityPreferences;
  final Uint8List? photoBytes;

  UserProfile copyWith({
    String? name,
    String? phone,
    String? professionalRegistration,
    String? affectedSide,
    String? strokeType,
    String? mobility,
    String? ageRange,
    int? monthsSinceStroke,
    String? dominantSide,
    String? assistiveDevice,
    String? participantContext,
    AccessibilityPreferences? accessibilityPreferences,
    Uint8List? photoBytes,
  }) => UserProfile(
    id: id,
    name: name ?? this.name,
    email: email,
    role: role,
    phone: phone ?? this.phone,
    professionalRegistration:
        professionalRegistration ?? this.professionalRegistration,
    affectedSide: affectedSide ?? this.affectedSide,
    strokeType: strokeType ?? this.strokeType,
    mobility: mobility ?? this.mobility,
    ageRange: ageRange ?? this.ageRange,
    monthsSinceStroke: monthsSinceStroke ?? this.monthsSinceStroke,
    dominantSide: dominantSide ?? this.dominantSide,
    assistiveDevice: assistiveDevice ?? this.assistiveDevice,
    participantContext: participantContext ?? this.participantContext,
    accessibilityPreferences:
        accessibilityPreferences ?? this.accessibilityPreferences,
    photoBytes: photoBytes ?? this.photoBytes,
  );
}

abstract final class MockUsers {
  static const patient = UserProfile(
    name: 'Maria Oliveira',
    email: 'maria@exemplo.com',
    phone: '(69) 99999-1001',
    role: UserRole.patient,
    affectedSide: 'right',
    strokeType: 'Não informado',
    mobility: 'Com apoio',
    ageRange: '60_69',
    monthsSinceStroke: 18,
    dominantSide: 'right',
    assistiveDevice: 'cane',
  );

  static const therapist = UserProfile(
    name: 'Dra. Ana Souza',
    email: 'ana@exemplo.com',
    phone: '(69) 99999-2002',
    professionalRegistration: 'CREFITO 000000-F',
    role: UserRole.therapist,
  );
}
