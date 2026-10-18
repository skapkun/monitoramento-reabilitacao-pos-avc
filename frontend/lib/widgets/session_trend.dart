import 'package:flutter/material.dart';

import '../models/clinical_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SessionTrend extends StatelessWidget {
  const SessionTrend({required this.sessions, super.key});

  final List<RehabilitationSession> sessions;

  @override
  Widget build(BuildContext context) {
    final completed = sessions
        .where((session) => session.status == 'completed')
        .take(8)
        .toList()
        .reversed
        .toList();
    if (completed.isEmpty) return const SizedBox.shrink();
    final maximum = completed
        .map((session) => session.repetitions)
        .fold<int>(1, (current, value) => value > current ? value : current);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tendência de repetições observadas',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...completed.indexed.map((entry) {
          final session = entry.$2;
          final date = session.createdAt;
          final label =
              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
          return Semantics(
            label: '$label: ${session.repetitions} repetições observadas',
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(width: 48, child: Text(label)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: session.repetitions / maximum,
                      minHeight: 18,
                      color: AppColors.primary,
                      backgroundColor: AppColors.primarySoft,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(width: 32, child: Text('${session.repetitions}')),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
