import 'package:flutter/material.dart';

import '../models/patient_summary.dart';
import '../models/selected_video.dart';
import '../models/clinical_data.dart';
import '../services/analysis_api_service.dart';
import '../services/auth_repository.dart';
import '../services/clinical_repository.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/patient/exercise_screen.dart';
import '../screens/patient/patient_home_screen.dart';
import '../screens/patient/patient_profile_screen.dart';
import '../screens/patient/history_screen.dart';
import '../screens/patient/progress_screen.dart';
import '../screens/patient/orientations_screen.dart';
import '../screens/patient/plan_screen.dart';
import '../screens/patient/preparation_screen.dart';
import '../screens/patient/processing_screen.dart';
import '../screens/patient/recording_screen.dart';
import '../screens/patient/result_screen.dart';
import '../screens/patient/wellbeing_screen.dart';
import '../screens/shared/placeholder_screen.dart';
import '../screens/shared/messages_screen.dart';
import '../screens/therapist/therapist_home_screen.dart';
import '../screens/therapist/patient_details_screen.dart';
import '../screens/therapist/patients_screen.dart';
import '../screens/therapist/therapist_profile_screen.dart';
import '../screens/therapist/plan_management_screen.dart';
import '../screens/therapist/sessions_screen.dart';
import '../screens/therapist/notes_screen.dart';
import '../screens/therapist/reports_screen.dart';
import '../screens/therapist/analysis_method_screen.dart';

abstract final class AppRoutes {
  static const login = '/';
  static const register = '/cadastro';
  static const forgotPassword = '/recuperar-senha';
  static const patientHome = '/paciente';
  static const patientPlan = '/paciente/plano';
  static const exercise = '/paciente/exercicio';
  static const preparation = '/paciente/preparacao';
  static const recording = '/paciente/gravacao';
  static const processing = '/paciente/processamento';
  static const result = '/paciente/resultado';
  static const patientHistory = '/paciente/historico';
  static const patientProgress = '/paciente/evolucao';
  static const patientProfile = '/paciente/perfil';
  static const patientOrientations = '/paciente/orientacoes';
  static const wellbeing = '/paciente/bem-estar';
  static const therapistHome = '/fisioterapeuta';
  static const therapistProfile = '/fisioterapeuta/perfil';
  static const patients = '/fisioterapeuta/pacientes';
  static const patientDetails = '/fisioterapeuta/paciente';
  static const therapistPlan = '/fisioterapeuta/plano';
  static const sessions = '/fisioterapeuta/sessoes';
  static const therapistProgress = '/fisioterapeuta/evolucao';
  static const reports = '/fisioterapeuta/relatorios';
  static const notes = '/fisioterapeuta/observacoes';
  static const patientMessages = '/paciente/mensagens';
  static const therapistMessages = '/fisioterapeuta/mensagens';
  static const analysisMethod = '/fisioterapeuta/metodo-analise';

  static Route<void> onGenerateRoute(
    RouteSettings settings, {
    AuthRepository authRepository = const DemoAuthRepository(),
    ClinicalRepository clinicalRepository = const DemoClinicalRepository(),
  }) {
    final screen = switch (settings.name) {
      login => LoginScreen(authRepository: authRepository),
      register => RegisterScreen(authRepository: authRepository),
      forgotPassword => ForgotPasswordScreen(authRepository: authRepository),
      patientHome => PatientHomeScreen(
        authRepository: authRepository,
        clinicalRepository: clinicalRepository,
      ),
      patientPlan => PlanScreen(repository: clinicalRepository),
      exercise => ExerciseScreen(
        plan: settings.arguments is TherapyPlan
            ? settings.arguments! as TherapyPlan
            : null,
      ),
      preparation => PreparationScreen(
        plan: settings.arguments is TherapyPlan
            ? settings.arguments! as TherapyPlan
            : null,
      ),
      recording => RecordingScreen(
        allowSimulation: clinicalRepository.isDemo,
        plan: settings.arguments is TherapyPlan
            ? settings.arguments! as TherapyPlan
            : null,
      ),
      processing => ProcessingScreen(
        clinicalRepository: clinicalRepository,
        video: settings.arguments is SelectedVideo
            ? settings.arguments! as SelectedVideo
            : null,
      ),
      result => ResultScreen(
        inconclusive: settings.arguments == true,
        result: settings.arguments is AnalysisApiResponse
            ? settings.arguments! as AnalysisApiResponse
            : null,
      ),
      wellbeing => WellbeingScreen(
        repository: clinicalRepository,
        sessionId: settings.arguments?.toString() ?? '',
      ),
      patientHistory => HistoryScreen(
        repository: clinicalRepository,
        authRepository: authRepository,
      ),
      patientProgress => PatientProgressScreen(repository: clinicalRepository),
      patientProfile => PatientProfileScreen(authRepository: authRepository),
      patientOrientations => OrientationsScreen(repository: clinicalRepository),
      therapistHome => TherapistHomeScreen(
        authRepository: authRepository,
        clinicalRepository: clinicalRepository,
      ),
      therapistProfile => TherapistProfileScreen(
        authRepository: authRepository,
      ),
      patients => PatientsScreen(
        repository: clinicalRepository,
        initialFilter: settings.arguments is PatientFilter
            ? settings.arguments! as PatientFilter
            : PatientFilter.all,
      ),
      patientDetails => PatientDetailsScreen(
        repository: clinicalRepository,
        patient: settings.arguments is PatientSummary
            ? settings.arguments! as PatientSummary
            : null,
      ),
      therapistPlan => PlanManagementScreen(
        repository: clinicalRepository,
        patient: settings.arguments is PatientSummary
            ? settings.arguments! as PatientSummary
            : null,
      ),
      sessions || therapistProgress => TherapistSessionsScreen(
        repository: clinicalRepository,
        patient: settings.arguments is PatientSummary
            ? settings.arguments! as PatientSummary
            : null,
      ),
      reports => ReportsScreen(
        repository: clinicalRepository,
        patient: settings.arguments is PatientSummary
            ? settings.arguments! as PatientSummary
            : null,
      ),
      notes => NotesScreen(
        repository: clinicalRepository,
        patient: settings.arguments is PatientSummary
            ? settings.arguments! as PatientSummary
            : null,
      ),
      patientMessages => MessagesScreen(repository: clinicalRepository),
      therapistMessages => MessagesScreen(
        repository: clinicalRepository,
        patient: settings.arguments is PatientSummary
            ? settings.arguments! as PatientSummary
            : null,
      ),
      analysisMethod => const AnalysisMethodScreen(),
      _ => const PlaceholderScreen(
        title: 'Página não encontrada',
        description: 'Não foi possível localizar esta página.',
        icon: Icons.error_outline,
      ),
    };

    return MaterialPageRoute<void>(builder: (_) => screen, settings: settings);
  }
}
