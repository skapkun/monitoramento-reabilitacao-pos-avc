import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/analysis_api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';
import '../../widgets/status_banner.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({this.inconclusive = false, this.result, super.key});

  final bool inconclusive;
  final AnalysisApiResponse? result;

  @override
  Widget build(BuildContext context) {
    final isInconclusive = inconclusive || result?.status == 'inconclusive';
    final isSimulated = result?.simulated ?? true;
    final metrics = result?.metrics;
    final exerciseName = switch (result?.exerciseType) {
      'squat' => 'Agachamento',
      'pinch' => 'Pinça',
      _ => 'Flexão de cotovelo',
    };
    return AppPage(
      title: 'Resultado',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusBanner(
            icon: isInconclusive ? Icons.help_outline : Icons.science_outlined,
            title: isInconclusive
                ? 'Não foi possível analisar'
                : isSimulated
                ? 'Resultado simulado'
                : 'Resultado do vídeo',
            message: isInconclusive
                ? result?.message ??
                      'Tente novamente seguindo as orientações de enquadramento.'
                : isSimulated
                ? 'Os dados abaixo servem apenas para demonstrar a interface. Nenhuma análise real foi realizada.'
                : 'O aplicativo contou os movimentos observados no vídeo.',
            backgroundColor: AppColors.warningBackground,
            foregroundColor: AppColors.warningText,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!isInconclusive)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exerciseName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ResultRow(
                      label: isSimulated
                          ? 'Repetições simuladas'
                          : 'Repetições observadas',
                      value: '${metrics?.repetitions ?? 8}',
                    ),
                    _ResultRow(
                      label: 'Estado',
                      value: isSimulated
                          ? 'Demonstração concluída'
                          : 'Vídeo analisado',
                    ),
                    _ResultRow(
                      label: 'Origem',
                      value: isSimulated
                          ? 'Dados simulados'
                          : 'Visão computacional experimental',
                    ),
                    if (metrics?.averageAmplitudeDegrees != null)
                      _ResultRow(
                        label: 'Amplitude média observada',
                        value:
                            '${metrics!.averageAmplitudeDegrees!.toStringAsFixed(1)}°',
                      ),
                    if (metrics?.confidence != null)
                      _ResultRow(
                        label: 'Qualidade técnica da detecção',
                        value: '${(metrics!.confidence! * 100).round()}%',
                      ),
                    if (metrics?.averageDurationSeconds != null)
                      _ResultRow(
                        label: 'Tempo médio por repetição',
                        value:
                            '${metrics!.averageDurationSeconds!.toStringAsFixed(2)} s',
                      ),
                    if (metrics?.averageVelocityDegreesPerSecond != null)
                      _ResultRow(
                        label: 'Velocidade angular média',
                        value:
                            '${metrics!.averageVelocityDegreesPerSecond!.toStringAsFixed(1)}°/s',
                      ),
                    if (metrics?.averageSymmetryDifferenceDegrees != null)
                      _ResultRow(
                        label: 'Diferença bilateral média',
                        value:
                            '${metrics!.averageSymmetryDifferenceDegrees!.toStringAsFixed(1)}°',
                      ),
                    if (metrics?.averageDistance != null)
                      _ResultRow(
                        label: 'Distância média polegar–indicador',
                        value: metrics!.averageDistance!.toStringAsFixed(3),
                      ),
                    if (metrics?.analyzedSide != null)
                      _ResultRow(
                        label: 'Braço analisado',
                        value: metrics!.analyzedSide == 'left'
                            ? 'Esquerdo'
                            : 'Direito',
                      ),
                    if (metrics?.averageAffectedAngleDegrees != null)
                      _ResultRow(
                        label: 'Ângulo médio do lado afetado',
                        value:
                            '${metrics!.averageAffectedAngleDegrees!.toStringAsFixed(1)}°',
                      ),
                    if (metrics?.averageUnaffectedAngleDegrees != null)
                      _ResultRow(
                        label: 'Ângulo médio do lado não afetado',
                        value:
                            '${metrics!.averageUnaffectedAngleDegrees!.toStringAsFixed(1)}°',
                      ),
                  ],
                ),
              ),
            ),
          if (!isInconclusive &&
              (metrics?.movementEvents.isNotEmpty ?? false)) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Momentos importantes do vídeo',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Os segundos abaixo ajudam você e o fisioterapeuta a encontrar cada momento no vídeo compartilhado.',
            ),
            const SizedBox(height: AppSpacing.md),
            ...metrics!.movementEvents.map(
              (event) => Card(
                color: event.severity == 'positive'
                    ? AppColors.successSoft
                    : AppColors.warningBackground,
                child: ListTile(
                  minVerticalPadding: AppSpacing.md,
                  leading: Icon(
                    event.severity == 'positive'
                        ? Icons.star_outline
                        : Icons.visibility_outlined,
                    color: event.severity == 'positive'
                        ? AppColors.successSoftText
                        : AppColors.warningText,
                  ),
                  title: Text(event.title),
                  subtitle: Text(
                    '${event.description}\nMomento: ${_time(event.startSeconds)}',
                  ),
                ),
              ),
            ),
          ],
          if (!isInconclusive &&
              (metrics?.possibleCompensations.isNotEmpty ?? false)) ...[
            const SizedBox(height: AppSpacing.lg),
            StatusBanner(
              icon: Icons.visibility_outlined,
              title: 'Peça ao fisioterapeuta para conferir',
              message:
                  metrics!.possibleCompensations.contains(
                    'possible_trunk_inclination',
                  )
                  ? 'Foi observada possível inclinação excessiva do tronco. O resultado deve ser interpretado pelo fisioterapeuta.'
                  : 'Foi observada uma possível elevação do ombro. O resultado deve ser interpretado pelo fisioterapeuta.',
              backgroundColor: AppColors.warningBackground,
              foregroundColor: AppColors.warningText,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const StatusBanner(
            icon: Icons.info_outline,
            title: 'Sobre o resultado',
            message:
                'O sistema não fornece diagnóstico e não substitui a avaliação do fisioterapeuta.',
            backgroundColor: AppColors.primarySoft,
            foregroundColor: AppColors.primarySoftText,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: result != null && !result!.simulated
                ? () => Navigator.pushNamed(
                    context,
                    AppRoutes.wellbeing,
                    arguments: result!.analysisId,
                  )
                : () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.patientHome,
                    (route) => false,
                  ),
            icon: Icon(
              result != null && !result!.simulated
                  ? Icons.favorite_outline
                  : Icons.home_outlined,
            ),
            label: Text(
              result != null && !result!.simulated
                  ? 'Informar como me senti'
                  : 'Voltar ao início',
            ),
          ),
        ],
      ),
    );
  }

  String _time(double seconds) {
    final duration = Duration(milliseconds: (seconds * 1000).round());
    final minutes = duration.inMinutes;
    final remainder = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$remainder';
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        label: '$label: $value',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primarySoftText,
                ),
              ),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}
