import 'package:flutter/material.dart';

import '../../models/clinical_data.dart';
import '../../models/patient_summary.dart';
import '../../models/exercise.dart';
import '../../services/clinical_repository.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_colors.dart';
import '../../utils/portuguese_text.dart';
import '../../widgets/app_page.dart';
import '../../widgets/status_banner.dart';

class PlanManagementScreen extends StatefulWidget {
  const PlanManagementScreen({
    required this.repository,
    this.patient,
    super.key,
  });

  final ClinicalRepository repository;
  final PatientSummary? patient;

  @override
  State<PlanManagementScreen> createState() => _PlanManagementScreenState();
}

class _PlanManagementScreenState extends State<PlanManagementScreen> {
  final formKey = GlobalKey<FormState>();
  final instructions = TextEditingController(
    text: 'Execute devagar, mantendo o braço inteiro visível para a câmera.',
  );
  final repetitions = TextEditingController(text: '8');
  final sets = TextEditingController(text: '1');
  final amplitude = TextEditingController();
  final cadence = TextEditingController();
  final rest = TextEditingController(text: '60');
  final detectionStart = TextEditingController();
  final detectionChange = TextEditingController();
  final calibrationReason = TextEditingController();
  int sessionsPerWeek = 3;
  String exerciseType = 'elbow_flexion';
  String trainingSide = 'affected';
  DateTime? startDate;
  DateTime? endDate;
  bool active = true;
  bool saving = false;
  bool customDetectionEnabled = false;
  String? editingExerciseType;

  @override
  void dispose() {
    instructions.dispose();
    repetitions.dispose();
    sets.dispose();
    amplitude.dispose();
    cadence.dispose();
    rest.dispose();
    detectionStart.dispose();
    detectionChange.dispose();
    calibrationReason.dispose();
    super.dispose();
  }

  void loadPlan(TherapyPlan plan) {
    setState(() {
      editingExerciseType = plan.exerciseType;
      exerciseType = plan.exerciseType;
      sessionsPerWeek = plan.sessionsPerWeek;
      repetitions.text = '${plan.targetRepetitions}';
      sets.text = '${plan.sets}';
      amplitude.text = plan.targetAmplitudeDegrees?.toString() ?? '';
      cadence.text = plan.cadenceSeconds?.toString() ?? '';
      rest.text = '${plan.restSeconds}';
      instructions.text = plan.instructions;
      trainingSide = plan.trainingSide;
      startDate = plan.startDate;
      endDate = plan.endDate;
      active = plan.active;
      customDetectionEnabled = plan.customDetectionEnabled;
      detectionStart.text = plan.detectionStartThreshold?.toString() ?? '';
      detectionChange.text = plan.detectionChangeThreshold?.toString() ?? '';
      calibrationReason.text = plan.calibrationReason ?? '';
    });
  }

  void startNewExercise(List<TherapyPlan> plans) {
    final used = plans.map((plan) => plan.exerciseType).toSet();
    final available = MockExercises.all.where(
      (exercise) => !used.contains(exercise.type),
    );
    setState(() {
      editingExerciseType = null;
      exerciseType = available.isEmpty
          ? MockExercises.elbowFlexion.type
          : available.first.type;
      sessionsPerWeek = 3;
      repetitions.text = '8';
      sets.text = '1';
      amplitude.clear();
      cadence.clear();
      rest.text = '60';
      instructions.text =
          'Execute devagar, mantendo o movimento inteiro visível para a câmera.';
      trainingSide = 'affected';
      startDate = null;
      endDate = null;
      active = true;
      customDetectionEnabled = false;
      detectionStart.clear();
      detectionChange.clear();
      calibrationReason.clear();
    });
  }

