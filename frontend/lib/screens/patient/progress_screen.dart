import 'package:flutter/material.dart';

import '../../models/clinical_data.dart';
import '../../services/clinical_repository.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/responsive_metric_grid.dart';
import '../../widgets/status_banner.dart';
import '../../widgets/session_trend.dart';
import '../../theme/app_colors.dart';

class PatientProgressScreen extends StatelessWidget {
  const PatientProgressScreen({required this.repository, super.key});

  final ClinicalRepository repository;

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Evolução',
    child: StreamBuilder<List<RehabilitationSession>>(
      stream: repository.watchMySessions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Não foi possível calcular a evolução.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final sessions = snapshot.data!;
        final completed = sessions
            .where((item) => item.status == 'completed')
            .toList();
        final average = completed.isEmpty
            ? 0
            : (completed.fold<int>(0, (sum, item) => sum + item.repetitions) /
                      completed.length)
                  .round();
        final review = sessions.where((item) => item.requiresReview).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Resumo do seu progresso',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            ResponsiveMetricGrid(
              children: [
                MetricCard(
                  label: 'Sessões',
                  value: '${sessions.length}',
                  icon: Icons.event_note_outlined,
                ),
                MetricCard(
                  label: 'Concluídas',
                  value: '${completed.length}',
                  icon: Icons.check_circle_outline,
                ),
                MetricCard(
                  label: 'Média de repetições',
                  value: '$average',
                  icon: Icons.repeat,
                ),
                MetricCard(
                  label: 'Para revisão',
                  value: '$review',
                  icon: Icons.visibility_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SessionTrend(sessions: sessions),
            if (completed.isNotEmpty) const SizedBox(height: AppSpacing.lg),
            const StatusBanner(
              icon: Icons.info_outline,
              title: 'Converse com seu fisioterapeuta',
              message:
                  'Estes números mostram apenas o que foi registrado nas sessões. Eles não são um diagnóstico nem uma avaliação clínica.',
              backgroundColor: AppColors.primarySoft,
              foregroundColor: AppColors.primarySoftText,
            ),
          ],
        );
      },
    ),
  );
}
