import 'package:flutter/material.dart';

import '../../models/clinical_data.dart';
import '../../services/clinical_repository.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';
import '../../widgets/empty_state.dart';

class OrientationsScreen extends StatelessWidget {
  const OrientationsScreen({required this.repository, super.key});

  final ClinicalRepository repository;

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Orientações',
    child: StreamBuilder<List<ProfessionalNote>>(
      stream: repository.watchMyOrientations(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Não foi possível carregar as orientações.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final notes = snapshot.data!;
        if (notes.isEmpty) {
          return const EmptyState(
            title: 'Nenhuma orientação registrada',
            message:
                'As orientações compartilhadas pelo fisioterapeuta aparecerão aqui.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Orientações do fisioterapeuta',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            ...notes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    leading: const Icon(Icons.medical_services_outlined),
                    title: Text(note.text),
                    subtitle: Text(
                      '${note.createdAt.day.toString().padLeft(2, '0')}/${note.createdAt.month.toString().padLeft(2, '0')}/${note.createdAt.year}',
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
