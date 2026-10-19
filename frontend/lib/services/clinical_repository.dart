import '../models/clinical_data.dart';
import '../models/patient_summary.dart';

class ClinicalRepositoryException implements Exception {
  const ClinicalRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class ClinicalRepository {
  bool get isDemo;

  Stream<List<TherapyPlan>> watchMyPlan();
  Stream<List<TherapyPlan>> watchPatientPlans(String patientId);
  Stream<List<RehabilitationSession>> watchMySessions();
  Stream<List<CareLink>> watchPendingLinks();
  Stream<List<PatientSummary>> watchLinkedPatients();
  Stream<List<RehabilitationSession>> watchPatientSessions(String patientId);
  Stream<List<ProfessionalNote>> watchNotes(String patientId);
  Stream<List<ProfessionalNote>> watchMyOrientations();
  Stream<List<CareMessage>> watchMessages({String? patientId});
  Stream<List<CareMessage>> watchAllMessages();
  Stream<DashboardSummary> watchDashboard();

  Future<void> requestPatientLink(String patientId);
  Future<void> respondToLink(String linkId, {required bool accept});
  Future<void> savePlan(TherapyPlan plan);
  Future<void> addNote({
    required String patientId,
    required String text,
    required bool visibleToPatient,
  });
  Future<void> sendMessage({
    String? patientId,
    required String text,
    String category = 'general',
    String? sessionId,
  });
  Future<void> markConversationRead({String? patientId});
  Future<void> saveSession(RehabilitationSession session);
  Future<void> uploadSessionVideo({
    required String sessionId,
    required List<int> bytes,
    required String contentType,
    required DateTime consentAt,
  });
  Future<String> downloadSessionVideo(RehabilitationSession session);
  Future<void> deleteSessionVideo(RehabilitationSession session);
  Future<void> deleteSessionEvidence(RehabilitationSession session);
  Future<void> markSessionReviewed(String sessionId);

  Future<void> reviewSession({
    required String sessionId,
    required int rating,
    required String conduct,
    Map<String, String> eventReviews = const {},
    String? comment,
    bool visibleToPatient = false,
  });

  Future<void> saveWellbeing({
    required String sessionId,
    required int score,
    required int painScore,
    required int fatigueScore,
    String? note,
  });
}

class DemoClinicalRepository implements ClinicalRepository {
  const DemoClinicalRepository();

  @override
  bool get isDemo => true;

  static final sessions = [
    RehabilitationSession(
      id: 'demo-1',
      patientId: 'demo-patient',
      exerciseType: 'elbow_flexion',
      status: 'completed',
      createdAt: DateTime(2026, 10, 5, 9, 30),
      repetitions: 8,
      averageAmplitudeDegrees: 92,
      confidence: .86,
      prescribedSessionsPerWeek: 3,
      painScore: 2,
      fatigueScore: 4,
    ),
    RehabilitationSession(
      id: 'demo-2',
      patientId: 'demo-patient',
      exerciseType: 'elbow_flexion',
      status: 'inconclusive',
      createdAt: DateTime(2026, 10, 3, 16, 10),
      requiresReview: true,
      message: 'Enquadramento insuficiente para uma análise confiável.',
    ),
  ];

  @override
  Stream<List<TherapyPlan>> watchMyPlan() => Stream.value(const [
    TherapyPlan(
      patientId: 'demo-patient',
      exerciseType: 'elbow_flexion',
      title: 'Flexão de cotovelo',
      instructions: 'Execute devagar, mantendo o braço visível.',
      sessionsPerWeek: 3,
      targetRepetitions: 8,
    ),
  ]);

  @override
  Stream<List<TherapyPlan>> watchPatientPlans(String patientId) =>
      watchMyPlan();

  @override
  Stream<List<RehabilitationSession>> watchMySessions() =>
      Stream.value(sessions);

  @override
  Stream<List<CareLink>> watchPendingLinks() => Stream.value(const []);

  @override
  Stream<List<PatientSummary>> watchLinkedPatients() =>
      Stream.value(MockPatients.all);

  @override
  Stream<List<RehabilitationSession>> watchPatientSessions(String patientId) =>
      Stream.value(sessions);

