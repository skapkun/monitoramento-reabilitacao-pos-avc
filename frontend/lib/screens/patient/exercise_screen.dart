import 'package:flutter/material.dart';

import '../../models/exercise.dart';
import '../../models/clinical_data.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/portuguese_text.dart';
import '../../widgets/app_page.dart';
import '../../widgets/status_banner.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({this.plan, super.key});

  final TherapyPlan? plan;

  @override
  Widget build(BuildContext context) {
    final exercise = MockExercises.all.firstWhere(
      (item) => item.type == plan?.exerciseType,
      orElse: () => MockExercises.elbowFlexion,
    );
    return AppPage(
      title: exercise.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 220),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(48),
                  ),
                  child: Icon(exercise.icon, size: 52, color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Guia visual de ${exercise.name.toLowerCase()}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Mantenha todo o movimento indicado visível para a câmera.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (plan != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'O que seu fisioterapeuta pediu',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${quantity(plan!.sets, 'série', 'séries')} de ${plan!.targetRepetitions} repetições • ${quantity(plan!.sessionsPerWeek, 'vez', 'vezes')} por semana',
                    ),
                    Text('Lado: ${_side(plan!.trainingSide)}'),
                    if (plan!.targetAmplitudeDegrees != null)
                      Text(
                        'Referência definida pelo fisioterapeuta: ${plan!.targetAmplitudeDegrees!.toStringAsFixed(0)}°. Não force o movimento para alcançar esse valor.',
                      ),
                    if (plan!.cadenceSeconds != null)
                      Text(
                        'Faça cada movimento devagar, em cerca de ${_seconds(plan!.cadenceSeconds!)}.',
                      ),
                    Text('Intervalo: ${plan!.restSeconds} segundos'),
                    if (plan!.customDetectionEnabled) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'A análise automática foi adaptada pelo seu fisioterapeuta.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                    if (plan!.instructions.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text('Orientação: ${plan!.instructions}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            'Como realizar',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          ...exercise.instructions.indexed.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    child: Text('${item.$1 + 1}'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const StatusBanner(
            icon: Icons.health_and_safety_outlined,
            title: 'Orientação importante',
            message:
                'Faça somente o exercício orientado pelo fisioterapeuta. Pare se sentir dor, tontura ou mal-estar.',
            backgroundColor: AppColors.warningBackground,
            foregroundColor: AppColors.warningText,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            key: const Key('continuar_preparacao'),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.preparation,
              arguments: plan,
            ),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continuar para preparação'),
          ),
        ],
      ),
    );
  }

  String _side(String value) => switch (value) {
    'left' => 'esquerdo',
    'right' => 'direito',
    'bilateral' => 'bilateral',
    _ => 'lado acometido',
  };

  String _seconds(double value) {
    final formatted = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1).replaceAll('.', ',');
    return '$formatted ${value == 1 ? 'segundo' : 'segundos'}';
  }
}
