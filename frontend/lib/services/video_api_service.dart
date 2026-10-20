import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

import 'analysis_api_service.dart';

class VideoUploadResult {
  const VideoUploadResult({
    required this.storagePath,
    required this.sharedAt,
    required this.consentAt,
    required this.retentionUntil,
    required this.consentVersion,
  });

  final String storagePath;
  final DateTime sharedAt;
  final DateTime consentAt;
  final DateTime retentionUntil;
  final String consentVersion;

  factory VideoUploadResult.fromJson(Map<String, dynamic> json) =>
      VideoUploadResult(
        storagePath: json['storage_path'].toString(),
        sharedAt: DateTime.parse(json['shared_at'].toString()),
        consentAt: DateTime.parse(json['consent_at'].toString()),
        retentionUntil: DateTime.parse(json['retention_until'].toString()),
        consentVersion: json['consent_version'].toString(),
      );
}

class VideoApiException implements Exception {
  const VideoApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VideoApiService {
  VideoApiService({
    http.Client? client,
    String? baseUrl,
    AccessTokenProvider? accessTokenProvider,
  }) : _client = client ?? http.Client(),
       _accessTokenProvider = accessTokenProvider,
       baseUrl = baseUrl ?? _defaultBaseUrl;

  final http.Client _client;
  final AccessTokenProvider? _accessTokenProvider;
  final String baseUrl;

  static String get _defaultBaseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  Future<VideoUploadResult> upload({
    required String sessionId,
    required String therapistId,
    required Uint8List bytes,
    required String filename,
    required String contentType,
    required DateTime consentAt,
  }) async {
    final mediaParts = contentType.split('/');
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/videos'))
      ..fields['session_id'] = sessionId
      ..fields['therapist_id'] = therapistId
      ..fields['consent_at'] = consentAt.toUtc().toIso8601String()
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
    request.headers.addAll(await _headers());
    final streamed = await _client
        .send(request)
        .timeout(const Duration(minutes: 2));
    final response = await http.Response.fromStream(streamed);
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw VideoApiException(
        payload['detail']?.toString() ?? 'Não foi possível guardar o vídeo.',
      );
    }
    return VideoUploadResult.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Future<String> download(
    String sessionId, {
    bool annotated = false,
    String? exerciseType,
    String? analyzedSide,
  }) async {
    final uri = annotated
        ? Uri.parse('$baseUrl/videos/$sessionId/annotated').replace(
            queryParameters: {
              'exercise_type': exerciseType ?? 'elbow_flexion',
              if (analyzedSide != null) 'analyzed_side': analyzedSide,
            },
          )
        : Uri.parse('$baseUrl/videos/$sessionId');
    final response = await _client
        .get(uri, headers: await _headers())
        .timeout(const Duration(minutes: 2));
    if (response.statusCode != 200) {
      throw VideoApiException(_errorMessage(response, 'Vídeo indisponível.'));
    }
    final contentType = response.headers['content-type'] ?? 'video/mp4';
    final extension = contentType.contains('quicktime')
        ? 'mov'
        : contentType.contains('webm')
        ? 'webm'
        : 'mp4';
    final directory = await getTemporaryDirectory();
    final suffix = annotated ? '-anotado' : '';
    final file = File('${directory.path}/movere-$sessionId$suffix.$extension');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file.path;
  }

  Future<void> delete(String sessionId) async {
    final response = await _client
        .delete(
          Uri.parse('$baseUrl/videos/$sessionId'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 204 && response.statusCode != 404) {
      throw VideoApiException(
        _errorMessage(response, 'Não foi possível excluir o vídeo.'),
      );
    }
  }

  Future<Map<String, String>> _headers() async {
    final token = await _accessTokenProvider?.call();
    if (token == null || token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }

  String _errorMessage(http.Response response, String fallback) {
    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return payload['detail']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}
