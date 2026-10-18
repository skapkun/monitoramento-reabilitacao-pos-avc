import 'package:flutter/material.dart';

import '../../models/patient_summary.dart';
import '../../models/clinical_data.dart';
import '../../routes/app_routes.dart';
import '../../services/clinical_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/portuguese_text.dart';
import '../../widgets/app_page.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/responsive_metric_grid.dart';
import '../../widgets/status_banner.dart';

class PatientDetailsScreen extends StatelessWidget {
  const PatientDetailsScreen({
    this.patient,
    ClinicalRepository? repository,
    super.key,
  }) : repository = repository ?? const DemoClinicalRepository();

  final PatientSummary? patient;
  final ClinicalRepository repository;

  @override
  Widget build(BuildContext context) {
    if (patient == null && !repository.isDemo) {
      return const AppPage(
        title: 'Perfil do paciente',
        child: Text('Selecione um paciente vinculado na lista de pacientes.'),
      );
    }
    final data = patient ?? MockPatients.all.first;
    return AppPage(
      title: 'Perfil do paciente',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: Text(
                  data.initials,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      'Última sessão: ${data.lastSession}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (data.participantContext == 'healthy_volunteer') ...[
            const StatusBanner(
              icon: Icons.science_outlined,
              title: 'Voluntário saudável — teste técnico',
              message:
                  'Use este perfil para avaliar funcionamento, repetibilidade e usabilidade. Não interprete os resultados como validação clínica pós-AVC.',
              backgroundColor: AppColors.warningBackground,
              foregroundColor: AppColors.warningText,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.therapistPlan,
                  arguments: data,
                ),
                icon: const Icon(Icons.assignment_outlined),
                label: const Text('Plano'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.sessions,
                  arguments: data,
                ),
                icon: const Icon(Icons.event_note_outlined),
                label: const Text('Sessões'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.notes,
                  arguments: data,
                ),
                icon: const Icon(Icons.edit_note_outlined),
                label: const Text('Observações'),
              ),
              StreamBuilder<List<CareMessage>>(
                stream: repository.watchMessages(patientId: data.id),
                builder: (context, snapshot) {
                  final unread = (snapshot.data ?? const <CareMessage>[])
                      .where(
                        (message) =>
                            message.senderRole == 'patient' &&
                            message.readAt == null,
                      )
                      .length;
                  return OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.therapistMessages,
                      arguments: data,
                    ),
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: const Icon(Icons.chat_bubble_outline),
                    ),
                    label: Text(
                      unread == 0
                          ? 'Mensagens'
                          : 'Mensagens (${quantity(unread, 'nova', 'novas')})',
                    ),
                  );
                },
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.reports,
                  arguments: data,
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Relatório'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ResponsiveMetricGrid(
            children: [
              MetricCard(
                label: 'Sessões',
                value: '${data.sessions}',
                icon: Icons.event_available_outlined,
              ),
              MetricCard(
                label: repository.isDemo
                    ? 'Adesão simulada'
                    : 'Adesão registrada',
                value: '${data.adherence}%',
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          StreamBuilder<List<RehabilitationSession>>(
            stream: repository.watchPatientSessions(data.id),
            builder: (context, snapshot) =>
                _LatestSessionHighlights(sessions: snapshot.data ?? const []),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (data.alerts.isNotEmpty) ...[
            Text(
              'Pontos para conferir',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Alertas calculados a partir dos registros do aplicativo. Eles ajudam a organizar o acompanhamento e não representam diagnóstico ou piora clínica.',
            ),
            const SizedBox(height: AppSpacing.md),
            ...data.alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: StatusBanner(
                  icon: _alertIcon(alert.type),
                  title: alert.title,
                  message: alert.message,
                  backgroundColor: AppColors.warningBackground,
                  foregroundColor: AppColors.warningText,
                ),
              ),
            ),
          ] else
            StatusBanner(
              icon: data.requiresReview
                  ? Icons.warning_amber
                  : Icons.check_circle_outline,
              title: data.status,
              message: data.requiresReview
                  ? 'Há uma sessão para avaliação profissional, sem classificação clínica automática.'
                  : repository.isDemo
                  ? 'Informação simulada para demonstrar o acompanhamento.'
                  : 'Nenhum sinal operacional foi identificado neste momento.',
              backgroundColor: data.requiresReview
                  ? AppColors.warningBackground
                  : AppColors.successSoft,
              foregroundColor: data.requiresReview
                  ? AppColors.warningText
                  : AppColors.successSoftText,
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Dados informados pelo paciente',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Informações descritivas para contextualizar o acompanhamento. Não representam diagnóstico nem avaliação clínica automática.',
          ),
          const SizedBox(height: AppSpacing.md),
          _PatientDataGroup(
            items: [
              _PatientDataItem(
                'Contexto do perfil',
                _participantContextLabel(data.participantContext),
                Icons.science_outlined,
              ),
              _PatientDataItem(
                'Faixa etária',
                _ageRangeLabel(data.ageRange),
                Icons.cake_outlined,
              ),
              if (data.participantContext != 'healthy_volunteer') ...[
                _PatientDataItem(
                  'Tempo desde o AVC',
                  data.monthsSinceStroke == null
                      ? 'Não informado'
                      : '${data.monthsSinceStroke} meses',
                  Icons.calendar_month_outlined,
                ),
                _PatientDataItem(
                  'Lado afetado',
                  _sideLabel(data.affectedSide),
                  Icons.accessibility_new,
                ),
              ],
              _PatientDataItem(
                data.participantContext == 'healthy_volunteer'
                    ? 'Lado dominante'
                    : 'Lado dominante antes do AVC',
                _dominantSideLabel(data.dominantSide),
                Icons.back_hand_outlined,
              ),
              if (data.participantContext != 'healthy_volunteer')
                _PatientDataItem(
                  'Tipo do AVC',
                  _strokeTypeLabel(data.strokeType),
                  Icons.medical_information_outlined,
                ),
              _PatientDataItem(
                'Mobilidade',
                _mobilityLabel(data.mobility),
                Icons.directions_walk,
              ),
              _PatientDataItem(
                'Apoio ou dispositivo auxiliar',
                _assistiveDeviceLabel(data.assistiveDevice),
                Icons.accessible_forward,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Resumo do plano',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          StreamBuilder<List<RehabilitationSession>>(
            stream: repository.watchPatientSessions(data.id),
            builder: (context, snapshot) => Card(
              child: ListTile(
                minVerticalPadding: AppSpacing.md,
                leading: const Icon(
                  Icons.event_available_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  quantity(
                    snapshot.data?.length ?? 0,
                    'sessão registrada',
                    'sessões registradas',
                  ),
                ),
                subtitle: const Text(
                  'Selecione Sessões para consultar os resultados.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sideLabel(String? value) => switch (value) {
    'left' => 'Esquerdo',
    'right' => 'Direito',
    'bilateral' => 'Ambos',
    _ => 'Não informado',
  };

  String _participantContextLabel(String value) => switch (value) {
    'post_stroke' => 'Acompanhamento pós-AVC',
    'healthy_volunteer' => 'Voluntário saudável — teste técnico',
    _ => 'Não informado',
  };

  String _strokeTypeLabel(String? value) => switch (value) {
    'ischemic' => 'Isquêmico',
    'hemorrhagic' => 'Hemorrágico',
    _ => 'Não informado',
  };

  String _dominantSideLabel(String? value) => switch (value) {
    'left' => 'Esquerdo',
    'right' => 'Direito',
    'ambidextrous' => 'Ambidestro',
    _ => 'Não informado',
  };

  String _mobilityLabel(String? value) => switch (value) {
    'independent' => 'Independente',
    'with_support' => 'Com apoio',
    'wheelchair' => 'Cadeira de rodas',
    _ => 'Não informado',
  };

  String _ageRangeLabel(String? value) => switch (value) {
    'under_40' => 'Menos de 40 anos',
    '40_49' => '40 a 49 anos',
    '50_59' => '50 a 59 anos',
    '60_69' => '60 a 69 anos',
    '70_79' => '70 a 79 anos',
    '80_plus' => '80 anos ou mais',
    _ => 'Não informado',
  };

  String _assistiveDeviceLabel(String? value) => switch (value) {
    'none' => 'Nenhum',
    'cane' => 'Bengala',
    'walker' => 'Andador',
    'wheelchair' => 'Cadeira de rodas',
    'other' => 'Outro',
    _ => 'Não informado',
  };

  IconData _alertIcon(PatientAlertType type) => switch (type) {
    PatientAlertType.noSessions => Icons.play_circle_outline,
    PatientAlertType.inactive => Icons.event_busy_outlined,
    PatientAlertType.lowAdherence => Icons.calendar_month_outlined,
    PatientAlertType.recurringDifficulty => Icons.help_outline,
    PatientAlertType.belowPrescription => Icons.assignment_late_outlined,
    PatientAlertType.highDiscomfort => Icons.health_and_safety_outlined,
    PatientAlertType.decliningTrend => Icons.trending_down,
  };
}

class _LatestSessionHighlights extends StatelessWidget {
  const _LatestSessionHighlights({required this.sessions});

  final List<RehabilitationSession> sessions;

  @override
  Widget build(BuildContext context) {
    final ordered = [...sessions]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latest = ordered.isEmpty ? null : ordered.first;
    final latestResponse = ordered.where(
      (session) =>
          session.wellbeingScore != null ||
          session.painScore != null ||
          session.fatigueScore != null ||
          session.wellbeingNote?.trim().isNotEmpty == true,
    );
    final response = latestResponse.isEmpty ? null : latestResponse.first;
    final positive = ordered
        .where(
          (session) => session.status == 'completed' && !session.requiresReview,
        )
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Resumo mais importante',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          color: AppColors.successSoft,
          child: ListTile(
            minVerticalPadding: AppSpacing.md,
            leading: const Icon(
              Icons.thumb_up_alt_outlined,
              color: AppColors.successSoftText,
            ),
            title: const Text('Sessões sem alerta pendente'),
            subtitle: Text(
              '$positive de ${ordered.length} ${agreement(ordered.length, 'registrada', 'registradas')}',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          color: response == null ? AppColors.surface : AppColors.primarySoft,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.primarySoftText,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Último relato do paciente',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (response == null)
                  const Text('Nenhum relato registrado até o momento.')
                else ...[
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (response.wellbeingScore != null)
                        Text('Bem-estar ${response.wellbeingScore}/5'),
                      if (response.painScore != null)
                        Text('Dor ${response.painScore}/10'),
                      if (response.fatigueScore != null)
                        Text('Fadiga ${response.fatigueScore}/10'),
                    ],
                  ),
                  if (response.wellbeingNote?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text('“${response.wellbeingNote!.trim()}”'),
                  ],
                ],
              ],
            ),
          ),
        ),
        if (latest?.requiresReview == true) ...[
          const SizedBox(height: AppSpacing.sm),
          const StatusBanner(
            icon: Icons.visibility_outlined,
            title: 'Sessão mais recente precisa de revisão',
            message:
                'Abra Sessões para comparar os acertos, os pontos de atenção e o relato do paciente.',
            backgroundColor: AppColors.warningBackground,
            foregroundColor: AppColors.warningText,
          ),
        ],
      ],
    );
  }
}

class _PatientDataItem {
  const _PatientDataItem(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _PatientDataGroup extends StatelessWidget {
  const _PatientDataGroup({required this.items});

  final List<_PatientDataItem> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final columns = constraints.maxWidth >= 340 && textScale <= 1.4 ? 2 : 1;
      final width = columns == 2
          ? (constraints.maxWidth - AppSpacing.sm) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: items
            .map(
              (item) => SizedBox(
                width: width,
                child: _PatientDataTile(item: item),
              ),
            )
            .toList(),
      );
    },
  );
}

class _PatientDataTile extends StatelessWidget {
  const _PatientDataTile({required this.item});

  final _PatientDataItem item;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(item.icon, color: AppColors.primary, size: 22),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                item.value,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
