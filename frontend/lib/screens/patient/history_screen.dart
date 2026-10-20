import 'package:flutter/material.dart';

import '../../models/clinical_data.dart';
import '../../models/user_profile.dart';
import '../../services/auth_repository.dart';
import '../../services/clinical_repository.dart';
import '../../services/report_api_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';
import '../../widgets/session_list.dart';
import '../shared/pdf_preview_screen.dart';
import '../shared/session_video_screen.dart';
import '../shared/session_evidence_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    required this.repository,
    this.authRepository = const DemoAuthRepository(),
    super.key,
  });

  final ClinicalRepository repository;
  final AuthRepository authRepository;

  Future<void> _exportSession(
    BuildContext context,
    RehabilitationSession session,
  ) async {
    final service = ReportApiService();
    try {
      final profile = authRepository.isDemo
          ? MockUsers.patient
          : await authRepository.currentProfile();
      final bytes = await service.generateSession(
        patientId: session.patientId,
        patientName: profile?.name.trim().isNotEmpty == true
            ? profile!.name.trim()
            : 'Paciente',
        session: session,
      );
      if (!context.mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            title: 'Relatório da sessão',
            filename: 'movere-sessao-${session.id}.pdf',
            bytes: bytes,
          ),
        ),
      );
    } on ReportApiException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o PDF.')),
      );
    } finally {
      service.close();
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Histórico',
    child: StreamBuilder<List<RehabilitationSession>>(
      stream: repository.watchMySessions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Não foi possível carregar o histórico.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sessões realizadas',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            SessionList(
              sessions: snapshot.data!,
              onExportPdf: (session) => _exportSession(context, session),
              onOpenVideo: (session) async {
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => session.hasSharedVideo
                        ? SessionVideoScreen(
                            repository: repository,
                            session: session,
                            allowDelete: true,
                          )
                        : SessionEvidenceScreen(
                            repository: repository,
                            session: session,
                            allowDelete: true,
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
