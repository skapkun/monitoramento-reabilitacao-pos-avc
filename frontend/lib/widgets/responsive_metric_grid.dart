import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class ResponsiveMetricGrid extends StatelessWidget {
  const ResponsiveMetricGrid({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final useSingleColumn = textScale >= 1.5 || constraints.maxWidth < 340;
      final itemWidth = useSingleColumn
          ? constraints.maxWidth
          : (constraints.maxWidth - AppSpacing.md) / 2;
      return Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: children
            .map((child) => SizedBox(width: itemWidth, child: child))
            .toList(),
      );
    },
  );
}
