import 'package:flutter/material.dart';

import '../../models/clinical_data.dart';
import '../../models/patient_summary.dart';
import '../../services/clinical_repository.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';
import '../../widgets/session_list.dart';
import '../../widgets/session_trend.dart';
import '../shared/session_video_screen.dart';
import '../shared/session_evidence_screen.dart';

class TherapistSessionsScreen extends StatelessWidget {
  const TherapistSessionsScreen({
    required this.repository,
    this.patient,
    super.key,
  });

  final ClinicalRepository repository;
  final PatientSummary? patient;

  Future<void> _review(
    BuildContext context,
    RehabilitationSession session,
  ) async {
    var rating = 3;
    var conduct = 'maintain_training';
    var visibleToPatient = false;
    final commentController = TextEditingController(
      text: session.reviewComment ?? '',
    );
    final eventReviews = <String, String>{...session.eventReviews};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Avaliar sessão'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Avaliação profissional'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      tooltip: '${index + 1} de 5',
                      onPressed: () => setDialogState(() => rating = index + 1),
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: conduct,
                  decoration: const InputDecoration(labelText: 'Conduta'),
                  items: const [
                    DropdownMenuItem(
                      value: 'maintain_training',
                      child: Text('Manter treino'),
                    ),
                    DropdownMenuItem(
                      value: 'adjust_load',
                      child: Text('Ajustar carga'),
                    ),
                    DropdownMenuItem(
                      value: 'schedule_reassessment',
                      child: Text('Agendar reavaliação'),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => conduct = value ?? conduct),
                ),
                if (session.movementEvents.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Revisar alertas do vídeo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...session.movementEvents.map((event) {
                    final key = _eventKey(event);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: eventReviews[key] ?? 'pending',
                        decoration: InputDecoration(
                          labelText: event.title,
                          helperText:
                              'Momento ${_time(event.startSeconds)} • resultado experimental',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Ainda não revisado'),
                          ),
                          DropdownMenuItem(
                            value: 'confirmed',
                            child: Text('Observação confirmada'),
                          ),
                          DropdownMenuItem(
                            value: 'not_confirmed',
                            child: Text('Observação não confirmada'),
                          ),
                          DropdownMenuItem(
                            value: 'insufficient_video',
                            child: Text('Vídeo insuficiente'),
                          ),
                        ],
                        onChanged: (value) => setDialogState(
                          () => eventReviews[key] = value ?? 'pending',
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: commentController,
                  maxLength: 1000,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Comentário da revisão',
                    hintText:
                        'Registre o que observou e a orientação proposta.',
                  ),
                ),
                CheckboxListTile(
                  value: visibleToPatient,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Mostrar comentário ao paciente'),
                  subtitle: const Text(
                    'As decisões técnicas sobre os alertas continuam visíveis apenas ao profissional.',
                  ),
                  onChanged: (value) =>
                      setDialogState(() => visibleToPatient = value ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Salvar avaliação'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) {
      commentController.dispose();
      return;
    }
    try {
      await repository.reviewSession(
        sessionId: session.id,
        rating: rating,
        conduct: conduct,
        eventReviews: eventReviews,
        comment: commentController.text,
        visibleToPatient: visibleToPatient,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avaliação profissional salva.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível avaliar a sessão.')),
        );
      }
    } finally {
      commentController.dispose();
    }
  }

  String _eventKey(MovementEvent event) =>
      '${event.type}_${(event.startSeconds * 1000).round()}';

  String _time(double seconds) {
    final duration = Duration(milliseconds: (seconds * 1000).round());
    return '${duration.inMinutes}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final selected = patient;
    return AppPage(
      title: 'Sessões',
      child: selected == null
          ? const Text(
              'Selecione um paciente na lista para consultar as sessões.',
            )
          : StreamBuilder<List<RehabilitationSession>>(
              stream: repository.watchPatientSessions(selected.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Não foi possível carregar as sessões.');
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      selected.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SessionTrend(sessions: snapshot.data!),
                    const SizedBox(height: AppSpacing.lg),
                    SessionList(
                      sessions: snapshot.data!,
                      professionalView: true,
                      onReview: (session) => _review(context, session),
                      onOpenVideo: (session) async {
                        await Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => session.hasSharedVideo
                                ? SessionVideoScreen(
                                    repository: repository,
                                    session: session,
                                    allowDelete: false,
                                  )
                                : SessionEvidenceScreen(
                                    repository: repository,
                                    session: session,
                                    allowDelete: false,
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}
