import 'package:flutter/material.dart';

import '../../models/clinical_data.dart';
import '../../services/clinical_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';
import '../../widgets/status_banner.dart';

class SessionEvidenceScreen extends StatefulWidget {
  const SessionEvidenceScreen({
    required this.repository,
    required this.session,
    required this.allowDelete,
    super.key,
  });

  final ClinicalRepository repository;
  final RehabilitationSession session;
  final bool allowDelete;

  @override
  State<SessionEvidenceScreen> createState() => _SessionEvidenceScreenState();
}

class _SessionEvidenceScreenState extends State<SessionEvidenceScreen> {
  bool deleting = false;

  Future<void> deleteEvidence() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir capturas?'),
        content: const Text(
          'As imagens serão removidas definitivamente. As métricas e o histórico da sessão serão mantidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir capturas'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => deleting = true);
    try {
      await widget.repository.deleteSessionEvidence(widget.session);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir as capturas.')),
      );
    }
  }

  String time(double seconds) {
    final value = Duration(milliseconds: (seconds * 1000).round());
    return '${value.inMinutes}:${value.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Capturas da análise',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StatusBanner(
          icon: Icons.lock_outline,
          title: 'Evidências privadas',
          message:
              'Estas imagens foram autorizadas pelo paciente. O vídeo original foi apagado e não está disponível.',
          backgroundColor: AppColors.primarySoft,
          foregroundColor: AppColors.primarySoftText,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final evidence in widget.session.evidence)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    image: true,
                    label: 'Captura da análise: ${evidence.title}',
                    child: Image.memory(
                      evidence.bytes,
                      height: 220,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          evidence.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Momento observado: ${time(evidence.timestampSeconds)}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (widget.allowDelete)
          OutlinedButton.icon(
            onPressed: deleting ? null : deleteEvidence,
            icon: const Icon(Icons.delete_outline),
            label: Text(deleting ? 'Excluindo…' : 'Excluir minhas capturas'),
          ),
      ],
    ),
  );
}
