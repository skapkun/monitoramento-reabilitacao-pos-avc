import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movere_app/models/clinical_data.dart';
import 'package:movere_app/models/patient_summary.dart';
import 'package:movere_app/screens/patient/history_screen.dart';
import 'package:movere_app/screens/patient/progress_screen.dart';
import 'package:movere_app/screens/patient/recording_screen.dart';
import 'package:movere_app/screens/patient/result_screen.dart';
import 'package:movere_app/screens/patient/wellbeing_screen.dart';
import 'package:movere_app/screens/shared/messages_screen.dart';
import 'package:movere_app/screens/therapist/reports_screen.dart';
import 'package:movere_app/screens/therapist/plan_management_screen.dart';
import 'package:movere_app/screens/therapist/sessions_screen.dart';
import 'package:movere_app/services/clinical_repository.dart';
import 'package:movere_app/services/analysis_api_service.dart';
import 'package:movere_app/widgets/session_list.dart';

void main() {
  const repository = DemoClinicalRepository();

  testWidgets('histórico apresenta sessões registradas', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HistoryScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sessões realizadas'), findsOneWidget);
    expect(find.textContaining('8 repetições'), findsOneWidget);
    expect(find.textContaining('Inconclusiva'), findsOneWidget);
  });

  testWidgets('paciente usa mensagem rápida e visualiza conversa', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MessagesScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Canal não emergencial'), findsOneWidget);
    expect(find.textContaining('Tenho dúvida sobre a posição'), findsOneWidget);
    await tester.tap(find.text('Senti dor'));
    await tester.pump();
    expect(
      find.textContaining('Senti dor ou desconforto durante o exercício'),
      findsOneWidget,
    );
  });

  testWidgets('evolução calcula indicadores longitudinais', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PatientProgressScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resumo do seu progresso'), findsOneWidget);
    expect(find.text('Sessões'), findsOneWidget);
    expect(find.text('Média de repetições'), findsOneWidget);
  });

  testWidgets('relatório resume sessões do paciente', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ReportsScreen(
          repository: repository,
          patient: PatientSummary(
            name: 'Paciente Teste',
            initials: 'PT',
            lastSession: 'Hoje',
            sessions: 2,
            adherence: 100,
            status: 'Acompanhamento ativo',
            requiresReview: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Paciente Teste'), findsOneWidget);
    expect(find.text('2 sessões registradas'), findsOneWidget);
    expect(find.text('Gerar e compartilhar PDF'), findsOneWidget);
  });

  testWidgets('paciente informa bem-estar em escala de cinco pontos', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WellbeingScreen(repository: repository, sessionId: 'demo-1'),
      ),
    );

    expect(find.text('Como você se sentiu após o exercício?'), findsOneWidget);
    expect(find.byKey(const Key('bem_estar_5')), findsOneWidget);
    expect(find.byKey(const Key('dor_pos_sessao')), findsOneWidget);
    expect(find.byKey(const Key('fadiga_pos_sessao')), findsOneWidget);
    await tester.tap(find.byKey(const Key('bem_estar_5')));
    await tester.pump();
    expect(find.text('Muito bem'), findsOneWidget);
    expect(find.byIcon(Icons.sentiment_very_satisfied), findsOneWidget);
  });

  testWidgets('fisioterapeuta abre avaliação e escolhe conduta', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TherapistSessionsScreen(
          repository: repository,
          patient: PatientSummary(
            name: 'Paciente Teste',
            initials: 'PT',
            lastSession: 'Hoje',
            sessions: 2,
            adherence: 100,
            status: 'Acompanhamento ativo',
            requiresReview: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('Marcar como revisada'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Marcar como revisada'));
    await tester.pumpAndSettle();
    expect(find.text('Avaliar sessão'), findsOneWidget);
    expect(find.text('Manter treino'), findsOneWidget);
    expect(find.text('Salvar avaliação'), findsOneWidget);
  });

  testWidgets('compartilhamentos começam desativados e exigem escolha', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: RecordingScreen(allowSimulation: false)),
    );

    final checkbox = tester.widget<CheckboxListTile>(
      find.byKey(const Key('compartilhar_video')),
    );
    expect(checkbox.value, isFalse);

    await tester.tap(find.byKey(const Key('compartilhar_video')));
    await tester.pump();

    final selected = tester.widget<CheckboxListTile>(
      find.byKey(const Key('compartilhar_video')),
    );
    expect(selected.value, isTrue);

    await tester.ensureVisible(
      find.byKey(const Key('compartilhar_video_completo')),
    );
    await tester.pumpAndSettle();
    final fullVideoCheckbox = tester.widget<CheckboxListTile>(
      find.byKey(const Key('compartilhar_video_completo')),
    );
    expect(fullVideoCheckbox.value, isFalse);

    await tester.tap(find.byKey(const Key('compartilhar_video_completo')));
    await tester.pump();

    final fullVideoSelected = tester.widget<CheckboxListTile>(
      find.byKey(const Key('compartilhar_video_completo')),
    );
    expect(fullVideoSelected.value, isTrue);
  });

  testWidgets('sessão compartilhada oferece reprodução ao usuário autorizado', (
    tester,
  ) async {
    var opened = false;
    final session = RehabilitationSession(
      id: 'session-video',
      patientId: 'patient',
      exerciseType: 'elbow_flexion',
      status: 'completed',
      createdAt: DateTime(2026, 10, 11),
      videoStoragePath: 'sessionVideos/patient/session-video/video',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionList(
            sessions: [session],
            onOpenVideo: (_) async => opened = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Assistir vídeo compartilhado'));
    expect(opened, isTrue);
  });

  testWidgets('paciente vê somente observação confirmada e compartilhada', (
    tester,
  ) async {
    const event = MovementEvent(
      type: 'limited_amplitude',
      title: 'Amplitude abaixo da referência',
      description: 'O movimento teve menor amplitude neste instante.',
      startSeconds: 2,
      endSeconds: 3,
      severity: 'attention',
    );
    final hiddenSession = RehabilitationSession(
      id: 'hidden',
      patientId: 'patient',
      exerciseType: 'elbow_flexion',
      status: 'completed',
      createdAt: DateTime(2026, 10, 11),
      movementEvents: const [event],
      eventReviews: const {'limited_amplitude_2000': 'confirmed'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SessionList(sessions: [hiddenSession])),
      ),
    );
    expect(find.text('Amplitude abaixo da referência'), findsNothing);
    expect(find.text('Nenhum ponto para conferir'), findsOneWidget);

    final sharedSession = RehabilitationSession(
      id: 'shared',
      patientId: 'patient',
      exerciseType: 'elbow_flexion',
      status: 'completed',
      createdAt: DateTime(2026, 10, 11),
      movementEvents: const [event],
      eventReviews: const {'limited_amplitude_2000': 'confirmed'},
      reviewVisibleToPatient: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SessionList(sessions: [sharedSession])),
      ),
    );
    expect(
      find.text('Observações compartilhadas pelo fisioterapeuta'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Amplitude abaixo da referência'),
      findsOneWidget,
    );
  });

  testWidgets('profissional vê marcações automáticas ainda não revisadas', (
    tester,
  ) async {
    final session = RehabilitationSession(
      id: 'professional',
      patientId: 'patient',
      exerciseType: 'elbow_flexion',
      status: 'completed',
      createdAt: DateTime(2026, 10, 11),
      movementEvents: const [
        MovementEvent(
          type: 'limited_amplitude',
          title: 'Amplitude para conferir',
          description: 'Marcação automática ainda não revisada.',
          startSeconds: 2,
          endSeconds: 3,
          severity: 'attention',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionList(sessions: [session], professionalView: true),
        ),
      ),
    );
    expect(find.text('Momentos destacados automaticamente'), findsOneWidget);
    expect(find.textContaining('Amplitude para conferir'), findsOneWidget);
  });

  testWidgets('prescrição profissional apresenta parâmetros individuais', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PlanManagementScreen(
          repository: repository,
          patient: PatientSummary(
            id: 'demo-patient',
            name: 'Paciente Teste',
            initials: 'PT',
            lastSession: 'Hoje',
            sessions: 2,
            adherence: 100,
            status: 'Acompanhamento ativo',
            requiresReview: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('prescricao_series')), findsOneWidget);
    expect(find.byKey(const Key('prescricao_repeticoes')), findsOneWidget);
    expect(find.byKey(const Key('prescricao_amplitude')), findsOneWidget);
    expect(find.text('Lado trabalhado'), findsOneWidget);
    expect(find.text('Prescrição ativa'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('calibracao_deteccao')));
    await tester.tap(find.byKey(const Key('calibracao_deteccao')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('limiar_inicio')), findsOneWidget);
    expect(find.byKey(const Key('limiar_mudanca')), findsOneWidget);
    expect(find.byKey(const Key('justificativa_calibracao')), findsOneWidget);
    expect(find.text('Restaurar valores padrão'), findsOneWidget);
  });

  testWidgets('resultado mostra comparação bilateral e momentos do vídeo', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResultScreen(
          result: AnalysisApiResponse(
            analysisId: 'analysis',
            status: 'completed',
            simulated: false,
            message: 'Movimento processado.',
            metrics: AnalysisApiMetrics(
              repetitions: 2,
              source: 'computer_vision',
              affectedSide: 'right',
              unaffectedSide: 'left',
              averageAffectedAngleDegrees: 110,
              averageUnaffectedAngleDegrees: 118,
              movementEvents: [
                MovementEvent(
                  type: 'best_repetition',
                  title: 'Maior amplitude observada',
                  description: 'Repetição 2.',
                  startSeconds: 3.2,
                  endSeconds: 5.1,
                  severity: 'positive',
                  repetition: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Momentos importantes do vídeo'), findsOneWidget);
    expect(find.text('Maior amplitude observada'), findsOneWidget);
    expect(find.text('Ângulo médio do lado afetado'), findsOneWidget);
    expect(find.text('Ângulo médio do lado não afetado'), findsOneWidget);
  });
}
