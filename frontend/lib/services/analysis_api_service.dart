import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';

import '../models/clinical_data.dart';

typedef AccessTokenProvider = Future<String?> Function();

class AnalysisApiResponse {
  const AnalysisApiResponse({
    required this.analysisId,
    required this.status,
    required this.simulated,
    required this.message,
    this.exerciseType = 'elbow_flexion',
    this.metrics,
    this.technicalIssueCode,
  });

  final String analysisId;
  final String status;
  final bool simulated;
  final String message;
  final String exerciseType;
  final AnalysisApiMetrics? metrics;
  final String? technicalIssueCode;

  bool get isFinished => status != 'processing';

  factory AnalysisApiResponse.fromPayload(Map<String, dynamic> payload) {
    final data = payload['data'] as Map<String, dynamic>;
    final rawMetrics = data['metrics'];
    return AnalysisApiResponse(
      analysisId: data['analysis_id'].toString(),
      status: data['status'].toString(),
      simulated: data['simulated'] == true,
      message: data['message']?.toString() ?? payload['message'].toString(),
      exerciseType: data['exercise_type']?.toString() ?? 'elbow_flexion',
      metrics: rawMetrics is Map<String, dynamic>
          ? AnalysisApiMetrics.fromJson(rawMetrics)
          : null,
      technicalIssueCode: data['technical_issue_code']?.toString(),
    );
  }
}

class AnalysisApiMetrics {
  const AnalysisApiMetrics({
    required this.repetitions,
    required this.source,
    this.confidence,
    this.averageAmplitudeDegrees,
    this.averageDurationSeconds,
    this.averageVelocityDegreesPerSecond,
    this.averageSymmetryDifferenceDegrees,
    this.averageDistance,
    this.parametersVersion,
    this.analyzedSide,
    this.possibleCompensations = const [],
    this.warnings = const [],
    this.movementEvents = const [],
    this.repetitionDetails = const [],
    this.affectedSide,
    this.unaffectedSide,
    this.averageAffectedAngleDegrees,
    this.averageUnaffectedAngleDegrees,
    this.validFrames,
    this.totalFrames,
    this.detectionRatio,
    this.evidence = const [],
  });

  final int repetitions;
  final String source;
  final double? confidence;
  final double? averageAmplitudeDegrees;
  final double? averageDurationSeconds;
  final double? averageVelocityDegreesPerSecond;
  final double? averageSymmetryDifferenceDegrees;
  final double? averageDistance;
  final String? parametersVersion;
  final String? analyzedSide;
  final List<String> possibleCompensations;
  final List<String> warnings;
  final List<MovementEvent> movementEvents;
  final List<RepetitionDetail> repetitionDetails;
  final String? affectedSide;
  final String? unaffectedSide;
  final double? averageAffectedAngleDegrees;
  final double? averageUnaffectedAngleDegrees;
  final int? validFrames;
  final int? totalFrames;
  final double? detectionRatio;
  final List<AnalysisEvidence> evidence;

