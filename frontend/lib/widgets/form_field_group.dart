import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class FormFieldGroup extends StatelessWidget {
  const FormFieldGroup({
    required this.label,
    required this.child,
    this.helpText,
    super.key,
  });

  final String label;
  final String? helpText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleLarge),
        if (helpText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(helpText!, style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}
