import 'package:flutter/material.dart';

import '../../models/clinical_data.dart';
import '../../models/exercise.dart';
import '../../models/user_profile.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_repository.dart';
import '../../services/clinical_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/portuguese_text.dart';
import '../../widgets/role_navigation_bar.dart';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({
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

  Future<String?> _firstName() async {
    final profile = authRepository.isDemo
        ? MockUsers.patient
        : await authRepository.currentProfile();
    final name = profile?.name.trim();
    if (name == null || name.isEmpty) return null;
    return name.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
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
        child: Align(
          alignment: Alignment.topCenter,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              FutureBuilder<String?>(
                future: _firstName(),
                builder: (context, snapshot) => Text(
                  snapshot.data == null ? 'Olá!' : 'Olá, ${snapshot.data}',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Seu acompanhamento de hoje',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _MotivationalMessage(),
              if (clinicalRepository.isDemo) ...[
                const SizedBox(height: AppSpacing.md),
                const _DemoNotice(),
              ],
              const SizedBox(height: AppSpacing.lg),
              StreamBuilder<List<TherapyPlan>>(
                stream: clinicalRepository.watchMyPlan(),
                builder: (context, snapshot) {
                  final plans = snapshot.data ?? const <TherapyPlan>[];
                  return _TodayExerciseCard(
                    plan: plans.isEmpty ? null : plans.first,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              StreamBuilder<List<RehabilitationSession>>(
                stream: clinicalRepository.watchMySessions(),
                builder: (context, snapshot) => _ProgressSummary(
                  sessions: snapshot.data ?? const <RehabilitationSession>[],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Outras opções',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.patientProgress),
                    icon: const Icon(Icons.trending_up),
                    label: const Text('Evolução'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.patientOrientations,
                    ),
                    icon: const Icon(Icons.medical_services_outlined),
                    label: const Text('Orientações'),
                  ),
                  StreamBuilder<List<CareMessage>>(
                    stream: clinicalRepository.watchMessages(),
                    builder: (context, snapshot) {
                      final unread = (snapshot.data ?? const <CareMessage>[])
                          .where(
                            (message) =>
                                message.senderRole == 'therapist' &&
                                message.readAt == null,
                          )
                          .length;
                      return OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.patientMessages,
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
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const RoleNavigationBar(
        role: AppNavigationRole.patient,
      ),
    );
  }
}

class _MotivationalMessage extends StatelessWidget {
  const _MotivationalMessage();

  static const messages = [
    'Cada movimento conta. Faça no seu ritmo e respeite seus limites.',
    'Hoje, faça o que for confortável para você.',
    'Vá com calma. Cuidar do seu ritmo também faz parte.',
    'Um passo de cada vez, sempre com segurança.',
    'Concentre-se no movimento e respeite os sinais do seu corpo.',
    'Seu esforço de hoje merece ser reconhecido.',
  ];

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Mensagem de incentivo',
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite_outline, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              messages[DateTime.now().day % messages.length],
              key: const Key('mensagem_motivacional'),
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TodayExerciseCard extends StatelessWidget {
  const _TodayExerciseCard({required this.plan});

  final TherapyPlan? plan;

  @override
  Widget build(BuildContext context) {
    final currentPlan = plan;
    final exercise = currentPlan == null
        ? null
        : MockExercises.all.firstWhere(
            (item) => item.type == currentPlan.exerciseType,
            orElse: () => MockExercises.elbowFlexion,
          );
    return Semantics(
      container: true,
      label: currentPlan == null
          ? 'Nenhum exercício disponível hoje'
          : 'Exercício em destaque: ${exercise!.name}',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    exercise?.icon ?? Icons.event_busy_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exercício em destaque',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primarySoftText,
                        ),
                      ),
                      Text(
                        exercise?.name ?? 'Nenhum exercício atribuído',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (currentPlan != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                '${quantity(currentPlan.sessionsPerWeek, 'vez', 'vezes')} por semana • ${quantity(currentPlan.sets, 'série', 'séries')} de ${currentPlan.targetRepetitions}',
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                key: const Key('iniciar_exercicio_destaque'),
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.exercise,
                  arguments: currentPlan,
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar exercício'),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Quando seu fisioterapeuta atribuir um plano, ele aparecerá aqui.',
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.patientOrientations),
                icon: const Icon(Icons.help_outline),
                label: const Text('Ver orientações'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.sessions});

  final List<RehabilitationSession> sessions;

  @override
  Widget build(BuildContext context) {
    final completed = sessions
        .where((session) => session.status == 'completed')
        .length;
    final last = sessions.isEmpty ? null : sessions.first;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.insights_outlined,
            color: AppColors.successSoftText,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quantity(completed, 'sessão concluída', 'sessões concluídas'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.successSoftText,
                  ),
                ),
                Text(
                  last == null
                      ? 'Seu progresso aparecerá depois da primeira sessão.'
                      : 'Último registro: ${quantity(last.repetitions, 'repetição observada', 'repetições observadas')}.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.successSoftText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.accentSoft,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.science_outlined, color: AppColors.accent),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Dados simulados para demonstrar a navegação.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.accent),
          ),
        ),
      ],
    ),
  );
}