  Future<void> save() async {
    final patient = widget.patient;
    if (patient == null || formKey.currentState?.validate() != true) return;
    if (startDate != null && endDate != null && endDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A data final deve ser posterior à inicial.'),
        ),
      );
      return;
    }
    setState(() => saving = true);
    try {
      final exercise = MockExercises.all.firstWhere(
        (item) => item.type == exerciseType,
      );
      await widget.repository.savePlan(
        TherapyPlan(
          patientId: patient.id,
          exerciseType: exercise.type,
          title: exercise.name,
          instructions: instructions.text.trim(),
          sessionsPerWeek: sessionsPerWeek,
          targetRepetitions: int.parse(repetitions.text),
          sets: int.parse(sets.text),
          targetAmplitudeDegrees: amplitude.text.trim().isEmpty
              ? null
              : double.parse(amplitude.text.replaceAll(',', '.')),
          trainingSide: trainingSide,
          cadenceSeconds: cadence.text.trim().isEmpty
              ? null
              : double.parse(cadence.text.replaceAll(',', '.')),
          restSeconds: int.parse(rest.text),
          customDetectionEnabled: customDetectionEnabled,
          detectionStartThreshold: customDetectionEnabled
              ? double.parse(detectionStart.text.replaceAll(',', '.'))
              : null,
          detectionChangeThreshold: customDetectionEnabled
              ? double.parse(detectionChange.text.replaceAll(',', '.'))
              : null,
          calibrationReason: customDetectionEnabled
              ? calibrationReason.text.trim()
              : null,
          startDate: startDate,
          endDate: endDate,
          active: active,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editingExerciseType == null
                  ? 'Exercício adicionado à rotina.'
                  : 'Exercício atualizado na rotina.',
            ),
          ),
        );
        setState(() => editingExerciseType = exercise.type);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar o plano.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    return AppPage(
      title: 'Plano de exercícios',
      child: patient == null
          ? const Text(
              'Selecione um paciente na lista antes de editar o plano.',
            )
          : StreamBuilder<List<TherapyPlan>>(
              stream: widget.repository.watchPatientPlans(patient.id),
              builder: (context, snapshot) {
                final plans = snapshot.data ?? const <TherapyPlan>[];
                return Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        patient.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      if (patient.participantContext ==
                          'healthy_volunteer') ...[
                        const SizedBox(height: AppSpacing.md),
                        const StatusBanner(
                          icon: Icons.science_outlined,
                          title: 'Plano para teste técnico',
                          message:
                              'Escolha esquerdo, direito ou bilateral. Não use “lado acometido” para um voluntário saudável.',
                          backgroundColor: AppColors.warningBackground,
                          foregroundColor: AppColors.warningText,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Rotina do paciente',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        plans.isEmpty
                            ? 'Nenhum exercício foi adicionado.'
                            : '${quantity(plans.length, 'exercício configurado', 'exercícios configurados')}. Cada um pode ter metas próprias.',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (plans.isNotEmpty) ...[
                        ...plans.asMap().entries.map(
                          (entry) => Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${entry.key + 1}'),
                              ),
                              title: Text(entry.value.title),
                              subtitle: Text(
                                '${entry.value.sessionsPerWeek}x por semana • ${quantity(entry.value.sets, 'série', 'séries')} de ${entry.value.targetRepetitions}\n${entry.value.active ? 'Ativo' : 'Pausado'} • versão ${entry.value.version}${entry.value.customDetectionEnabled ? ' • calibração individual' : ''}',
                              ),
                              isThreeLine: true,
                              trailing: TextButton(
                                onPressed: () => loadPlan(entry.value),
                                child: const Text('Editar'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      OutlinedButton.icon(
                        key: const Key('adicionar_exercicio_rotina'),
                        onPressed: () => startNewExercise(plans),
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar outro exercício'),
                      ),
                      const Divider(height: AppSpacing.xl),
                      Text(
                        editingExerciseType == null
                            ? 'Novo exercício'
                            : 'Editar exercício',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (editingExerciseType != null)
                        Text(
                          'Você está alterando esta prescrição. Para incluir outro exercício, use o botão acima.',
                        ),
                      if (editingExerciseType != null)
                        const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        key: ValueKey('exercise_$exerciseType'),
                        isExpanded: true,
                        initialValue: exerciseType,
                        decoration: const InputDecoration(
                          labelText: 'Exercício',
                        ),
                        items: MockExercises.all
                            .map(
                              (exercise) => DropdownMenuItem(
                                value: exercise.type,
                                child: Text(exercise.name),
                              ),
                            )
                            .toList(),
                        onChanged: editingExerciseType != null
                            ? null
                            : (value) => setState(() {
                                exerciseType = value ?? 'elbow_flexion';
                                if (exerciseType == 'pinch') amplitude.clear();
                                if (customDetectionEnabled) {
                                  _setDefaultCalibration();
                                }
                              }),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<int>(
                        key: ValueKey('frequency_$sessionsPerWeek'),
                        isExpanded: true,
                        initialValue: sessionsPerWeek,
                        decoration: const InputDecoration(
                          labelText: 'Sessões por semana',
                        ),
                        items: [1, 2, 3, 4, 5, 6, 7]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text('$value'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => sessionsPerWeek = value ?? 3),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        key: const Key('prescricao_series'),
                        controller: sets,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Séries'),
                        validator: (value) => _integer(value, 1, 10),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        key: const Key('prescricao_repeticoes'),
                        controller: repetitions,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Repetições por série',
                        ),
                        validator: (value) => _integer(value, 1, 100),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (exerciseType != 'pinch') ...[
                        TextFormField(
                          key: const Key('prescricao_amplitude'),
                          controller: amplitude,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Meta de amplitude (graus, opcional)',
                            helperText:
                                'Meta individual; não altera os limiares do algoritmo.',
                          ),
                          validator: (value) => _decimal(value, 1, 180),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ] else ...[
                        const Text(
                          'A pinça usa distância normalizada da imagem; não é definida uma meta clínica em graus.',
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      SwitchListTile(
                        key: const Key('calibracao_deteccao'),
                        contentPadding: EdgeInsets.zero,
                        value: customDetectionEnabled,
                        onChanged: (value) => setState(() {
                          customDetectionEnabled = value;
                          if (value) _setDefaultCalibration();
                        }),
                        title: const Text('Calibração individual da detecção'),
                        subtitle: const Text(
                          'Experimental. Altera a contagem automática, não a meta clínica.',
                        ),
                      ),
                      if (customDetectionEnabled) ...[
                        const StatusBanner(
                          icon: Icons.tune,
                          title: 'Ajuste técnico rastreável',
                          message:
                              'Use somente após observar o movimento possível do paciente. Os valores serão registrados com a sessão e podem ser restaurados ao padrão.',
                          backgroundColor: AppColors.primarySoft,
                          foregroundColor: AppColors.primarySoftText,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          key: const Key('limiar_inicio'),
                          controller: detectionStart,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: exerciseType == 'pinch'
                                ? 'Abertura para iniciar/retornar'
                                : 'Ângulo para iniciar/retornar',
                            suffixText: exerciseType == 'pinch' ? null : '°',
                          ),
                          validator: _calibrationStartValidator,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          key: const Key('limiar_mudanca'),
                          controller: detectionChange,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: exerciseType == 'pinch'
                                ? 'Fechamento para reconhecer a pinça'
                                : 'Ângulo de flexão/descida',
                            suffixText: exerciseType == 'pinch' ? null : '°',
                          ),
                          validator: _calibrationChangeValidator,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          key: const Key('justificativa_calibracao'),
                          controller: calibrationReason,
                          maxLength: 300,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Justificativa profissional',
                            hintText:
                                'Ex.: faixa observada em tentativa supervisionada.',
                          ),
                          validator: (value) {
                            final length = value?.trim().length ?? 0;
                            if (length < 10) {
                              return 'Explique o ajuste em pelo menos 10 caracteres.';
                            }
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(_setDefaultCalibration),
                            icon: const Icon(Icons.restore),
                            label: const Text('Restaurar valores padrão'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      DropdownButtonFormField<String>(
                        key: ValueKey('side_$trainingSide'),
                        initialValue: trainingSide,
                        decoration: const InputDecoration(
                          labelText: 'Lado trabalhado',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'affected',
                            child: Text('Lado acometido'),
                          ),
                          DropdownMenuItem(
                            value: 'left',
                            child: Text('Esquerdo'),
                          ),
                          DropdownMenuItem(
                            value: 'right',
                            child: Text('Direito'),
                          ),
                          DropdownMenuItem(
                            value: 'bilateral',
                            child: Text('Bilateral'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => trainingSide = value ?? 'affected'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: cadence,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Segundos por repetição',
                          hintText: 'Opcional',
                        ),
                        validator: (value) => _decimal(value, 1, 30),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: rest,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Intervalo (segundos)',
                        ),
                        validator: (value) => _integer(value, 0, 600),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => pickDate(isStart: true),
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text('Início: ${_date(startDate)}'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => pickDate(isStart: false),
                            icon: const Icon(Icons.event_outlined),
                            label: Text('Término: ${_date(endDate)}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: instructions,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Orientações ao paciente',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: active,
                        onChanged: (value) => setState(() => active = value),
                        title: const Text('Prescrição ativa'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton.icon(
                        onPressed: saving ? null : save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          saving
                              ? 'Salvando…'
                              : editingExerciseType == null
                              ? 'Adicionar à rotina'
                              : 'Salvar alterações',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> pickDate({required bool isStart}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: (isStart ? startDate : endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isStart) {
        startDate = selected;
      } else {
        endDate = selected;
      }
    });
  }

  String _date(DateTime? value) => value == null
      ? 'não definido'
      : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String? _integer(String? value, int minimum, int maximum) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed < minimum || parsed > maximum) {
      return 'Use um valor de $minimum a $maximum.';
    }
    return null;
  }

  String? _decimal(String? value, double minimum, double maximum) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || parsed < minimum || parsed > maximum) {
      return 'Use um valor de ${minimum.toInt()} a ${maximum.toInt()}.';
    }
    return null;
  }

  void _setDefaultCalibration() {
    if (exerciseType == 'pinch') {
      detectionStart.text = '0.10';
      detectionChange.text = '0.05';
    } else if (exerciseType == 'squat') {
      detectionStart.text = '160';
      detectionChange.text = '100';
    } else {
      detectionStart.text = '160';
      detectionChange.text = '90';
    }
  }

  String? _calibrationStartValidator(String? value) {
    if (!customDetectionEnabled) return null;
    final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
    final minimum = exerciseType == 'pinch' ? 0.06 : 120.0;
    final maximum = exerciseType == 'pinch' ? 0.20 : 175.0;
    if (parsed == null || parsed < minimum || parsed > maximum) {
      return exerciseType == 'pinch'
          ? 'Use um valor entre 0,06 e 0,20.'
          : 'Use um ângulo entre 120° e 175°.';
    }
    return _calibrationGapError();
  }

  String? _calibrationChangeValidator(String? value) {
    if (!customDetectionEnabled) return null;
    final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
    final minimum = exerciseType == 'pinch' ? 0.01 : 40.0;
    final maximum = exerciseType == 'pinch' ? 0.09 : 140.0;
    if (parsed == null || parsed < minimum || parsed > maximum) {
      return exerciseType == 'pinch'
          ? 'Use um valor entre 0,01 e 0,09.'
          : 'Use um ângulo entre 40° e 140°.';
    }
    return _calibrationGapError();
  }

  String? _calibrationGapError() {
    final start = double.tryParse(detectionStart.text.replaceAll(',', '.'));
    final change = double.tryParse(detectionChange.text.replaceAll(',', '.'));
    if (start == null || change == null) return null;
    final minimumGap = exerciseType == 'pinch' ? 0.02 : 20.0;
    if (start - change < minimumGap) {
      return exerciseType == 'pinch'
          ? 'Mantenha diferença mínima de 0,02.'
          : 'Mantenha diferença mínima de 20°.';
    }
    return null;
  }
}
