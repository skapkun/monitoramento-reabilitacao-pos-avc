import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movere_app/models/user_profile.dart';
import 'package:movere_app/screens/patient/patient_profile_screen.dart';
import 'package:movere_app/screens/therapist/therapist_profile_screen.dart';
import 'package:movere_app/services/auth_repository.dart';

class RecordingAuthRepository implements AuthRepository {
  RecordingAuthRepository({this.role = UserRole.patient});

  final UserRole role;
  AccessibilityPreferences? savedPreferences;
  UserProfile? updatedProfile;
  Uint8List? updatedPhoto;

  @override
  bool get isDemo => false;

  @override
  Future<UserProfile?> currentProfile() async => UserProfile(
    id: 'patient-1',
    name: role == UserRole.patient ? 'Paciente Teste' : 'Profissional Teste',
    email: role == UserRole.patient
        ? 'paciente@exemplo.com'
        : 'profissional@exemplo.com',
    role: role,
    professionalRegistration: role == UserRole.therapist
        ? 'CREFITO 100-F'
        : null,
    accessibilityPreferences: const AccessibilityPreferences(
      largerText: false,
      reducedMotion: true,
      repeatInstructions: false,
    ),
  );

  @override
  Future<void> updateAccessibilityPreferences(
    AccessibilityPreferences preferences,
  ) async {
    savedPreferences = preferences;
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
  }) => throw UnimplementedError();

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
    updatedProfile = UserProfile(
      id: 'patient-1',
      name: name.trim(),
      email: 'paciente@exemplo.com',
      role: role,
      phone: phone?.trim(),
      professionalRegistration: professionalRegistration?.trim(),
      affectedSide: affectedSide,
      strokeType: strokeType,
      mobility: mobility,
      ageRange: ageRange,
      monthsSinceStroke: monthsSinceStroke,
      dominantSide: dominantSide,
      assistiveDevice: assistiveDevice,
      participantContext: participantContext ?? 'not_informed',
    );
    return updatedProfile!;
  }

  @override
  Future<UserProfile> updateProfilePhoto(Uint8List bytes) async {
    updatedPhoto = bytes;
    return (await currentProfile())!.copyWith(photoBytes: bytes);
  }

  @override
  Future<void> sendPasswordReset(String email) => throw UnimplementedError();

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('carrega e salva preferências de acessibilidade', (tester) async {
    final repository = RecordingAuthRepository();
    await tester.pumpWidget(
      MaterialApp(home: PatientProfileScreen(authRepository: repository)),
    );
    await tester.pumpAndSettle();

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches.map((item) => item.value), [false, false, true]);

    await tester.ensureVisible(find.text('Texto ampliado'));
    await tester.tap(find.text('Texto ampliado'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('salvar_preferencias')));
    await tester.tap(find.byKey(const Key('salvar_preferencias')));
    await tester.pumpAndSettle();

    expect(repository.savedPreferences?.largerText, isTrue);
    expect(repository.savedPreferences?.reducedMotion, isTrue);
    expect(repository.savedPreferences?.repeatInstructions, isFalse);
    expect(find.text('Preferências salvas.'), findsOneWidget);
  });

  testWidgets('edita e apresenta dados pessoais persistidos', (tester) async {
    final repository = RecordingAuthRepository();
    await tester.pumpWidget(
      MaterialApp(home: PatientProfileScreen(authRepository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('editar_perfil')));
    await tester.tap(find.byKey(const Key('editar_perfil')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('editar_nome')),
      'Paciente Atualizado',
    );
    await tester.enterText(
      find.byKey(const Key('editar_telefone')),
      '(69) 99999-0000',
    );
    await tester.ensureVisible(find.byKey(const Key('editar_meses_desde_avc')));
    await tester.enterText(
      find.byKey(const Key('editar_meses_desde_avc')),
      '18',
    );
    await tester.ensureVisible(find.byKey(const Key('salvar_perfil')));
    await tester.tap(find.byKey(const Key('salvar_perfil')));
    await tester.pumpAndSettle();

    expect(repository.updatedProfile?.name, 'Paciente Atualizado');
    expect(repository.updatedProfile?.phone, '(69) 99999-0000');
    expect(repository.updatedProfile?.monthsSinceStroke, 18);
    expect(find.text('Paciente Atualizado'), findsOneWidget);
    expect(find.text('Perfil atualizado.'), findsOneWidget);
  });

  testWidgets('edita registro do perfil profissional', (tester) async {
    final repository = RecordingAuthRepository(role: UserRole.therapist);
    await tester.pumpWidget(
      MaterialApp(home: TherapistProfileScreen(authRepository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('editar_perfil')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('editar_registro_profissional')),
      'CREFITO 200-F',
    );
    await tester.tap(find.byKey(const Key('salvar_perfil')));
    await tester.pumpAndSettle();

    expect(
      repository.updatedProfile?.professionalRegistration,
      'CREFITO 200-F',
    );
    expect(find.textContaining('CREFITO 200-F'), findsOneWidget);
  });

  testWidgets('altera a foto do perfil do paciente', (tester) async {
    final repository = RecordingAuthRepository();
    final photo = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PatientProfileScreen(
          authRepository: repository,
          photoPicker: () async => photo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('alterar_foto_perfil')));
    await tester.pumpAndSettle();

    expect(repository.updatedPhoto, photo);
    expect(find.text('Foto de perfil atualizada.'), findsOneWidget);
  });

  testWidgets('altera a foto do perfil profissional', (tester) async {
    final repository = RecordingAuthRepository(role: UserRole.therapist);
    final photo = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TherapistProfileScreen(
          authRepository: repository,
          photoPicker: () async => photo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('alterar_foto_perfil')));
    await tester.pumpAndSettle();

    expect(repository.updatedPhoto, photo);
    expect(find.text('Foto de perfil atualizada.'), findsOneWidget);
  });
}
