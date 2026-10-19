import 'package:flutter/material.dart';

import '../models/clinical_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SessionTrend extends StatelessWidget {
  const SessionTrend({required this.sessions, super.key});

  final List<RehabilitationSession> sessions;

  @override
  Widget build(BuildContext context) {
    final completed =
        sessions.where((session) => session.status == 'completed').toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final recent = completed.length <= 8
        ? completed
        : completed.sublist(completed.length - 8);
    if (completed.isEmpty) return const SizedBox.shrink();
    final amplitude = recent
        .where((session) => session.averageAmplitudeDegrees != null)
        .toList();
    final pain = recent.where((session) => session.painScore != null).toList();
    final fatigue = recent
        .where((session) => session.fatigueScore != null)
        .toList();
    final adherence = _weeklyAdherence(completed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricTrend(
          title: 'Repetições ao longo do tempo',
          description: 'Últimas ${recent.length} sessões concluídas',
          icon: Icons.repeat,
          maximum: recent
              .map((session) => session.repetitions.toDouble())
              .fold(1, (current, value) => value > current ? value : current),
          points: recent
              .map(
                (session) => _TrendPoint(
                  label: _date(session.createdAt),
                  value: session.repetitions.toDouble(),
                  display: '${session.repetitions}',
                ),
              )
              .toList(),
        ),
        if (amplitude.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _MetricTrend(
            title: 'Amplitude média observada',
            description: 'Somente exercícios com medida angular compatível',
            icon: Icons.open_in_full,
            maximum: 180,
            points: amplitude
                .map(
                  (session) => _TrendPoint(
                    label: _date(session.createdAt),
                    value: session.averageAmplitudeDegrees!,
                    display:
                        '${session.averageAmplitudeDegrees!.toStringAsFixed(0)}°',
                  ),
                )
                .toList(),
          ),
        ],
        if (adherence.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _MetricTrend(
            title: 'Adesão semanal registrada',
            description: 'Sessões realizadas em relação às previstas',
            icon: Icons.calendar_month_outlined,
            maximum: 100,
            points: adherence,
          ),
        ],
        if (pain.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _MetricTrend(
            title: 'Dor relatada após a sessão',
            description: 'Escala informada pelo paciente, de 0 a 10',
            icon: Icons.healing_outlined,
            maximum: 10,
            color: AppColors.warningText,
            backgroundColor: AppColors.warningBackground,
            points: pain
                .map(
                  (session) => _TrendPoint(
                    label: _date(session.createdAt),
                    value: session.painScore!.toDouble(),
                    display: '${session.painScore}/10',
                  ),
                )
                .toList(),
          ),
        ],
        if (fatigue.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _MetricTrend(
            title: 'Cansaço relatado após a sessão',
            description: 'Escala informada pelo paciente, de 0 a 10',
            icon: Icons.battery_3_bar_outlined,
            maximum: 10,
            color: AppColors.accent,
            backgroundColor: AppColors.accentSoft,
            points: fatigue
                .map(
                  (session) => _TrendPoint(
                    label: _date(session.createdAt),
                    value: session.fatigueScore!.toDouble(),
                    display: '${session.fatigueScore}/10',
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  static List<_TrendPoint> _weeklyAdherence(
    List<RehabilitationSession> sessions,
  ) {
    final withTarget = sessions
        .where((session) => session.prescribedSessionsPerWeek != null)
        .toList();
    if (withTarget.isEmpty) return const [];
    final latest = withTarget.last.createdAt;
    final latestDay = DateTime(latest.year, latest.month, latest.day);
    final currentWeekStart = latestDay.subtract(
      Duration(days: latestDay.weekday - DateTime.monday),
    );
    final points = <_TrendPoint>[];
    for (var offset = 3; offset >= 0; offset--) {
      final start = currentWeekStart.subtract(Duration(days: offset * 7));
      final end = start.add(const Duration(days: 7));
      final inWeek = withTarget
          .where(
            (session) =>
                !session.createdAt.isBefore(start) &&
                session.createdAt.isBefore(end),
          )
          .toList();
      if (inWeek.isEmpty && offset > 0) continue;
      final target = inWeek.isEmpty
          ? withTarget.last.prescribedSessionsPerWeek!
          : inWeek.last.prescribedSessionsPerWeek!;
      final actual = inWeek.length;
      final percentage = target == 0
          ? 0.0
          : ((actual / target) * 100).clamp(0, 100).toDouble();
      points.add(
        _TrendPoint(
          label:
              '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}',
          value: percentage,
          display: '$actual/$target',
        ),
      );
    }
    return points;
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
}

class _MetricTrend extends StatelessWidget {
  const _MetricTrend({
    required this.title,
    required this.description,
    required this.icon,
    required this.maximum,
    required this.points,
    this.color = AppColors.primary,
    this.backgroundColor = AppColors.primarySoft,
  });

  final String title;
  final String description;
  final IconData icon;
  final double maximum;
  final List<_TrendPoint> points;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: title,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
            for (final point in points)
              Semantics(
                label: '${point.label}: ${point.display}',
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      SizedBox(width: 48, child: Text(point.label)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: maximum <= 0
                              ? 0
                              : (point.value / maximum).clamp(0, 1),
                          minHeight: 18,
                          color: color,
                          backgroundColor: backgroundColor,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 48,
                        child: Text(point.display, textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _TrendPoint {
  const _TrendPoint({
    required this.label,
    required this.value,
    required this.display,
  });

  final String label;
  final double value;
  final String display;
}
