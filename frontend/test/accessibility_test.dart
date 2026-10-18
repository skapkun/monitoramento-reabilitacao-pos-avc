import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movere_app/routes/app_routes.dart';
import 'package:movere_app/services/auth_repository.dart';
import 'package:movere_app/services/clinical_repository.dart';
import 'package:movere_app/theme/app_theme.dart';

void main() {
  const routes = <String>[
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
    AppRoutes.patientHome,
    AppRoutes.patientPlan,
    AppRoutes.exercise,
    AppRoutes.preparation,
    AppRoutes.recording,
    AppRoutes.processing,
    AppRoutes.result,
    AppRoutes.patientHistory,
    AppRoutes.patientProgress,
    AppRoutes.patientProfile,
    AppRoutes.patientOrientations,
    AppRoutes.patientMessages,
    AppRoutes.wellbeing,
    AppRoutes.therapistHome,
    AppRoutes.therapistProfile,
    AppRoutes.patients,
    AppRoutes.patientDetails,
    AppRoutes.therapistPlan,
    AppRoutes.sessions,
    AppRoutes.reports,
    AppRoutes.notes,
    AppRoutes.therapistMessages,
    AppRoutes.analysisMethod,
  ];

  for (final route in routes) {
    testWidgets('$route passa nas diretrizes automáticas visíveis', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          initialRoute: route,
          onGenerateRoute: (settings) => AppRoutes.onGenerateRoute(
            settings,
            authRepository: const DemoAuthRepository(),
            clinicalRepository: const DemoClinicalRepository(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('$route renderiza em telefone estreito com texto a 200%', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          initialRoute: route,
          onGenerateRoute: (settings) => AppRoutes.onGenerateRoute(
            settings,
            authRepository: const DemoAuthRepository(),
            clinicalRepository: const DemoClinicalRepository(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.byType(Scaffold), findsWidgets);
    });
  }

  for (final route in const [
    AppRoutes.patientProgress,
    AppRoutes.therapistHome,
    AppRoutes.patientDetails,
  ]) {
    testWidgets('$route mantém cartões sem overflow em largura mínima', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          initialRoute: route,
          onGenerateRoute: (settings) => AppRoutes.onGenerateRoute(
            settings,
            authRepository: const DemoAuthRepository(),
            clinicalRepository: const DemoClinicalRepository(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });
  }
}
