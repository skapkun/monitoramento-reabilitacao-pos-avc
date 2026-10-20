import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/clinical_data.dart';
import 'analysis_api_service.dart';

class ReportApiService {
  ReportApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? AnalysisApiService.defaultBaseUrl;

  final http.Client _client;
  final String baseUrl;

  Future<Uint8List> generate({
    required String patientId,
    required String patientName,
    required List<RehabilitationSession> sessions,
  }) => _requestPdf(
    path: '/reports/longitudinal.pdf',
    errorMessage:
        'Não foi possível gerar o relatório. Confirme se a API está em execução.',
    body: {
      'patient_id': patientId,
      'patient_name': patientName,
      'sessions': sessions.map(_sessionJson).toList(),
    },
  );

  Future<Uint8List> generateSession({
    required String patientId,
    required String patientName,
    required RehabilitationSession session,
  }) => _requestPdf(
    path: '/reports/session.pdf',
    errorMessage:
        'Não foi possível gerar o PDF desta sessão. Confirme se a API está em execução.',
    body: {
      'patient_id': patientId,
      'patient_name': patientName,
      'session': _sessionJson(session),
    },
  );

  Future<Uint8List> _requestPdf({
    required String path,
    required String errorMessage,
    required Map<String, Object?> body,
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final response = await _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 || response.bodyBytes.length < 4) {
      throw ReportApiException(errorMessage);
    }
    return Uint8List.fromList(response.bodyBytes);
  }

  Future<String> generateAndShare({
    required String patientId,
    required String patientName,
    required List<RehabilitationSession> sessions,
  }) async {
    final bytes = await generate(
      patientId: patientId,
      patientName: patientName,
      sessions: sessions,
    );
    final directory = await getTemporaryDirectory();
    final safeId = patientId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${directory.path}/movere-relatorio-$safeId.pdf');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        title: 'Relatório longitudinal Movere',
        text: 'Relatório técnico descritivo do Movere.',
        files: [XFile(file.path, mimeType: 'application/pdf')],
      ),
    );
    return file.path;
  }

  Future<String> generateSessionAndShare({
    required String patientId,
    required String patientName,
    required RehabilitationSession session,
  }) async {
    final bytes = await generateSession(
      patientId: patientId,
      patientName: patientName,
      session: session,
    );
    final directory = await getTemporaryDirectory();
    final safeId = session.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${directory.path}/movere-sessao-$safeId.pdf');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        title: 'Relatório individual da sessão',
        text: 'Registro técnico descritivo de uma sessão do Movere.',
        files: [XFile(file.path, mimeType: 'application/pdf')],
      ),
    );
    return file.path;
  }

  void close() => _client.close();

  static String _exerciseName(String type) => switch (type) {
    'squat' => 'Agachamento',
    'pinch' => 'Pinça',
    _ => 'Flexão de cotovelo',
  };

  static Map<String, Object?> _sessionJson(RehabilitationSession session) => {
    'date': session.createdAt.toUtc().toIso8601String(),
    'exercise': _exerciseName(session.exerciseType),
    'status': session.status,
    'repetitions': session.repetitions,
    'average_amplitude_degrees': session.averageAmplitudeDegrees,
    'requires_review': session.requiresReview,
    'average_duration_seconds': session.averageDurationSeconds,
    'average_velocity_degrees_per_second':
        session.averageVelocityDegreesPerSecond,
    'average_symmetry_difference_degrees':
        session.averageSymmetryDifferenceDegrees,
    'average_distance': session.averageDistance,
    'wellbeing_score': session.wellbeingScore,
    'pain_score': session.painScore,
    'fatigue_score': session.fatigueScore,
    'professional_rating': session.professionalRating,
    'professional_conduct': session.professionalConduct,
    'prescription_version': session.prescriptionVersion,
    'prescribed_sets': session.prescribedSets,
    'prescribed_repetitions': session.prescribedRepetitions,
    'prescribed_sessions_per_week': session.prescribedSessionsPerWeek,
    'prescribed_amplitude_degrees': session.prescribedAmplitudeDegrees,
    'prescribed_training_side': session.prescribedTrainingSide,
    'prescribed_cadence_seconds': session.prescribedCadenceSeconds,
    'prescribed_rest_seconds': session.prescribedRestSeconds,
    'custom_detection_applied': session.customDetectionApplied,
    'detection_start_threshold': session.detectionStartThreshold,
    'detection_change_threshold': session.detectionChangeThreshold,
    'calibration_reason': session.calibrationReason,
    'movement_events': session.movementEvents
        .map((event) => event.toJson())
        .toList(),
    'affected_side': session.affectedSide,
    'unaffected_side': session.unaffectedSide,
    'average_affected_angle_degrees': session.averageAffectedAngleDegrees,
    'average_unaffected_angle_degrees': session.averageUnaffectedAngleDegrees,
    'event_reviews': session.eventReviews,
    'review_comment': session.reviewComment,
    'review_visible_to_patient': session.reviewVisibleToPatient,
    'evidence': session.evidence
        .map(
          (item) => {
            'event_index': item.eventIndex,
            'event_type': item.eventType,
            'title': item.title,
            'timestamp_seconds': item.timestampSeconds,
            'content_type': item.contentType,
            'image_base64': base64Encode(item.bytes),
          },
        )
        .toList(),
  };
}

class ReportApiException implements Exception {
  const ReportApiException(this.message);
  final String message;
}
