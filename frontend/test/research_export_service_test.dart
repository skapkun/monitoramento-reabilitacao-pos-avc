import 'package:flutter_test/flutter_test.dart';
import 'package:movere_app/models/clinical_data.dart';
import 'package:movere_app/services/research_export_service.dart';

void main() {
  test('exportação usa código estável e não expõe identificador ou datas', () {
    final service = ResearchExportService();
    const patientId = 'paciente-identificavel-123';
    final sessions = [
      RehabilitationSession(
        id: 'sessao-secreta',
        patientId: patientId,
        exerciseType: 'elbow_flexion',
        status: 'completed',
        createdAt: DateTime.utc(2026, 10, 10, 14),
        repetitions: 6,
        analysisParametersVersion: 'elbow-flexion-v1',
        validFrames: 90,
        totalFrames: 100,
        detectionRatio: 0.9,
        eventReviews: {
          'limited_amplitude_1000': 'confirmed',
          'trunk_inclination_2000': 'not_confirmed',
        },
      ),
      RehabilitationSession(
        id: 'outra-sessao',
        patientId: patientId,
        exerciseType: 'elbow_flexion',
        status: 'completed',
        createdAt: DateTime.utc(2026, 10, 13, 14),
      ),
    ];

    final csv = service.buildCsv(patientId: patientId, sessions: sessions);
    final code = service.participantCode(patientId);

    expect(code, hasLength(12));
    expect(csv, contains(code));
    expect(csv, contains('days_since_first_session'));
    expect(csv, contains('\n$code,1,0,'));
    expect(csv, contains('\n$code,2,3,'));
    expect(csv, isNot(contains(patientId)));
    expect(csv, isNot(contains('sessao-secreta')));
    expect(csv, isNot(contains('2026-10-10')));
    expect(csv, contains('elbow-flexion-v1'));
    expect(csv, contains(',1,1,0,'));
  });
}
