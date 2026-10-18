import 'package:flutter/material.dart';

import '../../models/clinical_data.dart';
import '../../models/patient_summary.dart';
import '../../services/clinical_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_banner.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({required this.repository, this.patient, super.key});

  final ClinicalRepository repository;
  final PatientSummary? patient;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final controller = TextEditingController();
  String category = 'general';
  bool sending = false;

  bool get isTherapist => widget.patient != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    try {
      await widget.repository.markConversationRead(
        patientId: widget.patient?.id,
      );
    } catch (_) {}
  }

  Future<void> _send() async {
    if (controller.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escreva uma mensagem antes de enviar.')),
      );
      return;
    }
    setState(() => sending = true);
    try {
      await widget.repository.sendMessage(
        patientId: widget.patient?.id,
        text: controller.text,
        category: category,
      );
      controller.clear();
      if (mounted) setState(() => category = 'general');
    } on ClinicalRepositoryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void _useQuickMessage(String value, String text) {
    setState(() {
      category = value;
      controller.text = text;
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: isTherapist ? 'Mensagens — ${widget.patient!.name}' : 'Mensagens',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StatusBanner(
          icon: Icons.info_outline,
          title: 'Canal não emergencial',
          message:
              'As mensagens podem não ser respondidas imediatamente. Em caso de urgência, procure o serviço de saúde indicado para sua região.',
          backgroundColor: AppColors.warningBackground,
          foregroundColor: AppColors.warningText,
        ),
        const SizedBox(height: AppSpacing.lg),
        StreamBuilder<List<CareMessage>>(
          stream: widget.repository.watchMessages(
            patientId: widget.patient?.id,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Não foi possível carregar as mensagens.');
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final messages = snapshot.data!;
            if (messages.isEmpty) {
              return const EmptyState(
                title: 'Nenhuma mensagem',
                message: 'Use o campo abaixo para iniciar a conversa.',
              );
            }
            return Column(
              children: [
                for (var index = 0; index < messages.length; index++)
                  _MessageBubble(
                    message: messages[index],
                    sentByCurrentUser:
                        messages[index].senderRole ==
                        (isTherapist ? 'therapist' : 'patient'),
                    answered: _wasAnswered(messages, index),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          isTherapist ? 'Responder' : 'Enviar uma dúvida',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (!isTherapist) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ActionChip(
                label: const Text('Senti dor'),
                onPressed: () => _useQuickMessage(
                  'discomfort',
                  'Senti dor ou desconforto durante o exercício. ',
                ),
              ),
              ActionChip(
                label: const Text('Não consegui fazer'),
                onPressed: () => _useQuickMessage(
                  'could_not_complete',
                  'Não consegui concluir o exercício. ',
                ),
              ),
              ActionChip(
                label: const Text('Dúvida sobre movimento'),
                onPressed: () => _useQuickMessage(
                  'movement_question',
                  'Tenho uma dúvida sobre como fazer o movimento. ',
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const Key('mensagem_texto'),
          controller: controller,
          minLines: 2,
          maxLines: 5,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: isTherapist ? 'Resposta' : 'Mensagem',
            hintText: isTherapist
                ? 'Escreva uma orientação clara'
                : 'Conte sua dúvida com suas palavras',
          ),
        ),
        ElevatedButton.icon(
          key: const Key('enviar_mensagem'),
          onPressed: sending ? null : _send,
          icon: sending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : const Icon(Icons.send_outlined),
          label: Text(sending ? 'Enviando…' : 'Enviar mensagem'),
        ),
      ],
    ),
  );

  bool _wasAnswered(List<CareMessage> messages, int index) {
    final current = messages[index];
    if (current.senderRole != 'patient') return false;
    return messages
        .skip(index + 1)
        .any((message) => message.senderRole == 'therapist');
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.sentByCurrentUser,
    required this.answered,
  });

  final CareMessage message;
  final bool sentByCurrentUser;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    final date = message.createdAt.toLocal();
    final status = answered
        ? 'Respondida'
        : message.readAt != null
        ? 'Visualizada'
        : 'Enviada';
    return Align(
      alignment: sentByCurrentUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: sentByCurrentUser ? AppColors.primarySoft : AppColors.surface,
          border: Border.all(
            color: sentByCurrentUser
                ? AppColors.primary
                : Theme.of(context).dividerColor,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.senderRole == 'patient' ? 'Paciente' : 'Fisioterapeuta',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(message.text),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} • $status',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
