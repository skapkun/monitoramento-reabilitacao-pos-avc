import 'package:flutter/material.dart';

import '../../models/clinical_data.dart';
import '../../services/clinical_repository.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';
import '../../widgets/session_list.dart';
import '../shared/session_video_screen.dart';
import '../shared/session_evidence_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.repository, super.key});

  final ClinicalRepository repository;

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
