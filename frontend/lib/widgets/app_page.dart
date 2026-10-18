import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'role_navigation_bar.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    required this.title,
    required this.child,
    this.showBackButton = true,
    this.navigationRole,
    super.key,
  });

  final String title;
  final Widget child;
  final bool showBackButton;
  final AppNavigationRole? navigationRole;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '';
    final resolvedRole =
        navigationRole ??
        switch (route) {
          String value when value.startsWith('/paciente') =>
            AppNavigationRole.patient,
          String value when value.startsWith('/fisioterapeuta') =>
            AppNavigationRole.therapist,
          _ => null,
        };
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBackButton,
        title: Text(title),
      ),
      bottomNavigationBar: resolvedRole == null
          ? null
          : RoleNavigationBar(role: resolvedRole),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
