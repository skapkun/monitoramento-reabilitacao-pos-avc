import '../models/clinical_data.dart';
import '../models/patient_summary.dart';
import '../utils/portuguese_text.dart';

abstract final class PatientAlertEvaluator {
  static List<PatientAlert> evaluate({
    required List<RehabilitationSession> sessions,
    required List<TherapyPlan> activePlans,
    required int sessionsLastSevenDays,
    required int expectedSessionsPerWeek,
    required DateTime now,
  }) {
    if (activePlans.isEmpty) return const [];
    final alerts = <PatientAlert>[];
    final ordered = [...sessions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (ordered.isEmpty) {
      alerts.add(
        const PatientAlert(
          type: PatientAlertType.noSessions,
          title: 'Plano ainda não iniciado',
          message: 'Há um plano ativo, mas nenhuma sessão foi registrada.',
        ),
      );
      return alerts;
    }

    if (now.difference(ordered.first.createdAt).inDays >= 14) {
      alerts.add(
        const PatientAlert(
          type: PatientAlertType.inactive,
          title: 'Sem atividade recente',
          message: 'Nenhuma sessão foi registrada nos últimos 14 dias.',
        ),
      );
    }

    if (expectedSessionsPerWeek > 0 &&
        sessionsLastSevenDays * 2 < expectedSessionsPerWeek) {
      alerts.add(
        PatientAlert(
          type: PatientAlertType.lowAdherence,
          title: 'Poucas sessões nesta semana',
          message:
              '${quantity(sessionsLastSevenDays, 'sessão', 'sessões')} de ${quantity(expectedSessionsPerWeek, 'sessão prevista', 'sessões previstas')} ${agreement(sessionsLastSevenDays, 'foi registrada', 'foram registradas')} nos últimos 7 dias.',
        ),
      );
    }

    final latest = ordered.take(3).toList();
    final incomplete = latest
        .where(
          (session) =>
              session.status == 'inconclusive' ||
              session.status == 'failed' ||
              session.requiresReview,
        )
        .length;
    if (latest.length >= 2 && incomplete >= 2) {
      alerts.add(
        PatientAlert(
          type: PatientAlertType.recurringDifficulty,
          title: 'Dificuldades repetidas na análise',
          message:
              '$incomplete das ${latest.length} sessões mais recentes precisam de revisão.',
        ),
      );
    }

    final belowTarget = latest.where(_isBelowPrescription).length;
    if (latest.length >= 2 && belowTarget >= 2) {
      alerts.add(
        const PatientAlert(
          type: PatientAlertType.belowPrescription,
          title: 'Resultados abaixo da prescrição',
          message:
              'Em pelo menos duas sessões recentes, repetições ou movimento ficaram abaixo da meta registrada.',
        ),
      );
    }

    final highDiscomfort = latest.any(
      (session) =>
          (session.painScore ?? 0) >= 7 || (session.fatigueScore ?? 0) >= 8,
    );
    if (highDiscomfort) {
      alerts.add(
        const PatientAlert(
          type: PatientAlertType.highDiscomfort,
          title: 'Relato alto de dor ou cansaço',
          message:
              'Uma sessão recente tem dor a partir de 7/10 ou cansaço a partir de 8/10. Confira o relato do paciente.',
        ),
      );
    }

    if (_hasDecliningTrend(ordered)) {
      alerts.add(
        const PatientAlert(
          type: PatientAlertType.decliningTrend,
          title: 'Tendência de queda para revisar',
          message:
              'As repetições recentes diminuíram em relação às anteriores. Isso não indica piora clínica e precisa de avaliação profissional.',
        ),
      );
    }
    return alerts;
  }

  static bool _isBelowPrescription(RehabilitationSession session) {
    if (session.status != 'completed') return false;
    final repetitions = session.prescribedRepetitions;
    final sets = session.prescribedSets;
    final belowRepetitions =
        repetitions != null &&
        repetitions > 0 &&
        session.repetitions < repetitions * (sets ?? 1);
    final amplitude = session.prescribedAmplitudeDegrees;
    final observed = session.averageAmplitudeDegrees;
    final belowAmplitude =
        amplitude != null && observed != null && observed < amplitude * 0.9;
    return belowRepetitions || belowAmplitude;
  }

  static bool _hasDecliningTrend(List<RehabilitationSession> ordered) {
    final byExercise = <String, List<RehabilitationSession>>{};
    for (final session in ordered.where((item) => item.status == 'completed')) {
      byExercise.putIfAbsent(session.exerciseType, () => []).add(session);
    }
    for (final sessions in byExercise.values) {
      if (sessions.length < 4) continue;
      final recent = sessions.take(2).toList();
      final previous = sessions.skip(2).take(2).toList();
      final recentAverage =
          recent.fold<int>(0, (sum, item) => sum + item.repetitions) / 2;
      final previousAverage =
          previous.fold<int>(0, (sum, item) => sum + item.repetitions) / 2;
      if (previousAverage > 0 && recentAverage < previousAverage * 0.85) {
        return true;
      }
    }
    return false;
  }
}
