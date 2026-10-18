# Progresso do projeto

Atualizar este documento ao concluir cada tarefa. Não marcar itens apenas iniciados como concluídos.

## Estado atual

- Fase atual: **validação técnica com vídeos reais e avaliação profissional**
- Próxima entrega: validar o fluxo completo em dispositivo com vídeos humanos representativos
- Prazo de priorização do núcleo funcional: **25 de outubro de 2026**

## Fase 0 — Planejamento

- [x] Documento mestre consolidado.
- [x] Arquitetura definida.
- [x] Requisitos e prompts organizados.
- [x] Sistema visual documentado com pares de contraste verificados.
- [x] Plano incremental definido.
- [x] Diagnóstico pré-implementação executado: o repositório contém somente documentação; `frontend/` e `backend/` ainda precisam ser criados.
- [x] Ambiente Flutter validado com `flutter doctor`: Android, iOS, macOS, web, Android Studio e VS Code sem problemas.

## Fase 1 — Aplicativo base

- [x] Projeto Flutter, tema, componentes acessíveis e navegação inicial.
- [x] Cadastro e login simulados com validação e indicação de processamento.
- [x] Recuperação de senha simulada.
- [x] Perfis completos do paciente e fisioterapeuta.
- [x] Preferências simuladas de acessibilidade do paciente.
- [x] Dashboard profissional com indicadores e alerta simulados.
- [x] Lista, busca, filtros, estado vazio e detalhe de pacientes simulados.
- [x] Estados vazio, carregamento, validação, erro e sucesso.
- [x] Quatorze testes aprovados, análise estática sem problemas e compilação web concluída.

## Fase 2 — Fluxo simulado do exercício

- [x] Plano, seleção, instruções e preparação.
- [x] Gravação e seleção de vídeo simuladas.
- [x] Processamento e resultado simulados claramente identificados.
- [x] Estados de sucesso, falha, nova tentativa e análise inconclusiva.
- [x] Fluxo completo coberto por testes automatizados.
- [x] Análise estática sem problemas, sete testes aprovados e compilação web concluída.

## Fase 3 — API básica

- [x] FastAPI organizado em rotas, esquemas e serviços.
- [x] Endpoint de saúde validado em servidor local real.
- [x] Upload, identificação do exercício, limite configurável e resposta explicitamente simulada.
- [x] Consulta do resultado simulado por identificador.
- [x] Cinco testes do backend aprovados.
- [x] Cliente HTTP do Flutter com dois testes de contrato; suíte Flutter totaliza dezesseis testes aprovados.
- [x] Dockerfile e Compose opcionais com configuração validada.
- [ ] Construção da imagem Docker não executada: o Docker Desktop/daemon não está ativo nesta máquina; execução local está validada.

## Fase 4 — Visão computacional

- [x] Pipeline isolado OpenCV, MediaPipe e NumPy implementado.
- [x] Flexão de cotovelo, máquina de estados e casos inconclusivos implementados.
- [x] Parâmetros, limitações e testes controlados documentados.
- [x] Falhas de inicialização e processamento do MediaPipe tratadas explicitamente.
- [x] Quatorze testes específicos da visão computacional; suíte do backend com dezenove testes aprovados.
- [x] CLI de validação com relatório JSON, identificação SHA-256 da amostra e protocolo de gravação documentado.
- [ ] Validação com vídeos humanos representativos: pendente de amostras e execução local interativa do MediaPipe.

## Fase 5 — Primeira integração real

- [x] Seleção ou gravação de vídeo real no Flutter.
- [x] Flutter → API → serviço de análise → API → Flutter implementado.
- [x] Alternância explícita entre `ANALYSIS_MODE=mock` e `ANALYSIS_MODE=real`.
- [x] Upload validado e salvo somente em arquivo temporário.
- [x] Remoção do vídeo em sucesso, resultado inconclusivo ou falha.
- [x] Consulta do job até conclusão, falha ou resultado inconclusivo.
- [x] Resultado técnico real e resultado simulado diferenciados na interface.
- [x] Falha de conexão, timeout, formato inválido e nova tentativa tratados.
- [x] Vinte e três testes do backend e dezessete testes do Flutter aprovados.
- [ ] Validação ponta a ponta com vídeo humano real: pendente.

## Fase 6 — Outros exercícios

- [x] Agachamento em módulo independente, integrado à API e ao aplicativo.
- [x] Pinça em módulo independente com MediaPipe Hands, integrada à API e ao aplicativo.
- [x] Planos profissionais permitem selecionar qualquer um dos três exercícios.
- [x] Métricas específicas persistidas e apresentadas no resultado.
- [ ] Validar ambos com vídeos humanos representativos e revisão do fisioterapeuta.

## Fase 7 — Histórico e progresso

- [x] Sessões persistentes, histórico, indicadores e gráfico acessível de evolução longitudinal.
- [x] Detalhes por repetição com tempo, amplitude, duração e classificação
  técnica persistidos na sessão.
