import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/clinical_data.dart';

class ResearchExportService {
  Future<String> generateAndShare({
    required String patientId,
    required List<RehabilitationSession> sessions,
  }) async {
    final content = buildCsv(patientId: patientId, sessions: sessions);
    final participant = participantCode(patientId);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/movere-pesquisa-$participant.csv');
    await file.writeAsString('\uFEFF$content', flush: true);
    await SharePlus.instance.share(
      ShareParams(
        title: 'Exportação de pesquisa Movere',
        text:
            'Dados pseudonimizados. Verifique o protocolo ético antes de compartilhar.',
        files: [XFile(file.path, mimeType: 'text/csv')],
      ),
    );
    return file.path;
  }

  String buildCsv({
    required String patientId,
    required List<RehabilitationSession> sessions,
  }) {
    final ordered = [...sessions]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final firstDate = ordered.isEmpty ? null : _day(ordered.first.createdAt);
    final participant = participantCode(patientId);
    final rows = <List<Object?>>[
      [
        'participant_code',
        'session_order',
        'days_since_first_session',
        'exercise',
        'status',
        'repetitions',
        'average_amplitude_degrees',
        'average_duration_seconds',
        'average_velocity_degrees_per_second',
        'average_symmetry_difference_degrees',
        'confidence',
        'detection_ratio',
        'valid_frames',
        'total_frames',
        'parameters_version',
        'requires_review',
        'confirmed_events',
        'not_confirmed_events',
        'insufficient_video_events',
        'wellbeing_score',
        'pain_score',
        'fatigue_score',
      ],
    ];
    for (var index = 0; index < ordered.length; index++) {
      final session = ordered[index];
      final date = _day(session.createdAt);
      rows.add([
        participant,
        index + 1,
        firstDate == null ? 0 : date.difference(firstDate).inDays,
        session.exerciseType,
        session.status,
        session.repetitions,
        session.averageAmplitudeDegrees,
        session.averageDurationSeconds,
        session.averageVelocityDegreesPerSecond,
        session.averageSymmetryDifferenceDegrees,
        session.confidence,
        session.detectionRatio,
        session.validFrames,
        session.totalFrames,
        session.analysisParametersVersion,
        session.requiresReview,
        _count(session, 'confirmed'),
        _count(session, 'not_confirmed'),
        _count(session, 'insufficient_video'),
        session.wellbeingScore,
        session.painScore,
        session.fatigueScore,
      ]);
    }
    return rows.map(_row).join('\n');
  }

  String participantCode(String patientId) {
    final code = sha256.convert(utf8.encode('movere-research:$patientId'));
    return code.toString().substring(0, 12);
  }

  static int _count(RehabilitationSession session, String value) =>
      session.eventReviews.values.where((review) => review == value).length;

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _row(List<Object?> values) => values.map(_cell).join(',');

  static String _cell(Object? value) {
    if (value == null) return '';
    final text = value.toString();
    if (!text.contains(RegExp('[,"\\n\\r]'))) return text;
    return '"${text.replaceAll('"', '""')}"';
  }
}
