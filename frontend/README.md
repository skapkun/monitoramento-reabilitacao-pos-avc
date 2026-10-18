# Aplicativo Movere

Aplicativo Flutter acessível para pacientes e fisioterapeutas da plataforma Movere.

## Estado atual

As fases 1 e 2 contêm perfis, dashboard profissional, pacientes, navegação, tema e componentes acessíveis. O fluxo do exercício permite gravar ou selecionar um vídeo, enviá-lo ao FastAPI, acompanhar o job e exibir sucesso, resultado inconclusivo ou falha.

Firebase Authentication, perfis editáveis, vínculos consentidos, planos, sessões, orientações, histórico e métricas estão persistidos no Firestore para Android e iOS com o identificador `com.app.movere`. Os repositórios demonstrativos permanecem isolados para testes automatizados; a compilação normal utiliza Firebase. A análise real depende de executar o backend com `ANALYSIS_MODE=real` e o PDF compartilhável depende do endpoint de relatórios da API.

## Executar

```bash
flutter pub get
flutter run
```

O projeto `movere-dc610`, E-mail/senha, Firestore `(default)` em `southamerica-east1`, regras e índices já estão configurados. Consulte [`../docs/CONFIGURACAO.md`](../docs/CONFIGURACAO.md).

## Validar

```bash
flutter analyze
flutter test
```

Consulte a documentação principal em [`../docs/SISTEMA.md`](../docs/SISTEMA.md) e o estado das fases em [`../docs/PROGRESSO.md`](../docs/PROGRESSO.md).
