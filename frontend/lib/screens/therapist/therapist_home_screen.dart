import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_repository.dart';
import '../../services/clinical_repository.dart';
import '../../models/clinical_data.dart';
import '../../models/patient_summary.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/portuguese_text.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/responsive_metric_grid.dart';
import '../../widgets/status_banner.dart';
import '../../widgets/role_navigation_bar.dart';
import 'patients_screen.dart';

class TherapistHomeScreen extends StatelessWidget {
  const TherapistHomeScreen({
    AuthRepository? authRepository,
    ClinicalRepository? clinicalRepository,
    super.key,
  }) : authRepository = authRepository ?? const DemoAuthRepository(),
       clinicalRepository =
           clinicalRepository ?? const DemoClinicalRepository();

  final AuthRepository authRepository;
  final ClinicalRepository clinicalRepository;

  Future<void> _signOut(BuildContext context) async {
    await authRepository.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel profissional'),
        actions: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            tooltip: 'Sair',
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Visão geral',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Veja prioridades e atividade recente.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            _DashboardOverview(repository: clinicalRepository),
            const SizedBox(height: AppSpacing.md),
            _MessageInbox(repository: clinicalRepository),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.analysisMethod),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Como as métricas são calculadas'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const RoleNavigationBar(
        role: AppNavigationRole.therapist,
      ),
    );
  }
}

class _MessageInbox extends StatelessWidget {
  const _MessageInbox({required this.repository});

  final ClinicalRepository repository;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<PatientSummary>>(
    stream: repository.watchLinkedPatients(),
    builder: (context, patientSnapshot) => StreamBuilder<List<CareMessage>>(
      stream: repository.watchAllMessages(),
      builder: (context, messageSnapshot) {
        if (patientSnapshot.hasError || messageSnapshot.hasError) {
          return const SizedBox.shrink();
        }
        if (!patientSnapshot.hasData || !messageSnapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: LinearProgressIndicator(),
            ),
          );
        }
        final patients = {
          for (final patient in patientSnapshot.data!) patient.id: patient,
        };
        final unread =
            messageSnapshot.data!
                .where(
                  (message) =>
                      message.senderRole == 'patient' &&
                      message.readAt == null &&
                      patients.containsKey(message.patientId),
                )
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Badge(
                      isLabelVisible: unread.isNotEmpty,
                      label: Text('${unread.length}'),
                      child: const Icon(
                        Icons.mark_unread_chat_alt_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Mensagens de pacientes',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (unread.isEmpty)
                  const Text('Nenhuma mensagem nova no momento.')
                else ...[
                  Text(
                    quantity(
                      unread.length,
                      'mensagem não lida',
                      'mensagens não lidas',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final message in unread.take(3))
                    _InboxMessage(
                      message: message,
                      patient: patients[message.patientId]!,
                    ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _InboxMessage extends StatelessWidget {
  const _InboxMessage({required this.message, required this.patient});

  final CareMessage message;
  final PatientSummary patient;

  @override
  Widget build(BuildContext context) => ListTile(
    key: Key('mensagem_pendente_${message.id}'),
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(child: Text(patient.initials)),
    title: Text(patient.name),
    subtitle: Text(message.text, maxLines: 2, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.pushNamed(
      context,
      AppRoutes.therapistMessages,
      arguments: patient,
    ),
  );
}

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview({required this.repository});

  final ClinicalRepository repository;

  @override
  Widget build(BuildContext context) => StreamBuilder<DashboardSummary>(
    stream: repository.watchDashboard(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const StatusBanner(
          icon: Icons.cloud_off_outlined,
          title: 'Não foi possível atualizar a visão geral',
          message:
              'Confira sua conexão. A lista de pacientes continua disponível para consulta.',
          backgroundColor: AppColors.errorBackground,
          foregroundColor: AppColors.errorText,
        );
      }
      final summary = snapshot.data;
      if (summary == null) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: AppSpacing.md),
                Expanded(child: Text('Atualizando a visão geral…')),
              ],
            ),
          ),
        );
      }
      final attention = summary.attentionPatients;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveMetricGrid(
            children: [
              MetricCard(
                label: 'Pacientes vinculados',
                value: '${summary.patients}',
                icon: Icons.groups_outlined,
                backgroundColor: AppColors.primarySoft,
                compact: true,
                actionHint: 'Abrir todos os pacientes',
                onTap: () => _openPatients(context, PatientFilter.all),
              ),
              MetricCard(
                label: 'Sessões esta semana',
                value: '${summary.sessions}',
                icon: Icons.event_available_outlined,
                color: AppColors.successSoftText,
                backgroundColor: AppColors.successSoft,
                compact: true,
                actionHint: 'Abrir pacientes com sessões registradas',
                onTap: () => _openPatients(context, PatientFilter.all),
              ),
              MetricCard(
                label: 'Precisam de atenção',
                value: '$attention',
                icon: Icons.visibility_outlined,
                color: AppColors.warningText,
                backgroundColor: AppColors.warningBackground,
                compact: true,
                actionHint: 'Abrir pacientes que precisam de atenção',
                onTap: () => _openPatients(context, PatientFilter.attention),
              ),
              MetricCard(
                label: 'Sem atividade recente',
                value: '${summary.inactivePatients}',
                icon: Icons.event_busy_outlined,
                color: AppColors.errorText,
                backgroundColor: AppColors.errorBackground,
                compact: true,
                actionHint: 'Abrir pacientes sem atividade recente',
                onTap: () => _openPatients(context, PatientFilter.inactive),
              ),
              MetricCard(
                label: 'Sessões para revisar',
                value: '${summary.requiresReview}',
                icon: Icons.rate_review_outlined,
                color: AppColors.warningText,
                backgroundColor: AppColors.warningBackground,
                compact: true,
                actionHint: 'Abrir pacientes com sessões para revisar',
                onTap: () => _openPatients(context, PatientFilter.review),
              ),
              MetricCard(
                label: 'Adesão registrada',
                value: '${summary.adherence}%',
                icon: Icons.trending_up,
                color: AppColors.accent,
                backgroundColor: AppColors.accentSoft,
                compact: true,
                actionHint: 'Abrir pacientes para consultar adesão',
                onTap: () => _openPatients(context, PatientFilter.all),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          StatusBanner(
            icon: attention > 0
                ? Icons.fact_check_outlined
                : Icons.check_circle_outline,
            title: attention > 0
                ? 'Prioridades de acompanhamento'
                : 'Sem alertas de acompanhamento',
            message: attention > 0
                ? '${quantity(attention, 'paciente tem', 'pacientes têm')} sinais operacionais para conferência. Abra Pacientes para ver os motivos. Esses alertas não são diagnósticos.'
                : 'Nenhum sinal operacional foi identificado agora. Continue o acompanhamento profissional habitual.',
            backgroundColor: attention > 0
                ? AppColors.warningBackground
                : AppColors.successSoft,
            foregroundColor: attention > 0
                ? AppColors.warningText
                : AppColors.successSoftText,
          ),
        ],
      );
    },
  );

  void _openPatients(BuildContext context, PatientFilter filter) {
    Navigator.pushNamed(context, AppRoutes.patients, arguments: filter);
  }
}
