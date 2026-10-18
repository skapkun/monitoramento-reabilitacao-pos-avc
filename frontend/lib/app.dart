import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'models/user_profile.dart';
import 'routes/app_routes.dart';
import 'services/auth_repository.dart';
import 'services/clinical_repository.dart';
import 'services/firebase_auth_repository.dart';
import 'theme/app_theme.dart';

class MovereApp extends StatelessWidget {
  const MovereApp({
    AuthRepository? authRepository,
    ClinicalRepository? clinicalRepository,
    super.key,
  }) : authRepository = authRepository ?? const DemoAuthRepository(),
       clinicalRepository =
           clinicalRepository ?? const DemoClinicalRepository();

  final AuthRepository authRepository;
  final ClinicalRepository clinicalRepository;

  @override
  Widget build(BuildContext context) {
    final preferences = authRepository is FirebaseAuthRepository
        ? (authRepository as FirebaseAuthRepository).accessibilityPreferences
        : const _FixedPreferences();
    return ValueListenableBuilder<AccessibilityPreferences>(
      valueListenable: preferences,
      builder: (context, value, _) => MaterialApp(
        title: 'Movere',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.login,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          final textScaler = media.textScaler.clamp(
            minScaleFactor: value.largerText ? 1.15 : 1,
          );
          return MediaQuery(
            data: media.copyWith(
              textScaler: textScaler,
              disableAnimations: value.reducedMotion,
              accessibleNavigation: value.reducedMotion,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        onGenerateRoute: (settings) => AppRoutes.onGenerateRoute(
          settings,
          authRepository: authRepository,
          clinicalRepository: clinicalRepository,
        ),
      ),
    );
  }
}

class _FixedPreferences implements ValueListenable<AccessibilityPreferences> {
  const _FixedPreferences();

  @override
  AccessibilityPreferences get value => const AccessibilityPreferences();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
