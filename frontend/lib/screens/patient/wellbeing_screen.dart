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
        Text(
          'Avaliação geral da sessão',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text('Escolha de 1 a 5 estrelas.'),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          container: true,
          label: 'Avaliação selecionada: $score de 5 estrelas',
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return IconButton(
                    key: Key('bem_estar_$value'),
                    tooltip: '$value de 5 estrelas',
                    iconSize: 40,
                    onPressed: () => setState(() => score = value),
                    icon: Icon(
                      value <= score ? Icons.star : Icons.star_border,
                      color: AppColors.accent,
                    ),
                  );
                }),
              ),
              Text(
                '$score de 5 — ${_wellbeingLabels[score - 1]}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Dor ou desconforto percebido: $painScore de 10',
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
          'Cansaço percebido: $fatigueScore de 10',
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

const _wellbeingLabels = <String>[
  'Muito ruim',
  'Ruim',
  'Regular',
  'Boa',
  'Muito boa',
];