  @override
  Stream<List<ProfessionalNote>> watchNotes(String patientId) => Stream.value([
    ProfessionalNote(
      id: 'demo-note',
      patientId: patientId,
      therapistId: 'demo-therapist',
      text: 'Mantenha o movimento confortável e siga as orientações recebidas.',
      createdAt: DateTime(2026, 10, 5),
    ),
  ]);

  @override
  Stream<List<ProfessionalNote>> watchMyOrientations() =>
      watchNotes('demo-patient');

  @override
  Stream<List<CareMessage>> watchMessages({String? patientId}) => Stream.value([
    CareMessage(
      id: 'demo-message-1',
      patientId: patientId ?? 'demo-patient',
      therapistId: 'demo-therapist',
      senderId: 'demo-patient',
      senderRole: 'patient',
      text: 'Tenho dúvida sobre a posição do braço durante o exercício.',
      category: 'movement_question',
      createdAt: DateTime(2026, 10, 5, 9, 40),
      readAt: DateTime(2026, 10, 5, 10),
    ),
    CareMessage(
      id: 'demo-message-2',
      patientId: patientId ?? 'demo-patient',
      therapistId: 'demo-therapist',
      senderId: 'demo-therapist',
      senderRole: 'therapist',
      text: 'Mantenha o cotovelo próximo ao corpo e faça sem sentir dor.',
      createdAt: DateTime(2026, 10, 5, 10, 5),
    ),
  ]);

  @override
  Stream<List<CareMessage>> watchAllMessages() => Stream.value([
    CareMessage(
      id: 'demo-inbox-1',
      patientId: 'demo-patient-joao',
      therapistId: 'demo-therapist',
      senderId: 'demo-patient-joao',
      senderRole: 'patient',
      text: 'Tive dificuldade para completar o movimento hoje.',
      category: 'could_not_complete',
      createdAt: DateTime(2026, 10, 18, 15, 20),
    ),
    CareMessage(
      id: 'demo-inbox-2',
      patientId: 'demo-patient',
      therapistId: 'demo-therapist',
      senderId: 'demo-patient',
      senderRole: 'patient',
      text: 'Posso realizar os movimentos mais devagar?',
      category: 'movement_question',
      createdAt: DateTime(2026, 10, 18, 14, 10),
    ),
  ]);

  @override
  Stream<DashboardSummary> watchDashboard() => Stream.value(
    const DashboardSummary(
      patients: 3,
      sessions: 7,
      requiresReview: 1,
      adherence: 79,
      attentionPatients: 2,
      inactivePatients: 1,
    ),
  );

  @override
  Future<void> requestPatientLink(String patientId) async {}

  @override
  Future<void> respondToLink(String linkId, {required bool accept}) async {}

  @override
  Future<void> savePlan(TherapyPlan plan) async {}

  @override
  Future<void> addNote({
    required String patientId,
    required String text,
    required bool visibleToPatient,
  }) async {}

  @override
  Future<void> sendMessage({
    String? patientId,
    required String text,
    String category = 'general',
    String? sessionId,
  }) async {}

  @override
  Future<void> markConversationRead({String? patientId}) async {}

  @override
  Future<void> saveSession(RehabilitationSession session) async {}

  @override
  Future<void> uploadSessionVideo({
    required String sessionId,
    required List<int> bytes,
    required String contentType,
    required DateTime consentAt,
  }) async {}

  @override
  Future<String> downloadSessionVideo(RehabilitationSession session) async =>
      throw const ClinicalRepositoryException(
        'Vídeos não estão disponíveis no modo demonstração.',
      );

  @override
  Future<void> deleteSessionVideo(RehabilitationSession session) async {}

  @override
  Future<void> deleteSessionEvidence(RehabilitationSession session) async {}

  @override
  Future<void> markSessionReviewed(String sessionId) async {}

  @override
  Future<void> reviewSession({
    required String sessionId,
    required int rating,
    required String conduct,
    Map<String, String> eventReviews = const {},
    String? comment,
    bool visibleToPatient = false,
  }) async {}

  @override
  Future<void> saveWellbeing({
    required String sessionId,
    required int score,
    required int painScore,
    required int fatigueScore,
    String? note,
  }) async {}
}
