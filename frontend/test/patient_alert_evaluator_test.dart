import 'package:flutter_test/flutter_test.dart';
import 'package:movere_app/models/clinical_data.dart';
import 'package:movere_app/models/patient_summary.dart';
import 'package:movere_app/services/patient_alert_evaluator.dart';

void main() {
  const plan = TherapyPlan(
    patientId: 'patient',
    exerciseType: 'elbow_flexion',
    title: 'Flexão de cotovelo',
    instructions: '',
    sessionsPerWeek: 3,
    targetRepetitions: 10,
  );
  final now = DateTime(2026, 10, 12, 12);

  test('indica plano ativo ainda sem sessões', () {
    final alerts = PatientAlertEvaluator.evaluate(
      sessions: const [],
      activePlans: const [plan],
      sessionsLastSevenDays: 0,
      expectedSessionsPerWeek: 3,
      now: now,
    );

    expect(alerts.single.type, PatientAlertType.noSessions);
  });

  test('identifica inatividade, baixa frequência e dificuldade repetida', () {
    final sessions = [
      _session('one', now.subtract(const Duration(days: 15))),
      _session('two', now.subtract(const Duration(days: 16))),
    ];
    final alerts = PatientAlertEvaluator.evaluate(
      sessions: sessions,
      activePlans: const [plan],
      sessionsLastSevenDays: 0,
      expectedSessionsPerWeek: 3,
      now: now,
    );

    expect(_types(alerts), contains(PatientAlertType.inactive));
    expect(_types(alerts), contains(PatientAlertType.lowAdherence));
    expect(_types(alerts), contains(PatientAlertType.recurringDifficulty));
  });

  test('identifica desconforto e resultado abaixo da prescrição', () {
    final sessions = [
      _session(
        'one',
        now,
        status: 'completed',
        repetitions: 4,
        pain: 7,
        prescribedRepetitions: 10,
      ),
      _session(
        'two',
        now.subtract(const Duration(days: 2)),
        status: 'completed',
        repetitions: 5,
        prescribedRepetitions: 10,
      ),
    ];
    final alerts = PatientAlertEvaluator.evaluate(
      sessions: sessions,
      activePlans: const [plan],
      sessionsLastSevenDays: 2,
      expectedSessionsPerWeek: 3,
      now: now,
    );

    expect(_types(alerts), contains(PatientAlertType.highDiscomfort));
    expect(_types(alerts), contains(PatientAlertType.belowPrescription));
  });

  test('não cria alerta quando registros não atendem aos limites', () {
    final sessions = [
      _session(
        'one',
        now,
        status: 'completed',
        repetitions: 10,
        prescribedRepetitions: 10,
      ),
      _session(
        'two',
        now.subtract(const Duration(days: 2)),
        status: 'completed',
        repetitions: 10,
        prescribedRepetitions: 10,
      ),
    ];
    final alerts = PatientAlertEvaluator.evaluate(
      sessions: sessions,
      activePlans: const [plan],
      sessionsLastSevenDays: 2,
      expectedSessionsPerWeek: 3,
      now: now,
    );

    expect(alerts, isEmpty);
  });
}

RehabilitationSession _session(
  String id,
  DateTime createdAt, {
  String status = 'inconclusive',
  int repetitions = 0,
  int? pain,
  int? prescribedRepetitions,
}) => RehabilitationSession(
  id: id,
  patientId: 'patient',
  exerciseType: 'elbow_flexion',
  status: status,
  createdAt: createdAt,
  repetitions: repetitions,
  painScore: pain,
  prescribedSets: 1,
  prescribedRepetitions: prescribedRepetitions,
);

Set<PatientAlertType> _types(List<PatientAlert> alerts) =>
    alerts.map((alert) => alert.type).toSet();
