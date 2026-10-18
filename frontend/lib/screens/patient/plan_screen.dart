import 'package:flutter/material.dart';

import '../../models/exercise.dart';
import '../../models/clinical_data.dart';
import '../../routes/app_routes.dart';
import '../../services/clinical_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/portuguese_text.dart';
import '../../widgets/app_page.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({ClinicalRepository? repository, super.key})
    : repository = repository ?? const DemoClinicalRepository();

  final ClinicalRepository repository;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Meu plano',
      child: StreamBuilder<List<TherapyPlan>>(
        stream: repository.watchMyPlan(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Não foi possível carregar o plano.');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final plans = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Minha rotina de exercícios',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                plans.isEmpty
                    ? 'Nenhum exercício foi atribuído pelo fisioterapeuta.'
                    : '${quantity(plans.length, 'exercício ativo', 'exercícios ativos')}. Faça cada exercício conforme as orientações.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              ...plans.asMap().entries.map((entry) {
                final position = entry.key + 1;
                final plan = entry.value;
                final exercise = MockExercises.all.firstWhere(
                  (item) => item.type == plan.exerciseType,
                  orElse: () => MockExercises.elbowFlexion,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primarySoft,
                                foregroundColor: AppColors.primarySoftText,
                                child: Text('$position'),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Icon(
                                exercise.icon,
                                size: 32,
                                color: exercise.available
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  exercise.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            exercise.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            '${quantity(plan.sessionsPerWeek, 'vez', 'vezes')} por semana • ${quantity(plan.sets, 'série', 'séries')} de ${plan.targetRepetitions} repetições',
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text('Lado: ${_side(plan.trainingSide)}'),
                          if (plan.targetAmplitudeDegrees != null)
                            Text(
                              'Movimento esperado: ${plan.targetAmplitudeDegrees!.toStringAsFixed(0)}° (medida técnica)',
                            ),
                          if (plan.cadenceSeconds != null)
                            Text(
                              'Faça cada repetição em cerca de ${plan.cadenceSeconds!.toStringAsFixed(1)} segundos',
                            ),
                          Text('Intervalo: ${plan.restSeconds} segundos'),
                          if (plan.customDetectionEnabled) ...[
                            const SizedBox(height: AppSpacing.xs),
                            const Text(
                              'Análise de movimento adaptada pelo fisioterapeuta para este exercício.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                          if (plan.startDate != null || plan.endDate != null)
                            Text(
                              'Período: ${_date(plan.startDate)} até ${_date(plan.endDate)}',
                            ),
                          if (plan.instructions.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(plan.instructions),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          if (exercise.available)
                            ElevatedButton.icon(
                              key: Key(
                                plan.exerciseType == 'elbow_flexion'
                                    ? 'abrir_flexao_cotovelo'
                                    : 'abrir_${plan.exerciseType}',
                              ),
                              onPressed: () => Navigator.pushNamed(
                                context,
                                AppRoutes.exercise,
                                arguments: plan,
                              ),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Ver exercício'),
                            )
                          else
                            const Row(
                              children: [
                                Icon(Icons.schedule, size: 24),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(child: Text('Exercício indisponível')),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  static String _side(String value) => switch (value) {
    'left' => 'esquerdo',
    'right' => 'direito',
    'bilateral' => 'bilateral',
    _ => 'lado acometido',
  };

  static String _date(DateTime? value) => value == null
      ? 'não definido'
      : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
