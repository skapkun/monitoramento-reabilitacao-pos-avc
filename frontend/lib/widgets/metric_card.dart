import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.backgroundColor,
    this.compact = false,
    this.onTap,
    this.actionHint,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final bool compact;
  final VoidCallback? onTap;
  final String? actionHint;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: compact ? 24 : 28),
              if (compact) const SizedBox(width: AppSpacing.sm),
              if (compact)
                Expanded(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              if (compact && onTap != null)
                const Icon(Icons.chevron_right, size: 22),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
    return Semantics(
      label: '$label: $value',
      hint: actionHint,
      button: onTap != null,
      child: Card(
        color: backgroundColor,
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}