- [x] Momentos de maior amplitude, amplitude abaixo da referência e possíveis
  desvios associados aos segundos correspondentes do vídeo.
- [x] Galeria privada de até quatro capturas técnicas autorizadas, com título e
  instante observado; o vídeo completo usa consentimento separado e retenção
  temporária no FastAPI.
- [x] Comparação descritiva entre lado afetado e não afetado quando os dois
  lados possuem visibilidade suficiente.
- [ ] Validar a interpretação do gráfico com uma série real representativa.

## Fase 8 — Dashboard do fisioterapeuta

- [x] Pacientes vinculados, filtros, métricas, evolução e alertas descritivos.
- [x] Observações profissionais e orientações visíveis ao paciente.
- [x] Indicador semanal calcula somente sessões dos últimos sete dias; pendências de revisão permanecem históricas até serem avaliadas.
- [x] Visão geral prioriza pacientes com sinais operacionais de inatividade,
  baixa frequência semanal, dificuldades repetidas, resultado abaixo da
  prescrição, dor/cansaço altos ou queda recente das repetições.
- [x] Lista de pacientes possui filtros para atenção, inatividade, revisão e
  plano ainda não iniciado, com os motivos detalhados no perfil.
- [x] Alertas são apresentados como apoio à organização profissional, sem
  afirmar diagnóstico, piora clínica ou conduta automática.
- [x] Revisão da sessão com nota de 1 a 5 e conduta: manter treino, ajustar carga ou agendar reavaliação.
- [x] Revisão profissional de cada momento destacado, com estados pendente,
  confirmado, não confirmado ou vídeo insuficiente, além de orientação textual
  que pode ser compartilhada com o paciente.
- [x] Prescrição individual ampliada com meta de amplitude definida pelo
  fisioterapeuta, número de séries, intervalo, lado trabalhado, cadência e
  período do plano; manter essas metas separadas dos limiares técnicos do
  algoritmo e registrar na sessão a versão do plano utilizada.
- [x] Tela profissional explica o pipeline, as fórmulas, os limiares técnicos,
  a diferença entre prescrição e detecção, a confiança heurística e as
  limitações da análise 2D, sem apresentar as métricas como validação clínica.
- [x] Calibração individual opcional dos limiares de ciclo por exercício, com
  valores padrão, faixas protegidas no aplicativo/API/Firestore, justificativa
  obrigatória, versionamento pelo plano e registro dos valores na sessão e PDF.
- [x] Perfil diferencia participante pós-AVC de voluntário saudável; o modo de
  teste saudável omite campos clínicos incompatíveis e informa que seu uso
  avalia funcionamento e usabilidade, não eficácia clínica pós-AVC.
- [x] Rotina com múltiplos exercícios por paciente: o fisioterapeuta adiciona
  e edita cada exercício separadamente, e o paciente visualiza a sequência
  completa numerada com metas e orientações próprias.
- [x] Sessões reorganizadas por hierarquia visual, separando acertos
  observados, pontos que exigem conferência e o relato do paciente sobre
  bem-estar, dor, fadiga e comentário livre.
- [x] Perfil profissional destaca o último relato do paciente e as sessões sem
  alerta pendente antes dos dados contextuais.
- [x] Navegação inferior persistente nos fluxos principais de paciente e
  fisioterapeuta, mantendo alvos de toque e suporte a texto ampliado.
- [x] Comunicação assíncrona entre paciente e fisioterapeuta vinculado, com
  mensagens rápidas, confirmação de leitura/resposta, aviso de canal não
  emergencial e isolamento por regras do Firestore.
- [x] Telas iniciais compactadas para reduzir rolagem: atalhos duplicados foram
  removidos, métricas profissionais ganharam versão reduzida e os detalhes
  extensos das sessões podem ser expandidos quando necessários.

## Fase 9 — Relatórios

- [x] PDF longitudinal gerado pelo FastAPI, com gráfico Matplotlib, métricas técnicas, bem-estar e revisão profissional, e compartilhável no aplicativo.
- [x] PDF inclui a revisão dos momentos destacados e as orientações registradas
  pelo fisioterapeuta, sem transformar achados técnicos em diagnóstico.
- [x] Exportação CSV pseudonimizada para pesquisa, sem nome, identificador
  original ou datas absolutas, protegida por aviso de uso conforme TCLE e
  protocolo ético.
- [ ] Refinar identidade visual do relatório após validação com usuários.

## Fase 10 — Firebase

