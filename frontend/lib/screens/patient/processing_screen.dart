import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/selected_video.dart';
import '../../routes/app_routes.dart';
import '../../services/analysis_api_service.dart';
import '../../services/clinical_repository.dart';
import '../../models/clinical_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({
    this.apiService,
    ClinicalRepository? clinicalRepository,
    this.video,
    super.key,
  }) : clinicalRepository =
           clinicalRepository ?? const DemoClinicalRepository();

  final AnalysisApiService? apiService;
  final SelectedVideo? video;
  final ClinicalRepository clinicalRepository;

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  ProcessingStatus status = ProcessingStatus.processing;
  late final AnalysisApiService apiService;
  late final bool ownsService;
  String? apiMessage;
  AnalysisApiResponse? analysisResult;

  @override
  void initState() {
    super.initState();
    ownsService = widget.apiService == null;
    apiService =
        widget.apiService ??
        AnalysisApiService(
          accessTokenProvider: () async {
            final user = FirebaseAuth.instance.currentUser;
            return await user?.getIdToken();
          },
        );
    if (widget.video != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => sendSelectedVideo());
    }
  }

  @override
  void dispose() {
    if (ownsService) apiService.close();
    super.dispose();
  }

  void completeSimulation() {
    setState(() {
      status = ProcessingStatus.completed;
      apiMessage = null;
      analysisResult = AnalysisApiResponse(
        analysisId: 'demo-session',
        status: 'completed',
        simulated: true,
        message: 'Resultado demonstrativo concluído.',
        metrics: const AnalysisApiMetrics(
          repetitions: 8,
          source: 'mock',
          averageAmplitudeDegrees: 92,
          affectedSide: 'right',
          unaffectedSide: 'left',
          averageAffectedAngleDegrees: 111,
          averageUnaffectedAngleDegrees: 118,
          movementEvents: [
            MovementEvent(
              type: 'best_repetition',
              title: 'Maior amplitude observada',
              description: 'Exemplo demonstrativo da repetição 5.',
              startSeconds: 12.4,
              endSeconds: 14.6,
              severity: 'positive',
              repetition: 5,
            ),
            MovementEvent(
              type: 'possible_shoulder_elevation',
              title: 'Possível elevação do ombro',
              description:
                  'Exemplo demonstrativo que exigiria revisão do fisioterapeuta.',
              startSeconds: 18.2,
              endSeconds: 19.8,
              severity: 'attention',
              repetition: 7,
            ),
          ],
        ),
      );
    });
  }

  Future<void> sendToApi() async {
    setState(() {
      status = ProcessingStatus.connecting;
      apiMessage = null;
    });
    try {
      final response = await apiService.submitSimulatedAndWait();
      await _persist(response);
      if (!mounted) return;
      setState(() {
        analysisResult = response;
        status = _screenStatus(response.status);
        apiMessage = response.message;
      });
    } on AnalysisApiException catch (error) {
      if (!mounted) return;
      setState(() {
        status = ProcessingStatus.failed;
        apiMessage = error.message;
      });
    } catch (_) {
      _showConnectionFailure();
    }
  }

  Future<void> _persist(AnalysisApiResponse response) async {
    if (!response.isFinished) return;
    final metrics = response.metrics;
    final plan = widget.video?.plan;
    try {
      await widget.clinicalRepository.saveSession(
        RehabilitationSession(
          id: response.analysisId,
          patientId: '',
          exerciseType: widget.video?.exerciseType ?? 'elbow_flexion',
          status: response.status,
          createdAt: DateTime.now(),
          repetitions: metrics?.repetitions ?? 0,
          averageAmplitudeDegrees: metrics?.averageAmplitudeDegrees,
          confidence: metrics?.confidence,
          averageDurationSeconds: metrics?.averageDurationSeconds,
          averageVelocityDegreesPerSecond:
              metrics?.averageVelocityDegreesPerSecond,
          averageSymmetryDifferenceDegrees:
              metrics?.averageSymmetryDifferenceDegrees,
          averageDistance: metrics?.averageDistance,
          requiresReview:
              response.status != 'completed' ||
              (metrics?.possibleCompensations.isNotEmpty ?? false),
          simulated: response.simulated,
          message: response.message,
          technicalIssueCode: response.technicalIssueCode,
          prescriptionVersion: plan?.version,
          prescribedSets: plan?.sets,
          prescribedRepetitions: plan?.targetRepetitions,
          prescribedSessionsPerWeek: plan?.sessionsPerWeek,
          prescribedAmplitudeDegrees: plan?.targetAmplitudeDegrees,
          prescribedTrainingSide: plan?.trainingSide,
          prescribedCadenceSeconds: plan?.cadenceSeconds,
          prescribedRestSeconds: plan?.restSeconds,
          customDetectionApplied: plan?.customDetectionEnabled == true,
          detectionStartThreshold: plan?.customDetectionEnabled == true
              ? plan?.detectionStartThreshold
              : null,
          detectionChangeThreshold: plan?.customDetectionEnabled == true
              ? plan?.detectionChangeThreshold
              : null,
          calibrationReason: plan?.customDetectionEnabled == true
              ? plan?.calibrationReason
              : null,
          movementEvents: metrics?.movementEvents ?? const [],
          repetitionDetails: metrics?.repetitionDetails ?? const [],
          affectedSide: metrics?.affectedSide,
          unaffectedSide: metrics?.unaffectedSide,
          averageAffectedAngleDegrees: metrics?.averageAffectedAngleDegrees,
          averageUnaffectedAngleDegrees: metrics?.averageUnaffectedAngleDegrees,
          analysisParametersVersion: metrics?.parametersVersion,
          validFrames: metrics?.validFrames,
          totalFrames: metrics?.totalFrames,
          detectionRatio: metrics?.detectionRatio,
          evidence: widget.video?.shareWithTherapist == true
              ? metrics?.evidence ?? const []
              : const [],
          evidenceConsentAt: widget.video?.shareWithTherapist == true
              ? widget.video?.consentAt ?? DateTime.now()
              : null,
          evidenceConsentVersion: widget.video?.shareWithTherapist == true
              ? 'analysis-evidence-v1'
              : null,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A análise terminou, mas não foi possível registrar a sessão no histórico.',
            ),
          ),
        );
      }
    }
  }

  Future<void> sendSelectedVideo() async {
    setState(() {
      status = ProcessingStatus.connecting;
      apiMessage = null;
    });
    try {
      final file = widget.video!.file;
      final reportedMimeType = file.mimeType;
      final bytes = await file.readAsBytes();
      final contentType =
          reportedMimeType != null && reportedMimeType.startsWith('video/')
          ? reportedMimeType
          : _mimeTypeFor(file.name);
      final response = await apiService.submitAndWait(
        bytes: bytes,
        filename: file.name,
        mimeType: contentType,
        exerciseType: widget.video!.exerciseType,
        affectedSide: await _affectedSide(),
        detectionStartThreshold:
            widget.video!.plan?.customDetectionEnabled == true
            ? widget.video!.plan?.detectionStartThreshold
            : null,
        detectionChangeThreshold:
            widget.video!.plan?.customDetectionEnabled == true
            ? widget.video!.plan?.detectionChangeThreshold
            : null,
      );
      await _persist(response);
      if (widget.video!.shareFullVideo) {
        try {
          await widget.clinicalRepository.uploadSessionVideo(
            sessionId: response.analysisId,
            bytes: bytes,
            contentType: contentType,
            consentAt: widget.video!.videoConsentAt ?? DateTime.now(),
          );
        } on ClinicalRepositoryException catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error.message)));
          }
        }
      }
      if (!mounted) return;
      setState(() {
        analysisResult = response;
        status = _screenStatus(response.status);
        apiMessage = response.message;
      });
    } on AnalysisApiException catch (error) {
      if (!mounted) return;
      setState(() {
        status = ProcessingStatus.failed;
        apiMessage = error.message;
      });
    } catch (_) {
      _showConnectionFailure();
    }
  }

  Future<String?> _affectedSide() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.clinicalRepository.isDemo) return null;
    try {
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final side = profile.data()?['affectedSide']?.toString();
      return side == 'left' || side == 'right' ? side : null;
    } catch (_) {
      return null;
    }
  }

  void _showConnectionFailure() {
    if (!mounted) return;
    setState(() {
      status = ProcessingStatus.failed;
      apiMessage =
          'Não foi possível acessar a API local. Confirme se o FastAPI está em execução e tente novamente.';
    });
  }

  ProcessingStatus _screenStatus(String apiStatus) => switch (apiStatus) {
    'completed' => ProcessingStatus.completed,
    'inconclusive' => ProcessingStatus.inconclusive,
    'failed' => ProcessingStatus.failed,
    _ => ProcessingStatus.connecting,
  };

  String _mimeTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.webm')) return 'video/webm';
    return 'video/mp4';
  }

  @override
  Widget build(BuildContext context) {
    final realVideo = widget.video != null;
    return AppPage(
      title: 'Processamento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            label: switch (status) {
              ProcessingStatus.processing =>
                'Processamento simulado em andamento',
              ProcessingStatus.connecting => 'Envio do vídeo em andamento',
              ProcessingStatus.completed =>
                realVideo
                    ? 'Processamento de vídeo concluído'
                    : 'Processamento simulado concluído',
              ProcessingStatus.inconclusive => 'Análise inconclusiva',
              ProcessingStatus.failed => 'Processamento falhou',
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (status == ProcessingStatus.completed)
                    const Icon(
                      Icons.check_circle,
                      size: 72,
                      color: AppColors.success,
                    )
                  else if (status == ProcessingStatus.failed)
                    const Icon(
                      Icons.error_outline,
                      size: 72,
                      color: AppColors.errorText,
                    )
                  else if (status == ProcessingStatus.inconclusive)
                    const Icon(
                      Icons.help_outline,
                      size: 72,
                      color: AppColors.warningText,
                    )
                  else
                    const SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(strokeWidth: 6),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    switch (status) {
                      ProcessingStatus.processing => 'Analisando movimento',
                      ProcessingStatus.connecting => 'Enviando vídeo',
                      ProcessingStatus.completed =>
                        realVideo
                            ? 'Processamento concluído'
                            : 'Demonstração concluída',
                      ProcessingStatus.inconclusive =>
                        'Não foi possível analisar adequadamente',
                      ProcessingStatus.failed => 'Não foi possível concluir',
                    },
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    switch (status) {
                      ProcessingStatus.processing =>
                        'Esta é uma simulação. Nenhum vídeo está sendo analisado.',
                      ProcessingStatus.connecting =>
                        realVideo
                            ? 'Aguarde enquanto o vídeo é enviado e analisado.'
                            : 'Enviando o vídeo de demonstração.',
                      ProcessingStatus.completed =>
                        apiMessage ??
                            'Um resultado simulado está pronto para visualização.',
                      ProcessingStatus.inconclusive =>
                        apiMessage ??
                            'Tente novamente seguindo as orientações de enquadramento.',
                      ProcessingStatus.failed =>
                        apiMessage ??
                            'Falha simulada. Tente novamente para continuar a demonstração.',
                    },
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (status == ProcessingStatus.processing &&
              widget.clinicalRepository.isDemo) ...[
            ElevatedButton(
              key: const Key('concluir_processamento'),
              onPressed: completeSimulation,
              child: const Text('Concluir simulação'),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              key: const Key('enviar_api'),
              onPressed: sendToApi,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Testar API simulada'),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              key: const Key('simular_falha'),
              onPressed: () => setState(() => status = ProcessingStatus.failed),
              child: const Text('Simular falha'),
            ),
          ] else if (status == ProcessingStatus.failed)
            ElevatedButton.icon(
              key: const Key('tentar_novamente'),
              onPressed: realVideo
                  ? sendSelectedVideo
                  : () => setState(() {
                      status = ProcessingStatus.processing;
                      apiMessage = null;
                    }),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            )
          else
            ElevatedButton.icon(
              key: const Key('ver_resultado'),
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.result,
                arguments:
                    analysisResult ??
                    (status == ProcessingStatus.inconclusive ? true : null),
              ),
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                status == ProcessingStatus.inconclusive
                    ? 'Ver orientação'
                    : 'Ver resultado',
              ),
            ),
        ],
      ),
    );
  }
}

enum ProcessingStatus {
  processing,
  connecting,
  completed,
  inconclusive,
  failed,
}
