enum PatientAlertType {
  noSessions,
  inactive,
  lowAdherence,
  recurringDifficulty,
  belowPrescription,
  highDiscomfort,
  decliningTrend,
}

class PatientAlert {
  const PatientAlert({
    required this.type,
    required this.title,
    required this.message,
  });

  final PatientAlertType type;
  final String title;
  final String message;
}

class PatientSummary {
  const PatientSummary({
    this.id = 'demo-patient',
    required this.name,
    required this.initials,
    required this.lastSession,
    required this.sessions,
    required this.adherence,
    required this.status,
    required this.requiresReview,
    this.alerts = const [],
    this.affectedSide,
    this.strokeType,
    this.mobility,
    this.ageRange,
    this.monthsSinceStroke,
    this.dominantSide,
    this.assistiveDevice,
    this.participantContext = 'not_informed',
  });

  final String id;
  final String name;
  final String initials;
  final String lastSession;
  final int sessions;
  final int adherence;
  final String status;
  final bool requiresReview;
  final List<PatientAlert> alerts;
  final String? affectedSide;
  final String? strokeType;
  final String? mobility;
  final String? ageRange;
  final int? monthsSinceStroke;
  final String? dominantSide;
  final String? assistiveDevice;
  final String participantContext;

  bool get needsAttention => alerts.isNotEmpty || requiresReview;

  bool get isInactive => alerts.any(
    (alert) =>
        alert.type == PatientAlertType.inactive ||
        alert.type == PatientAlertType.noSessions,
  );
}

abstract final class MockPatients {
  static const all = [
    PatientSummary(
      name: 'Maria Oliveira',
      initials: 'MO',
      lastSession: 'Hoje, 09:30',
      sessions: 12,
      adherence: 86,
      status: 'Evolução registrada',
      requiresReview: false,
      affectedSide: 'right',
      strokeType: 'ischemic',
      mobility: 'with_support',
      ageRange: '60_69',
      monthsSinceStroke: 18,
      dominantSide: 'right',
      assistiveDevice: 'cane',
      participantContext: 'post_stroke',
    ),
    PatientSummary(
      id: 'demo-patient-joao',
      name: 'João Pereira',
      initials: 'JP',
      lastSession: 'Ontem, 16:10',
      sessions: 8,
      adherence: 72,
      status: 'Sessão requer revisão',
      requiresReview: true,
      alerts: [
        PatientAlert(
          type: PatientAlertType.recurringDifficulty,
          title: 'Dificuldade repetida na análise',
          message: 'Há sessões recentes que precisam de revisão profissional.',
        ),
      ],
    ),
    PatientSummary(
      id: 'demo-patient-lucia',
      name: 'Lúcia Santos',
      initials: 'LS',
      lastSession: 'Sem sessões registradas',
      sessions: 0,
      adherence: 0,
      status: 'Plano ainda não iniciado',
      requiresReview: false,
      alerts: [
        PatientAlert(
          type: PatientAlertType.noSessions,
          title: 'Plano ainda não iniciado',
          message: 'Há um plano ativo, mas nenhuma sessão foi registrada.',
        ),
      ],
    ),
  ];
}
