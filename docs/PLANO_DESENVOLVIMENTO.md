# Plano de desenvolvimento

Este plano segue [SISTEMA.md](./SISTEMA.md) e deve ser acompanhado em [PROGRESSO.md](./PROGRESSO.md).

## Regra de execução

Cada fase deve terminar funcionando e ser validada antes do início da próxima. Até **25 de outubro de 2026**, priorizar um núcleo demonstrável nesta ordem:

Flutter básico → API básica → flexão de cotovelo → integração real → demais exercícios → acompanhamento longitudinal.

## Fase 0 — Planejamento

- [x] Consolidar `SISTEMA.md` como fonte de verdade.
- [x] Definir arquitetura, requisitos, configuração e prompts.
- [x] Executar o diagnóstico de `prompts/01_analisar_projeto.md` antes da implementação.

**Conclusão:** arquitetura, riscos, prioridades e primeira entrega identificados sem alterar código prematuramente.

## Fase 1 — Aplicativo base

- [x] Criar o projeto Flutter em `frontend/`.
- [x] Configurar tema e componentes acessíveis.
- [x] Criar cadastro, login e recuperação de senha simulados com validação.
- [x] Criar home e perfil completos do paciente.
- [x] Criar dashboard e perfil completos do fisioterapeuta.
- [x] Criar lista, busca, filtros e detalhe de pacientes simulados.
- [x] Criar estados vazio, carregamento, validação, erro e sucesso.
- [x] Testar componentes, formulários, estados e rotas.

**Conclusão:** aplicativo navegável para os dois perfis, sem API, Firebase ou visão computacional.

## Fase 2 — Fluxo simulado do exercício

Fluxo: Meu plano → exercício → instruções → preparação → gravação/seleção → processamento → resultado simulado.

- [x] Apresentar demonstração, posição inicial, enquadramento e cuidados.
- [x] Solicitar confirmação de ambiente preparado.
- [x] Implementar gravação ou seleção de vídeo simuladas.
- [x] Criar estados de processamento, falha e análise inconclusiva.
- [x] Exibir resultado simulado claramente identificado.
- [x] Validar a acessibilidade do fluxo.

**Conclusão:** fluxo demonstrável no Flutter sem afirmar análise clínica real.

## Fase 3 — API básica

- [x] Criar `backend/` com rotas, esquemas, serviços, modelos e utilitários separados.
- [x] Criar endpoint de saúde.
- [x] Criar endpoint de análise com resposta simulada identificada.
- [x] Validar upload e identificação do exercício.
- [x] Criar documentação OpenAPI e testes dos contratos.
- [x] Manter execução direta com Python.
- [x] Adicionar `Dockerfile`, `.dockerignore` e `compose.yaml` como alternativa opcional somente para o backend.

**Conclusão:** Flutter envia uma requisição e recebe uma resposta simulada válida. O backend está validado com Python; a configuração Docker está pronta, mas a construção local da imagem ainda depende da obtenção da imagem-base.

## Fase 4 — Visão computacional: flexão de cotovelo

- [x] Processar vídeo e frames com OpenCV.
- [x] Extrair landmarks com MediaPipe.
- [x] Calcular métricas com NumPy.
- [x] Implementar estados, repetições e compensações parametrizadas.
- [x] Retornar análise inconclusiva quando os dados forem insuficientes.
- [x] Documentar parâmetros, limitações e testes técnicos.
- [ ] Validar o MediaPipe com vídeos reais representativos em ambiente com suporte gráfico e registrar os resultados.

**Conclusão:** módulo testado isoladamente, sem diagnóstico, segurança médica ou precisão clínica declarada.

## Fase 5 — Primeira integração real

- [x] Enviar vídeo real pelo Flutter.
- [x] Validar e processar o arquivo temporário no backend.
- [x] Chamar o módulo correspondente sem colocar MediaPipe nas rotas.
- [x] Retornar processamento, sucesso, falha ou análise inconclusiva.
- [x] Exibir o resultado de forma acessível.
- [x] Remover o vídeo temporário em todos os desfechos.
- [x] Testar falha de rede, vídeo inválido e dados insuficientes.
- [ ] Validar o fluxo completo com vídeo humano real.

**Conclusão:** núcleo está implementado de ponta a ponta; a conclusão da fase depende da validação com vídeo humano real.

## Fase 6 — Outros exercícios

- [x] Implementar e testar agachamento em módulo independente.
- [x] Integrar agachamento ao fluxo existente.
- [x] Implementar e testar pinça em módulo independente.
- [x] Integrar pinça ao fluxo existente.
- [x] Documentar regras, parâmetros e limitações por exercício.
- [ ] Validar agachamento e pinça com vídeos humanos representativos e revisão
  profissional.

**Conclusão:** os três exercícios utilizam o mesmo fluxo, preservando módulos e critérios independentes.

## Fase 7 — Histórico e progresso

- [x] Registrar sessões e métricas estruturadas.
- [x] Criar histórico individual.
- [x] Comparar sessão individual e evolução geral.
- [x] Criar gráficos quando houver dados suficientes.
- [x] Não inventar tendências quando os dados forem insuficientes.
- [ ] Validar a interpretação do gráfico com uma série real representativa.

**Conclusão:** é possível observar a evolução ao longo de várias sessões.

## Fase 8 — Dashboard do fisioterapeuta

- [x] Listar pacientes e filtros previstos.
- [x] Exibir sessões, exercícios, métricas e evolução.
- [x] Exibir alertas de análise com linguagem neutra.
- [x] Permitir observações e orientações profissionais.
- [x] Não classificar automaticamente pacientes como graves ou piores.
- [x] Permitir calibração técnica individual dos limiares de ciclo, com faixas
  protegidas, justificativa, restauração do padrão e rastreabilidade por sessão.

**Conclusão:** o fisioterapeuta acompanha pacientes e pendências sem diagnósticos automáticos.

## Fase 9 — Relatórios PDF

- [x] Gerar PDF individual com ReportLab.
- [x] Gerar relatório longitudinal por período.
- [x] Incluir gráficos somente quando houver dados suficientes.
- [x] Testar conteúdo e linguagem automaticamente.
- [x] Registrar no PDF os limiares personalizados e a justificativa quando uma
  calibração individual tiver sido aplicada.
- [ ] Validar legibilidade e identidade visual com usuários.

**Conclusão:** relatórios refletem exclusivamente os dados registrados.

## Fase 10 — Firebase e persistência completa

- [x] Configurar Firebase Authentication e Cloud Firestore.
- [x] Implementar perfis e vínculos entre pacientes e fisioterapeutas.
- [x] Persistir planos, sessões, métricas e observações; gerar relatórios sob demanda a partir desses dados.
- [x] Aplicar controle de acesso por perfil e vínculo.
- [x] Substituir os serviços simulados no aplicativo de produção sem acoplar telas diretamente ao Firebase.
- [x] Testar privacidade, autorização e fluxo remoto com dois perfis.

**Conclusão:** fluxo completo persistido com autenticação e controle de acesso.

## Encerramento de cada fase

Antes de avançar, registrar em `PROGRESSO.md` arquivos alterados, funcionalidades concluídas, testes, limitações, problemas e pendências.