  factory AnalysisApiMetrics.fromJson(Map<String, dynamic> json) {
    return AnalysisApiMetrics(
      repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
      source: json['source']?.toString() ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble(),
      averageAmplitudeDegrees: (json['average_amplitude_degrees'] as num?)
          ?.toDouble(),
      averageDurationSeconds: (json['average_duration_seconds'] as num?)
          ?.toDouble(),
      averageVelocityDegreesPerSecond:
          (json['average_velocity_degrees_per_second'] as num?)?.toDouble(),
      averageSymmetryDifferenceDegrees:
          (json['average_symmetry_difference_degrees'] as num?)?.toDouble(),
      averageDistance: (json['average_distance'] as num?)?.toDouble(),
      parametersVersion: json['parameters_version']?.toString(),
      analyzedSide: json['analyzed_side']?.toString(),
      possibleCompensations:
          (json['possible_compensations'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      warnings: (json['warnings'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      movementEvents: (json['movement_events'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MovementEvent.fromJson)
          .toList(),
      repetitionDetails:
          (json['repetition_details'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(RepetitionDetail.fromJson)
              .toList(),
      affectedSide: json['affected_side']?.toString(),
      unaffectedSide: json['unaffected_side']?.toString(),
      averageAffectedAngleDegrees:
          (json['average_affected_angle_degrees'] as num?)?.toDouble(),
      averageUnaffectedAngleDegrees:
          (json['average_unaffected_angle_degrees'] as num?)?.toDouble(),
      validFrames: (json['valid_frames'] as num?)?.toInt(),
      totalFrames: (json['total_frames'] as num?)?.toInt(),
      detectionRatio: (json['detection_ratio'] as num?)?.toDouble(),
      evidence: (json['evidence'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((item) {
            final encoded = item['image_base64']?.toString() ?? '';
            return AnalysisEvidence(
              eventIndex: (item['event_index'] as num?)?.toInt() ?? 0,
              eventType: item['event_type']?.toString() ?? 'information',
              title: item['title']?.toString() ?? 'Momento da análise',
              timestampSeconds:
                  (item['timestamp_seconds'] as num?)?.toDouble() ?? 0,
              bytes: base64Decode(encoded),
              contentType: item['content_type']?.toString() ?? 'image/jpeg',
            );
          })
          .where((item) => item.bytes.isNotEmpty)
          .toList(),
    );
  }
}

class AnalysisApiException implements Exception {
  const AnalysisApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AnalysisApiService {
  AnalysisApiService({
    http.Client? client,
    String? baseUrl,
    AccessTokenProvider? accessTokenProvider,
  }) : _client = client ?? http.Client(),
       _accessTokenProvider = accessTokenProvider,
       baseUrl = baseUrl ?? defaultBaseUrl;

  final http.Client _client;
  final AccessTokenProvider? _accessTokenProvider;
  final String baseUrl;

  static String get defaultBaseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  Future<bool> checkHealth() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/health'))
        .timeout(const Duration(seconds: 5));
    return response.statusCode == 200;
  }

  Future<AnalysisApiResponse> submitSimulatedVideo() {
    return submitVideo(
      bytes: Uint8List.fromList(utf8.encode('simulated-video-content')),
      filename: 'simulated.mp4',
      mimeType: 'video/mp4',
    );
  }

  Future<AnalysisApiResponse> submitSimulatedAndWait() {
    return submitAndWait(
      bytes: Uint8List.fromList(utf8.encode('simulated-video-content')),
      filename: 'simulated.mp4',
      mimeType: 'video/mp4',
    );
  }

  Future<AnalysisApiResponse> submitVideo({
    required Uint8List bytes,
    required String filename,
    String mimeType = 'video/mp4',
    String exerciseType = 'elbow_flexion',
    String? affectedSide,
    double? detectionStartThreshold,
    double? detectionChangeThreshold,
  }) async {
    final mediaParts = mimeType.split('/');
    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/analysis'))
          ..fields['exercise_type'] = exerciseType
          ..fields['session_id'] = const Uuid().v4()
          ..files.add(
            http.MultipartFile.fromBytes(
              'video_file',
              bytes,
              filename: filename,
              contentType: MediaType(
                mediaParts.first,
                mediaParts.length > 1 ? mediaParts[1] : 'mp4',
              ),
            ),
          );
    if (affectedSide == 'left' || affectedSide == 'right') {
      request.fields['affected_side'] = affectedSide!;
    }
    if (detectionStartThreshold != null && detectionChangeThreshold != null) {
      request.fields['detection_start_threshold'] = '$detectionStartThreshold';
      request.fields['detection_change_threshold'] =
          '$detectionChangeThreshold';
    }
    final headers = await _authorizationHeaders();
    request.headers.addAll(headers);

    final streamedResponse = await _client
        .send(request)
        .timeout(const Duration(seconds: 10));
    final response = await http.Response.fromStream(streamedResponse);
    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 202) {
      throw AnalysisApiException(
        payload['detail']?.toString() ?? 'A API não aceitou a solicitação.',
      );
    }

    return AnalysisApiResponse.fromPayload(payload);
  }

  Future<AnalysisApiResponse> getResult(String analysisId) async {
    final headers = await _authorizationHeaders();
    final response = await _client
        .get(Uri.parse('$baseUrl/analysis/$analysisId'), headers: headers)
        .timeout(const Duration(seconds: 10));
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw AnalysisApiException(
        payload['detail']?.toString() ??
            'Não foi possível consultar a análise.',
      );
    }
    return AnalysisApiResponse.fromPayload(payload);
  }

  Future<AnalysisApiResponse> submitAndWait({
    required Uint8List bytes,
    required String filename,
    String mimeType = 'video/mp4',
    String exerciseType = 'elbow_flexion',
    String? affectedSide,
    double? detectionStartThreshold,
    double? detectionChangeThreshold,
    Duration timeout = const Duration(minutes: 2),
    Duration pollInterval = const Duration(milliseconds: 600),
  }) async {
    var result = await submitVideo(
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
      exerciseType: exerciseType,
      affectedSide: affectedSide,
      detectionStartThreshold: detectionStartThreshold,
      detectionChangeThreshold: detectionChangeThreshold,
    );
    final deadline = DateTime.now().add(timeout);
    while (!result.isFinished && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(pollInterval);
      result = await getResult(result.analysisId);
    }
    if (!result.isFinished) {
      throw const AnalysisApiException(
        'A análise excedeu o tempo de espera. Tente novamente.',
      );
    }
    return result;
  }

  void close() => _client.close();

  Future<Map<String, String>> _authorizationHeaders() async {
    final token = await _accessTokenProvider?.call();
    if (token == null || token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }
}
