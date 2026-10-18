import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:movere_app/services/analysis_api_service.dart';

void main() {
  test('interpreta resposta simulada aceita pela API', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/analysis');
      expect(request.headers['authorization'], 'Bearer firebase-token');
      return http.Response(
        '''
        {
          "status": "success",
          "data": {
            "analysis_id": "22222222-2222-4222-8222-222222222222",
            "session_id": "11111111-1111-4111-8111-111111111111",
            "exercise_type": "elbow_flexion",
            "status": "processing",
            "simulated": true,
            "message": "Vídeo recebido para processamento simulado."
          },
          "message": "Solicitação de análise simulada aceita."
        }
        ''',
        202,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = AnalysisApiService(
      client: client,
      baseUrl: 'http://localhost:8000',
      accessTokenProvider: () async => 'firebase-token',
    );

    final response = await service.submitSimulatedVideo();

    expect(response.status, 'processing');
    expect(response.simulated, isTrue);
    expect(response.analysisId, '22222222-2222-4222-8222-222222222222');
    service.close();
  });

  test('expõe mensagem de erro devolvida pela API', () async {
    final client = MockClient(
      (_) async => http.Response(
        '{"detail":"Arquivo inválido."}',
        400,
        headers: {'content-type': 'application/json'},
      ),
    );
    final service = AnalysisApiService(
      client: client,
      baseUrl: 'http://localhost:8000',
    );

    expect(
      service.submitSimulatedVideo,
      throwsA(
        isA<AnalysisApiException>().having(
          (error) => error.message,
          'message',
          'Arquivo inválido.',
        ),
      ),
    );
    service.close();
  });

  test('aguarda análise real e interpreta métricas técnicas', () async {
    var getCalls = 0;
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        expect(request.body, contains('pinch'));
        expect(request.body, contains('detection_start_threshold'));
        expect(request.body, contains('0.12'));
        expect(request.body, contains('detection_change_threshold'));
        expect(request.body, contains('0.05'));
        return http.Response('''
          {
            "status":"success",
            "data":{
              "analysis_id":"22222222-2222-4222-8222-222222222222",
              "session_id":"11111111-1111-4111-8111-111111111111",
              "exercise_type":"pinch",
              "status":"processing",
              "simulated":false,
              "message":"Vídeo recebido."
            },
            "message":"Solicitação aceita."
          }
          ''', 202);
      }
      getCalls++;
      return http.Response('''
        {
          "status":"success",
          "data":{
            "analysis_id":"22222222-2222-4222-8222-222222222222",
            "session_id":"11111111-1111-4111-8111-111111111111",
            "exercise_type":"pinch",
            "status":"completed",
            "simulated":false,
            "message":"Movimento processado tecnicamente.",
            "technical_issue_code":null,
            "created_at":"2026-10-04T12:00:00Z",
            "metrics":{
              "repetitions":3,
              "source":"computer_vision",
              "confidence":0.91,
              "average_amplitude_degrees":94.5,
              "analyzed_side":"right",
              "affected_side":"right",
              "unaffected_side":"left",
              "average_affected_angle_degrees":112.0,
              "average_unaffected_angle_degrees":120.0,
              "movement_events":[{
                "type":"best_repetition",
                "title":"Maior amplitude observada",
                "description":"Repetição 2.",
                "start_seconds":3.2,
                "end_seconds":5.1,
                "severity":"positive",
                "repetition":2
              }],
              "repetition_details":[{
                "number":2,
                "start_seconds":3.2,
                "end_seconds":5.1,
                "amplitude_degrees":94.5,
                "duration_seconds":1.9,
                "classification":"best"
              }]
            }
          },
          "message":"Estado recuperado."
        }
        ''', 200);
    });
    final service = AnalysisApiService(client: client, baseUrl: 'http://api');

    final result = await service.submitAndWait(
      bytes: Uint8List.fromList([1, 2, 3]),
      filename: 'movimento.mp4',
      exerciseType: 'pinch',
      detectionStartThreshold: 0.12,
      detectionChangeThreshold: 0.05,
      pollInterval: Duration.zero,
    );

    expect(getCalls, 1);
    expect(result.simulated, isFalse);
    expect(result.status, 'completed');
    expect(result.exerciseType, 'pinch');
    expect(result.metrics?.repetitions, 3);
    expect(result.metrics?.averageAmplitudeDegrees, 94.5);
    expect(result.metrics?.analyzedSide, 'right');
    expect(result.metrics?.affectedSide, 'right');
    expect(result.metrics?.movementEvents.single.startSeconds, 3.2);
    expect(result.metrics?.repetitionDetails.single.classification, 'best');
    service.close();
  });
}
