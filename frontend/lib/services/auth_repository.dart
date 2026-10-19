import 'dart:typed_data';

import '../models/user_profile.dart';

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthRepository {
  bool get isDemo;

  Future<UserProfile> signIn({required String email, required String password});

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
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
  });

  Future<UserProfile> updateProfile({
    required String name,
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
  });

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  Future<UserProfile?> currentProfile();

  Future<void> updateAccessibilityPreferences(
    AccessibilityPreferences preferences,
  );

  Future<UserProfile> updateProfilePhoto(Uint8List bytes);
}

class DemoAuthRepository implements AuthRepository {
  const DemoAuthRepository();

  @override
  bool get isDemo => true;

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    return email == MockUsers.therapist.email
        ? MockUsers.therapist
        : MockUsers.patient;
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
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
  }) async {
    return UserProfile(
      name: name,
      email: email,
      role: role,
      phone: phone,
      professionalRegistration: professionalRegistration,
      affectedSide: affectedSide,
      strokeType: strokeType,
      mobility: mobility,
      ageRange: ageRange,
      monthsSinceStroke: monthsSinceStroke,
      dominantSide: dominantSide,
      assistiveDevice: assistiveDevice,
      participantContext: participantContext ?? 'not_informed',
    );
  }

  @override
  Future<UserProfile> updateProfile({
    required String name,
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
  }) async => UserProfile(
    name: name,
    email: MockUsers.patient.email,
    role: UserRole.patient,
    phone: phone,
    professionalRegistration: professionalRegistration,
    affectedSide: affectedSide,
    strokeType: strokeType,
    mobility: mobility,
    ageRange: ageRange,
    monthsSinceStroke: monthsSinceStroke,
    dominantSide: dominantSide,
    assistiveDevice: assistiveDevice,
    participantContext: participantContext ?? 'not_informed',
  );

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<UserProfile?> currentProfile() async => null;

  @override
  Future<void> updateAccessibilityPreferences(
    AccessibilityPreferences preferences,
  ) async {}

  @override
  Future<UserProfile> updateProfilePhoto(Uint8List bytes) async =>
      MockUsers.patient.copyWith(photoBytes: bytes);
}