- [x] Aplicativos Android e iOS registrados com `com.app.movere` e FlutterFire configurado.
- [x] Firebase Authentication integrado ao cadastro, login, recuperação, restauração de sessão e logout.
- [x] Perfis de paciente e fisioterapeuta integrados ao Firestore, com edição de nome, telefone e registro profissional quando aplicável.
- [x] Regras restritivas e índices do Firestore versionados.
- [x] Sintaxe das regras validada no emulador local do Firestore.
- [x] Análise estática limpa, 96 testes Flutter aprovados, APK Android e aplicativo para simulador iOS gerados.
- [x] Versões FlutterFire fixadas e validadas com Flutter 3.35.7; alvo mínimo iOS 15.
- [x] Authentication por e-mail/senha e Firestore `(default)` ativados no projeto remoto.
- [x] Capturas JPEG opcionais protegidas no Firestore e compartilhamento
  separado do vídeo completo implementados mediante consentimento.
- [x] Exclusão das capturas pelo paciente e inclusão das evidências autorizadas
  no relatório PDF implementadas.
- [x] Reprodução privada do vídeo completo implementada sem Firebase Storage:
  arquivo e metadados cifrados no FastAPI, retenção de até 30 dias, acesso do
  paciente e profissional escolhido e exclusão antecipada pelo paciente.
- [ ] Publicar o FastAPI com HTTPS e volume persistente e validar o fluxo com
  duas contas Firebase vinculadas em dispositivo físico.
- [x] Regras e índices publicados no Firestore remoto.
- [x] Cadastro temporário, criação/leitura do próprio perfil e atualização de preferências validados remotamente.
- [x] Alteração do papel e leitura do perfil de outro usuário bloqueadas pelas regras remotas.
- [x] Firestore recriado na região planejada `southamerica-east1`.
- [x] Preferências de acessibilidade carregadas e salvas no perfil do Firestore.
- [x] Texto ampliado e redução de animações aplicados globalmente a partir das preferências persistidas.
- [x] Vínculo paciente–fisioterapeuta por convite e aceite, planos e sessões persistentes.
- [x] Validação opcional de token Firebase no backend e envio do token pelo Flutter.
- [x] Resultado de análise isolado por proprietário autenticado.
- [x] Persistência de vínculos, planos, sessões e orientações com controles de acesso publicados e testados remotamente.
- [x] Cadastro profissional e edição de perfil validados remotamente; alteração indevida do papel bloqueada pelas regras.
- [x] Smoke test Android: APK instalado e `MainActivity` iniciada em emulador, sem exceção fatal ou erro Firebase no log.
- [x] Perfil do paciente ampliado com lado afetado, tipo de AVC e condição de mobilidade.
- [x] Perfil ampliado com faixa etária, tempo desde o AVC, dominância anterior e dispositivo auxiliar opcionais, visíveis ao paciente e ao profissional vinculado.
- [x] Bem-estar de 1 a 5, dor/desconforto e fadiga de 0 a 10 persistidos e visíveis no acompanhamento e no relatório.
- [x] Falhas e análises inconclusivas registram motivo técnico estruturado.
- [x] Regras remotas atualizadas para proteger os novos campos de perfil, bem-estar e revisão profissional, incluindo a revisão individual dos eventos.
- [x] Regras remotas atualizadas para proteger eventos temporais, detalhes por
  repetição e comparação bilateral das sessões.
- [x] Sessões persistem versão dos parâmetros de análise, quadros válidos,
  quadros totais e proporção de detecção para rastreabilidade técnica.

## Registro da última etapa concluída

- Data: 18 de outubro de 2026
- Fase: calibração individual rastreável e revisão final de linguagem.
- Funcionalidades implementadas: calibração opcional dos limiares por
  exercício, justificativa profissional, faixas protegidas em três camadas,
  registro na sessão e no PDF, perfil de voluntário saudável, explicação das
  métricas no aplicativo e pluralização natural dos textos da interface.
- Segurança: regras versionadas limitam dados clínicos ao paciente e ao fisioterapeuta com vínculo aceito; o FastAPI valida tokens reais sem exigir chave administrativa na configuração padrão.
- Testes executados: `flutter analyze`, 96 testes Flutter e 44 testes do
  backend; incluídos testes de acessibilidade, calibração, mensagens, extração
  de capturas, análise explicável, relatórios e exportação para pesquisa.
- Acessibilidade: 26 rotas verificadas automaticamente em telefone estreito;
  texto a 200%, contraste, rótulos e alvos de toque cobertos. Validação manual
  com tecnologias assistivas e público-alvo permanece pendente.
- Builds gerados novamente em 13 de outubro de 2026: APK Android de depuração e `Runner.app` para simulador iOS.
- Interface aproximada das Figuras 2 e 3 com identidade roxa, verde-água e laranja acessível, exercício em destaque, resumo de progresso, métricas compactas em cartões, bem-estar com ícone e texto e detalhes profissionais expansíveis; fluxos reais e política de privacidade preservados.
- Problemas encontrados: o projeto anterior foi substituído antes da entrada de dados reais para permitir a criação do Firestore na região planejada.
- Próximo passo: validar os três exercícios, a compreensão das frases e a facilidade de toque com pessoas representativas do público-alvo e fisioterapeuta, sem apresentar testes automatizados como validação clínica.
