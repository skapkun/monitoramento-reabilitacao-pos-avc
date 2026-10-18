import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final ValueNotifier<AccessibilityPreferences> accessibilityPreferences =
      ValueNotifier(const AccessibilityPreferences());

  @override
  bool get isDemo => false;

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final profile = await _profileFor(credential.user!.uid);
      if (profile == null) {
        await _auth.signOut();
        throw const AuthRepositoryException(
          'A conta existe, mas o perfil do Movere não foi encontrado.',
        );
      }
      return profile;
    } on FirebaseAuthException catch (error) {
      throw AuthRepositoryException(_messageFor(error));
    } on AuthRepositoryException {
      rethrow;
    } on FirebaseException {
      throw const AuthRepositoryException(
        'Não foi possível carregar seu perfil. Tente novamente.',
      );
    }
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
    User? createdUser;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      createdUser = credential.user;
      await createdUser!.updateDisplayName(name.trim());
      final profile = UserProfile(
        id: createdUser.uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
        phone: _optional(phone),
        professionalRegistration: role == UserRole.therapist
            ? _optional(professionalRegistration)
            : null,
        affectedSide: role == UserRole.patient ? _optional(affectedSide) : null,
        strokeType: role == UserRole.patient ? _optional(strokeType) : null,
        mobility: role == UserRole.patient ? _optional(mobility) : null,
        ageRange: role == UserRole.patient ? _optional(ageRange) : null,
        monthsSinceStroke: role == UserRole.patient ? monthsSinceStroke : null,
        dominantSide: role == UserRole.patient ? _optional(dominantSide) : null,
        assistiveDevice: role == UserRole.patient
            ? _optional(assistiveDevice)
            : null,
        participantContext: role == UserRole.patient
            ? participantContext ?? 'not_informed'
            : 'not_informed',
      );
      final data = <String, Object?>{
        'name': profile.name,
        'email': profile.email,
        'role': profile.role.name,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (profile.phone != null) data['phone'] = profile.phone;
      if (profile.professionalRegistration != null) {
        data['professionalRegistration'] = profile.professionalRegistration;
      }
      if (profile.affectedSide != null) {
        data['affectedSide'] = profile.affectedSide;
      }
      if (profile.strokeType != null) data['strokeType'] = profile.strokeType;
      if (profile.mobility != null) data['mobility'] = profile.mobility;
      if (profile.ageRange != null) data['ageRange'] = profile.ageRange;
      if (profile.monthsSinceStroke != null) {
        data['monthsSinceStroke'] = profile.monthsSinceStroke;
      }
      if (profile.dominantSide != null) {
        data['dominantSide'] = profile.dominantSide;
      }
      if (profile.assistiveDevice != null) {
        data['assistiveDevice'] = profile.assistiveDevice;
      }
      if (role == UserRole.patient) {
        data['participantContext'] = profile.participantContext;
      }
      await _firestore.collection('users').doc(createdUser.uid).set(data);
      return profile;
    } on FirebaseAuthException catch (error) {
      throw AuthRepositoryException(_messageFor(error));
    } on FirebaseException {
      await createdUser?.delete();
      throw const AuthRepositoryException(
        'Não foi possível salvar o perfil. Nenhuma conta incompleta foi mantida.',
      );
    }
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
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthRepositoryException(
        'Sua sessão expirou. Entre novamente.',
      );
    }
    final current = await _profileFor(user.uid);
    if (current == null) {
      throw const AuthRepositoryException('Perfil não encontrado.');
    }
    final normalizedName = name.trim();
    final normalizedPhone = _optional(phone);
    final normalizedRegistration = current.role == UserRole.therapist
        ? _optional(professionalRegistration)
        : null;
    final normalizedAffectedSide = current.role == UserRole.patient
        ? _optional(affectedSide)
        : null;
    final normalizedStrokeType = current.role == UserRole.patient
        ? _optional(strokeType)
        : null;
    final normalizedMobility = current.role == UserRole.patient
        ? _optional(mobility)
        : null;
    final normalizedAgeRange = current.role == UserRole.patient
        ? _optional(ageRange)
        : null;
    final normalizedDominantSide = current.role == UserRole.patient
        ? _optional(dominantSide)
        : null;
    final normalizedAssistiveDevice = current.role == UserRole.patient
        ? _optional(assistiveDevice)
        : null;
    final normalizedParticipantContext = current.role == UserRole.patient
        ? participantContext ?? current.participantContext
        : 'not_informed';
    try {
      await user.updateDisplayName(normalizedName);
      final updates = <String, Object?>{
        'name': normalizedName,
        'phone': normalizedPhone ?? FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (current.role == UserRole.therapist) {
        updates['professionalRegistration'] =
            normalizedRegistration ?? FieldValue.delete();
      }
      if (current.role == UserRole.patient) {
        updates['affectedSide'] = normalizedAffectedSide ?? FieldValue.delete();
        updates['strokeType'] = normalizedStrokeType ?? FieldValue.delete();
        updates['mobility'] = normalizedMobility ?? FieldValue.delete();
        updates['ageRange'] = normalizedAgeRange ?? FieldValue.delete();
        updates['monthsSinceStroke'] = monthsSinceStroke ?? FieldValue.delete();
        updates['dominantSide'] = normalizedDominantSide ?? FieldValue.delete();
        updates['assistiveDevice'] =
            normalizedAssistiveDevice ?? FieldValue.delete();
        updates['participantContext'] = normalizedParticipantContext;
      }
      await _firestore.collection('users').doc(user.uid).update(updates);
      return UserProfile(
        id: current.id,
        name: normalizedName,
        email: current.email,
        role: current.role,
        phone: normalizedPhone,
        professionalRegistration: normalizedRegistration,
        affectedSide: normalizedAffectedSide,
        strokeType: normalizedStrokeType,
        mobility: normalizedMobility,
        ageRange: normalizedAgeRange,
        monthsSinceStroke: monthsSinceStroke,
        dominantSide: normalizedDominantSide,
        assistiveDevice: normalizedAssistiveDevice,
        participantContext: normalizedParticipantContext,
        accessibilityPreferences: current.accessibilityPreferences,
      );
    } on FirebaseException {
      throw const AuthRepositoryException(
        'Não foi possível atualizar o perfil. Tente novamente.',
      );
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthRepositoryException(_messageFor(error));
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    accessibilityPreferences.value = const AccessibilityPreferences();
  }

  @override
  Future<UserProfile?> currentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      return await _profileFor(user.uid);
    } on AuthRepositoryException {
      rethrow;
    } on FirebaseException {
      throw const AuthRepositoryException(
        'Não foi possível restaurar sua sessão.',
      );
    }
  }

  @override
  Future<void> updateAccessibilityPreferences(
    AccessibilityPreferences preferences,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthRepositoryException(
        'Sua sessão expirou. Entre novamente.',
      );
    }
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'accessibilityPreferences': preferences.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      accessibilityPreferences.value = preferences;
    } on FirebaseException {
      throw const AuthRepositoryException(
        'Não foi possível salvar as preferências. Tente novamente.',
      );
    }
  }

  Future<UserProfile?> _profileFor(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data == null || data['active'] == false) return null;
    final roleValue = data['role']?.toString();
    final role = UserRole.values
        .where((item) => item.name == roleValue)
        .firstOrNull;
    if (role == null) {
      throw const AuthRepositoryException(
        'O perfil possui um tipo de acesso inválido.',
      );
    }
    final profile = UserProfile(
      id: uid,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      role: role,
      phone: data['phone']?.toString(),
      professionalRegistration: data['professionalRegistration']?.toString(),
      affectedSide: data['affectedSide']?.toString(),
      strokeType: data['strokeType']?.toString(),
      mobility: data['mobility']?.toString(),
      ageRange: data['ageRange']?.toString(),
      monthsSinceStroke: (data['monthsSinceStroke'] as num?)?.toInt(),
      dominantSide: data['dominantSide']?.toString(),
      assistiveDevice: data['assistiveDevice']?.toString(),
      participantContext:
          data['participantContext']?.toString() ?? 'not_informed',
      accessibilityPreferences: AccessibilityPreferences.fromJson(
        data['accessibilityPreferences'] is Map
            ? Map<String, dynamic>.from(data['accessibilityPreferences'] as Map)
            : null,
      ),
    );
    accessibilityPreferences.value = profile.accessibilityPreferences;
    return profile;
  }

  String? _optional(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  String _messageFor(FirebaseAuthException error) => switch (error.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'E-mail ou senha incorretos.',
    'email-already-in-use' => 'Este e-mail já possui uma conta.',
    'invalid-email' => 'Informe um e-mail válido.',
    'weak-password' => 'Escolha uma senha mais forte.',
    'too-many-requests' =>
      'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
    'network-request-failed' =>
      'Não foi possível acessar o serviço. Verifique sua conexão.',
    'operation-not-allowed' =>
      'O login por e-mail ainda não foi habilitado no Firebase.',
    _ => 'Não foi possível concluir a autenticação. Tente novamente.',
  };
}
