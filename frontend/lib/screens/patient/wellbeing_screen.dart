import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/clinical_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';

class WellbeingScreen extends StatefulWidget {
  const WellbeingScreen({
    required this.repository,
    required this.sessionId,
    super.key,
  });

  final ClinicalRepository repository;
  final String sessionId;

  @override
  State<WellbeingScreen> createState() => _WellbeingScreenState();
}

class _WellbeingScreenState extends State<WellbeingScreen> {
  final noteController = TextEditingController();
  int score = 3;
  int painScore = 0;
  int fatigueScore = 0;
  bool saving = false;

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await widget.repository.saveWellbeing(
        sessionId: widget.sessionId,
        score: score,
        painScore: painScore,
        fatigueScore: fatigueScore,
        note: noteController.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.patientHome,
        (_) => false,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar sua resposta.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Como você está?',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Como você se sentiu após o exercício?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Esta resposta é subjetiva e será compartilhada com seu fisioterapeuta.',
        ),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          container: true,
          label: 'Bem-estar selecionado: ${_wellbeingOptions[score - 1].label}',
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _wellbeingOptions.indexed.map((entry) {
              final value = entry.$1 + 1;
              final option = entry.$2;
              final selected = score == value;
              return Semantics(
                selected: selected,
                button: true,
                label: '${option.label}, $value de 5',
                child: InkWell(
                  key: Key('bem_estar_$value'),
                  onTap: () => setState(() => score = value),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 96,
                      minHeight: 72,
                    ),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          option.icon,
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                          size: 32,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          option.label,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Dor ou desconforto após a sessão: $painScore de 10',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Slider(
          key: const Key('dor_pos_sessao'),
          value: painScore.toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          label: '$painScore',
          semanticFormatterCallback: (value) =>
              'Dor ou desconforto ${value.round()} de 10',
          onChanged: (value) => setState(() => painScore = value.round()),
        ),
        const Text('0 significa nenhuma dor; 10, a maior dor percebida.'),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Cansaço após a sessão: $fatigueScore de 10',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Slider(
          key: const Key('fadiga_pos_sessao'),
          value: fatigueScore.toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          label: '$fatigueScore',
          semanticFormatterCallback: (value) =>
              'Cansaço ${value.round()} de 10',
          onChanged: (value) => setState(() => fatigueScore = value.round()),
        ),
        const Text('0 significa nenhum cansaço; 10, o maior cansaço sentido.'),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: noteController,
          maxLength: 500,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Comentário opcional',
            hintText: 'Ex.: senti cansaço ou desconforto.',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          key: const Key('salvar_bem_estar'),
          onPressed: saving ? null : save,
          icon: const Icon(Icons.check),
          label: Text(saving ? 'Salvando…' : 'Concluir sessão'),
        ),
      ],
    ),
  );
}

const _wellbeingOptions = <({String label, IconData icon})>[
  (label: 'Muito mal', icon: Icons.sentiment_very_dissatisfied),
  (label: 'Mal', icon: Icons.sentiment_dissatisfied),
  (label: 'Regular', icon: Icons.sentiment_neutral),
  (label: 'Bem', icon: Icons.sentiment_satisfied),
  (label: 'Muito bem', icon: Icons.sentiment_very_satisfied),
];
