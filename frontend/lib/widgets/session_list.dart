import 'package:flutter/material.dart';

import '../models/clinical_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/portuguese_text.dart';
import 'empty_state.dart';

class SessionList extends StatelessWidget {
  const SessionList({
    required this.sessions,
    this.professionalView = false,
    this.onReview,
    this.onOpenVideo,
    super.key,
  });

  final List<RehabilitationSession> sessions;
  final bool professionalView;
  final Future<void> Function(RehabilitationSession session)? onReview;
  final Future<void> Function(RehabilitationSession session)? onOpenVideo;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const EmptyState(
        title: 'Nenhuma sessão registrada',
        message: 'As análises concluídas aparecerão aqui.',
      );
    }
    return Column(
      children: sessions.map((session) {
        final date = session.createdAt.toLocal();
        final dateLabel =
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        final successes = _successes(session);
        final concerns = _concerns(
          session,
          includeAutomaticEvents: professionalView,
        );
        final visibleEvents = professionalView
            ? session.movementEvents
            : _confirmedEventsForPatient(session);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  minVerticalPadding: AppSpacing.md,
                  leading: Icon(
                    session.requiresReview
                        ? Icons.rate_review_outlined
                        : Icons.event_available_outlined,
                    color: session.requiresReview
                        ? AppColors.warningText
                        : AppColors.primary,
                  ),
                  title: Text(_exercise(session.exerciseType)),
                  subtitle: Text(
                    '$dateLabel\n${quantity(session.repetitions, 'repetição', 'repetições')} • ${_status(session.status)}',
                  ),
                  isThreeLine: true,
                  trailing: onReview != null && session.requiresReview
                      ? IconButton(
                          tooltip: 'Marcar como revisada',
                          onPressed: () => onReview!(session),
                          icon: const Icon(Icons.task_alt),
                        )
                      : session.simulated
                      ? const Tooltip(
                          message: 'Dado simulado',
                          child: Icon(Icons.science_outlined),
                        )
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _SummaryChip(
                        icon: Icons.check_circle_outline,
                        label: quantity(successes.length, 'acerto', 'acertos'),
                        background: AppColors.successSoft,
                        foreground: AppColors.successSoftText,
                      ),
                      _SummaryChip(
                        icon: concerns.isEmpty
                            ? Icons.check_circle_outline
                            : Icons.visibility_outlined,
                        label: concerns.isEmpty
                            ? 'Nenhum ponto para conferir'
                            : '${quantity(concerns.length, 'ponto', 'pontos')} para conferir',
                        background: concerns.isEmpty
                            ? AppColors.surface
                            : AppColors.warningBackground,
                        foreground: concerns.isEmpty
                            ? AppColors.textSecondary
                            : AppColors.warningText,
                      ),
                    ],
                  ),
                ),
                if (successes.isNotEmpty || concerns.isNotEmpty)
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      childrenPadding: const EdgeInsets.only(
                        bottom: AppSpacing.xs,
                      ),
                      leading: const Icon(Icons.fact_check_outlined),
                      title: const Text('Ver detalhes da análise'),
                      subtitle: const Text('Acertos e pontos de atenção'),
                      children: [
                        if (successes.isNotEmpty)
                          _FindingPanel(
                            title: 'Acertos observados',
                            icon: Icons.thumb_up_alt_outlined,
                            items: successes,
                            background: AppColors.successSoft,
                            foreground: AppColors.successSoftText,
                          ),
                        if (concerns.isNotEmpty)
                          _FindingPanel(
                            title: 'Pontos para conferir',
                            icon: Icons.visibility_outlined,
                            items: concerns,
                            background: AppColors.warningBackground,
                            foreground: AppColors.warningText,
                          ),
                      ],
                    ),
                  ),
                if (session.customDetectionApplied)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Calibração individual aplicada: ${_threshold(session.detectionStartThreshold)} → ${_threshold(session.detectionChangeThreshold)} → ${_threshold(session.detectionStartThreshold)}. Motivo: ${session.calibrationReason ?? 'não informado'}.',
                      ),
                    ),
                  ),
                if (_hasPatientResponse(session))
                  _PatientResponsePanel(session: session),
                if (visibleEvents.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          professionalView
                              ? 'Momentos destacados automaticamente'
                              : 'Observações compartilhadas pelo fisioterapeuta',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          professionalView
                              ? 'Confira ${quantity(visibleEvents.length, 'marcação técnica', 'marcações técnicas')} antes de orientar o paciente.'
                              : '${quantity(visibleEvents.length, 'observação confirmada', 'observações confirmadas')} durante a revisão profissional.',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (final event in visibleEvents.take(3))
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.schedule_outlined,
                                  size: 20,
                                  color: AppColors.warningText,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    '${event.title} — ${_eventTime(event.startSeconds)}\n${event.description}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (visibleEvents.length > 3)
                          Text(
                            'Mais ${visibleEvents.length - 3} ${visibleEvents.length - 3 == 1 ? 'observação' : 'observações'}.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (onReview != null &&
                            session.eventReviews.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(_reviewSummary(session)),
                        ],
                      ],
                    ),
                  ),
                if ((onReview != null || session.reviewVisibleToPatient) &&
                    session.reviewComment?.trim().isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Comentário do fisioterapeuta: ${session.reviewComment}',
                      ),
                    ),
                  ),
                if ((session.hasEvidence || session.hasSharedVideo) &&
                    onOpenVideo != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: () => onOpenVideo!(session),
                      icon: Icon(
                        session.hasSharedVideo
                            ? Icons.play_circle_outline
                            : Icons.photo_library_outlined,
                      ),
                      label: Text(
                        session.hasSharedVideo
                            ? 'Assistir vídeo compartilhado'
                            : 'Ver capturas da análise',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  static String _status(String status) => switch (status) {
    'completed' => 'Concluída',
    'failed' => 'Falhou',
    'inconclusive' => 'Inconclusiva',
    _ => 'Em processamento',
  };

  static String _exercise(String type) => switch (type) {
    'squat' => 'Agachamento',
    'pinch' => 'Pinça',
    _ => 'Flexão de cotovelo',
  };

  static String _threshold(double? value) => value == null
      ? '—'
      : value < 1
      ? value.toStringAsFixed(2)
      : '${value.toStringAsFixed(0)}°';

  static String _eventTime(double seconds) {
    final totalSeconds = seconds.round().clamp(0, 359999);
    final minutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  static String _issueLabel(String code) => switch (code) {
    'insufficient_frames' => 'vídeo muito curto',
    'low_visibility' => 'pontos do corpo ou mão pouco visíveis',
    'no_complete_cycle' => 'nenhum ciclo completo observado',
    'technical_failure' => 'falha técnica de processamento',
    _ => 'análise inconclusiva',
  };

  static String _reviewSummary(RehabilitationSession session) {
    final confirmed = session.eventReviews.values
        .where((value) => value == 'confirmed')
        .length;
    final rejected = session.eventReviews.values
        .where((value) => value == 'not_confirmed')
        .length;
    final insufficient = session.eventReviews.values
        .where((value) => value == 'insufficient_video')
        .length;
    return 'Revisão dos alertas: ${quantity(confirmed, 'confirmado', 'confirmados')}, ${quantity(rejected, 'não confirmado', 'não confirmados')} e ${quantity(insufficient, 'com vídeo insuficiente', 'com vídeo insuficiente')}.';
  }

  static List<String> _successes(RehabilitationSession session) {
    final values = <String>[];
    if (session.status == 'completed') {
      values.add('Análise concluída com movimento detectado.');
    }
    final target = session.prescribedRepetitions;
    final sets = session.prescribedSets ?? 1;
    if (target != null && session.repetitions >= target * sets) {
      values.add('Meta de repetições alcançada.');
    }
    final targetAmplitude = session.prescribedAmplitudeDegrees;
    final amplitude = session.averageAmplitudeDegrees;
    if (targetAmplitude != null &&
        amplitude != null &&
        amplitude >= targetAmplitude) {
      values.add('Meta técnica de amplitude alcançada.');
    }
    if (session.movementEvents.isEmpty && session.status == 'completed') {
      values.add('Nenhum desvio técnico foi destacado automaticamente.');
    }
    return values;
  }

  static List<String> _concerns(
    RehabilitationSession session, {
    required bool includeAutomaticEvents,
  }) {
    final values = includeAutomaticEvents
        ? session.movementEvents.map((event) => event.title).toSet().toList()
        : <String>[];
    if (session.technicalIssueCode != null) {
      values.add(_issueLabel(session.technicalIssueCode!));
    }
    if (session.status == 'inconclusive' && values.isEmpty) {
      values.add('Análise inconclusiva; confira a qualidade do vídeo.');
    }
    return values;
  }

  static List<MovementEvent> _confirmedEventsForPatient(
    RehabilitationSession session,
  ) {
    if (!session.reviewVisibleToPatient) return const [];
    return session.movementEvents
        .where((event) => session.eventReviews[_eventKey(event)] == 'confirmed')
        .toList();
  }

  static String _eventKey(MovementEvent event) =>
      '${event.type}_${(event.startSeconds * 1000).round()}';

  static bool _hasPatientResponse(RehabilitationSession session) =>
      session.wellbeingScore != null ||
      session.painScore != null ||
      session.fatigueScore != null ||
      session.wellbeingNote?.trim().isNotEmpty == true;
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 280),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: foreground),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(label, style: TextStyle(color: foreground)),
        ),
      ],
    ),
  );
}

class _FindingPanel extends StatelessWidget {
  const _FindingPanel({
    required this.title,
    required this.icon,
    required this.items,
    required this.background,
    required this.foreground,
  });

  final String title;
  final IconData icon;
  final List<String> items;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      0,
      AppSpacing.md,
      AppSpacing.sm,
    ),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text('• $item', style: TextStyle(color: foreground)),
          ),
        ),
      ],
    ),
  );
}

class _PatientResponsePanel extends StatelessWidget {
  const _PatientResponsePanel({required this.session});

  final RehabilitationSession session;

  @override
  Widget build(BuildContext context) {
    final values = <String>[
      if (session.wellbeingScore != null)
        'Bem-estar ${session.wellbeingScore}/5',
      if (session.painScore != null) 'Dor ${session.painScore}/10',
      if (session.fatigueScore != null) 'Fadiga ${session.fatigueScore}/10',
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: AppColors.primarySoftText),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Como o paciente se sentiu',
                  style: TextStyle(
                    color: AppColors.primarySoftText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (values.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(values.join(' • ')),
          ],
          if (session.wellbeingNote?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('“${session.wellbeingNote!.trim()}”'),
          ],
        ],
      ),
    );
  }
}
