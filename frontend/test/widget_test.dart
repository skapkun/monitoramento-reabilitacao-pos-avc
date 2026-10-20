import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movere_app/app.dart';
import 'package:movere_app/routes/app_routes.dart';
import 'package:movere_app/screens/patient/processing_screen.dart';
import 'package:movere_app/screens/patient/result_screen.dart';

Future<void> enterDemo(WidgetTester tester, Key buttonKey) async {
  await scrollTo(tester, find.byKey(buttonKey), 350);
  await tester.tap(find.byKey(buttonKey));
  await tester.pumpAndSettle();
}

Future<void> scrollTo(WidgetTester tester, Finder finder, double delta) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
}

Future<void> expectAccessibleScreen(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  testWidgets('login atende às diretrizes automatizadas de acessibilidade', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MovereApp());

    await expectAccessibleScreen(tester);

    semantics.dispose();
  });

  testWidgets('preserva ampliação de texto configurada no sistema', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const MovereApp());

    final context = tester.element(find.text('Movere'));
    expect(MediaQuery.textScalerOf(context).scale(16), 32);
    expect(tester.takeException(), isNull);
  });

  testWidgets('telas principais do paciente atendem auditoria automática', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MovereApp());
    await enterDemo(tester, const Key('entrar_paciente'));
    await expectAccessibleScreen(tester);

    await tester.tap(find.text('Rotina'));
    await tester.pumpAndSettle();
    await expectAccessibleScreen(tester);
    semantics.dispose();
  });

  testWidgets('painel profissional atende auditoria automática', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MovereApp());
    await enterDemo(tester, const Key('entrar_fisioterapeuta'));
    await expectAccessibleScreen(tester);
    semantics.dispose();
  });

  testWidgets('painel do paciente não corta conteúdo com texto a 200%', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const MovereApp());
    await enterDemo(tester, const Key('entrar_paciente'));

    expect(tester.takeException(), isNull);
    expect(find.text('Rotina'), findsOneWidget);
  });

  testWidgets('painel profissional não corta conteúdo com texto a 200%', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const MovereApp());
    await enterDemo(tester, const Key('entrar_fisioterapeuta'));

    expect(tester.takeException(), isNull);
    expect(find.text('Pacientes vinculados'), findsOneWidget);
  });

  testWidgets('abre o login e entra como paciente', (tester) async {
    await tester.pumpWidget(const MovereApp());

    expect(find.text('Movere'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar uma conta'), findsOneWidget);

    await enterDemo(tester, const Key('entrar_paciente'));

    expect(find.text('Olá, Maria'), findsOneWidget);
    expect(find.text('Olá, paciente'), findsNothing);
    expect(find.byKey(const Key('mensagem_motivacional')), findsOneWidget);
    expect(find.text('Rotina'), findsOneWidget);
  });

  testWidgets('valida os campos obrigatórios do login', (tester) async {
    await tester.pumpWidget(const MovereApp());
    await scrollTo(tester, find.byKey(const Key('entrar')), 250);
    await tester.tap(find.byKey(const Key('entrar')));
    await tester.pump();

    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
  });

  testWidgets('simula recuperação de senha', (tester) async {
    await tester.pumpWidget(const MovereApp());
    await scrollTo(tester, find.text('Esqueci minha senha'), 250);
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('recuperacao_email')),
      'usuario@exemplo.com',
    );
    await tester.tap(find.byKey(const Key('enviar_recuperacao')));
    await tester.pump();

    expect(find.text('Orientação simulada enviada'), findsOneWidget);
  });

  testWidgets('valida o formulário de cadastro', (tester) async {
    await tester.pumpWidget(const MovereApp());
    await scrollTo(tester, find.text('Criar uma conta'), 250);
    await tester.tap(find.text('Criar uma conta'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const Key('concluir_cadastro')), 400);
    await tester.tap(find.byKey(const Key('concluir_cadastro')));
    await tester.pump();

    expect(find.text('Informe seu nome completo.'), findsOneWidget);
    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(
      find.text('A senha deve ter pelo menos 6 caracteres.'),
      findsOneWidget,
    );
  });

  testWidgets('conclui o cadastro simulado com dados válidos', (tester) async {
    await tester.pumpWidget(const MovereApp());
    await scrollTo(tester, find.text('Criar uma conta'), 250);
    await tester.tap(find.text('Criar uma conta'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('cadastro_nome')),
      'Pessoa de Teste',
    );
    await tester.enterText(
      find.byKey(const Key('cadastro_email')),
      'pessoa@exemplo.com',
    );
    await tester.enterText(find.byKey(const Key('cadastro_senha')), '123456');
    await tester.enterText(
      find.byKey(const Key('cadastro_confirmacao')),
      '123456',
    );
    await scrollTo(tester, find.byType(Checkbox), 350);
    await tester.tap(find.byType(Checkbox));
    await scrollTo(tester, find.byKey(const Key('concluir_cadastro')), 250);
    await tester.tap(find.byKey(const Key('concluir_cadastro')));
    await tester.pumpAndSettle();

    expect(find.text('Cadastro simulado concluído'), findsOneWidget);
    expect(find.text('Voltar ao login'), findsOneWidget);
  });

  testWidgets('abre o perfil e preferências do paciente', (tester) async {
    await tester.pumpWidget(const MovereApp());
    await enterDemo(tester, const Key('entrar_paciente'));
    await scrollTo(tester, find.text('Perfil'), 450);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Maria Oliveira'), findsOneWidget);
    expect(find.text('Preferências de acessibilidade'), findsOneWidget);
    expect(find.text('Texto ampliado'), findsOneWidget);
  });

  testWidgets('abre o painel do fisioterapeuta', (tester) async {
    await tester.pumpWidget(const MovereApp());

    await enterDemo(tester, const Key('entrar_fisioterapeuta'));

    expect(find.text('Painel profissional'), findsOneWidget);
    expect(find.text('Pacientes vinculados'), findsOneWidget);
    expect(find.text('Sessões para revisar'), findsOneWidget);
    await scrollTo(tester, find.text('Mensagens de pacientes'), 300);
    expect(find.text('Mensagens de pacientes'), findsOneWidget);
    expect(find.text('2 mensagens não lidas'), findsOneWidget);
    expect(find.text('Pacientes'), findsOneWidget);
  });

  testWidgets('mensagem no painel abre a conversa do paciente', (tester) async {
    await tester.pumpWidget(const MovereApp());
    await enterDemo(tester, const Key('entrar_fisioterapeuta'));

    await scrollTo(tester, find.text('João Pereira'), 300);
    await tester.tap(find.text('João Pereira'));
    await tester.pumpAndSettle();

    expect(find.text('Mensagens — João Pereira'), findsOneWidget);
  });

  testWidgets('indicador profissional abre pacientes com filtro aplicado', (
    tester,
  ) async {
    await tester.pumpWidget(const MovereApp());
    await enterDemo(tester, const Key('entrar_fisioterapeuta'));

    await tester.tap(find.text('Sem atividade recente'));
    await tester.pumpAndSettle();

    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Sem atividade'),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('busca paciente e abre detalhes', (tester) async {
    await tester.pumpWidget(const MovereApp());
    await enterDemo(tester, const Key('entrar_fisioterapeuta'));
    Navigator.of(
      tester.element(find.text('Painel profissional')),
    ).pushNamed(AppRoutes.patients);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('buscar_paciente')), 'João');
    await tester.pump();
    expect(find.text('João Pereira'), findsOneWidget);
    expect(find.text('Maria Oliveira'), findsNothing);

    await tester.tap(find.text('João Pereira'));
    await tester.pumpAndSettle();
    expect(find.text('Perfil do paciente'), findsOneWidget);
    expect(find.text('Dificuldade repetida na análise'), findsOneWidget);
    expect(find.text('72%'), findsOneWidget);
    expect(find.text('Dados informados pelo paciente'), findsOneWidget);
    expect(find.text('Faixa etária'), findsOneWidget);
  });

  testWidgets('mostra estado vazio na busca de pacientes', (tester) async {
    await tester.pumpWidget(const MovereApp());
    await enterDemo(tester, const Key('entrar_fisioterapeuta'));
    Navigator.of(
      tester.element(find.text('Painel profissional')),
    ).pushNamed(AppRoutes.patients);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('buscar_paciente')),
      'Nome inexistente',
    );
    await tester.pump();
    expect(find.text('Nenhum paciente encontrado'), findsOneWidget);
    expect(find.text('Limpar filtros'), findsOneWidget);
  });

  testWidgets('abre o plano e inicia o exercício disponível', (tester) async {
    await tester.pumpWidget(const MovereApp());
    await enterDemo(tester, const Key('entrar_paciente'));

    await tester.tap(find.text('Rotina'));
    await tester.pumpAndSettle();

    expect(find.text('Minha rotina de exercícios'), findsOneWidget);
    expect(find.text('Flexão de cotovelo'), findsOneWidget);
    expect(find.byKey(const Key('abrir_flexao_cotovelo')), findsOneWidget);
  });

  testWidgets('conclui o fluxo simulado do exercício', (tester) async {
    await tester.pumpWidget(const MovereApp());
    await enterDemo(tester, const Key('entrar_paciente'));
    await tester.tap(find.text('Rotina'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const Key('abrir_flexao_cotovelo')), 250);
    await tester.tap(find.byKey(const Key('abrir_flexao_cotovelo')));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.byKey(const Key('continuar_preparacao')), 300);
    await tester.tap(find.byKey(const Key('continuar_preparacao')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('marcar_todos_preparacao')));
    await tester.pump();
    expect(find.text('Desmarcar todos'), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('iniciar_gravacao')), 300);
    await tester.tap(find.byKey(const Key('iniciar_gravacao')));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.byKey(const Key('simular_gravacao')), 300);
    await tester.tap(find.byKey(const Key('simular_gravacao')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('concluir_processamento')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ver_resultado')));
    await tester.pumpAndSettle();

    expect(find.text('Resultado simulado'), findsOneWidget);
    expect(find.text('Repetições simuladas'), findsOneWidget);
    expect(
      find.text('Sessão concluída. Agora conte como você se sentiu.'),
      findsOneWidget,
    );
  });

  testWidgets('permite falha simulada e nova tentativa', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProcessingScreen()));

    await tester.tap(find.byKey(const Key('simular_falha')));
    await tester.pump();
    expect(find.text('Não foi possível concluir'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tentar_novamente')));
    await tester.pump();
    expect(find.text('Analisando movimento'), findsOneWidget);
  });

  testWidgets('apresenta análise inconclusiva sem métricas', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ResultScreen(inconclusive: true)),
    );

    expect(find.text('Não foi possível analisar'), findsOneWidget);
    expect(find.text('Repetições simuladas'), findsNothing);
  });
}
