# Requisitos

Este documento funciona como índice de rastreabilidade. A descrição completa e normativa permanece em [SISTEMA.md](./SISTEMA.md).

## Requisitos funcionais

- Dois perfis: paciente e fisioterapeuta.
- Autenticação e controle de acesso conforme o perfil e o vínculo profissional.
- Plano de exercícios individual.
- Prescrição profissional versionada com séries, repetições, frequência, lado,
  cadência, intervalo, período de vigência, orientações, estado ativo e meta
  opcional de amplitude para cotovelo e agachamento.
- Registro, em cada sessão, da versão e das metas da prescrição utilizada.
- Calibração técnica individual opcional dos limiares de detecção, separada da
  meta terapêutica, com faixas protegidas, justificativa profissional,
  restauração do padrão e registro dos valores usados em cada sessão.
- Preparação, gravação ou seleção de vídeo, processamento e apresentação do resultado.
- Análise dos exercícios iniciais: flexão de cotovelo, agachamento e pinça.
- Registro de sessões, métricas, compensações, observações e orientações.
- Histórico, comparação de sessões e acompanhamento longitudinal.
- Painel do fisioterapeuta com filtros e sessões que merecem revisão.
- Rotina terapêutica com múltiplos exercícios por paciente e configuração
  individual de frequência, séries, repetições, lado, amplitude e intervalo.
- Relatórios individual e longitudinal em PDF.
- Perfil contextual opcional do paciente: faixa etária, tempo desde o AVC,
  lado afetado, dominância anterior ao AVC, tipo de AVC, mobilidade e uso de
  dispositivo auxiliar.
- Relato pós-sessão de bem-estar, dor/desconforto e fadiga, sem interpretação
  diagnóstica automática.
- Motivo técnico estruturado quando a análise falhar ou for inconclusiva.
- Compartilhamento opcional de até quatro capturas técnicas da sessão com o
  fisioterapeuta vinculado, desativado por padrão e condicionado a
  consentimento explícito. O vídeo original não é persistido.

## Requisitos de acessibilidade

- Aplicar WCAG 2.1 nível AA sempre que pertinente.
- Utilizar área de toque mínima de 48×48 dp.
- Apresentar linguagem simples, instruções curtas e feedback compreensível.
- Não transmitir informação exclusivamente por cor ou áudio.
- Considerar limitações motoras, visuais, cognitivas e fadiga após AVC.

## Requisitos de segurança e confiabilidade

- Não diagnosticar doenças nem substituir o fisioterapeuta.
- Não afirmar segurança ou precisão clínica sem validação.
- Informar quando uma análise for inconclusiva.
- Utilizar linguagem neutra para resultados que mereçam atenção.
- Manter critérios de análise parametrizados e documentados.

## Requisitos de privacidade

- Minimizar a coleta e a retenção de dados.
- Remover vídeos temporários após o processamento sempre que possível.
- Quando o paciente optar pelo compartilhamento, armazenar uma cópia privada
  por no máximo 30 dias, permitir exclusão antecipada pelo paciente e impedir
  acesso público ou por profissionais sem vínculo aceito.
- Restringir o paciente aos próprios dados.
- Restringir o fisioterapeuta aos pacientes vinculados.
- Não afirmar conformidade legal definitiva somente com base na implementação técnica.
- Coletar campos contextuais somente de forma opcional e com finalidade
  documentada; não coletar altura, sexo, data de nascimento exata ou um
  “grau de paralisia” genérico sem justificativa metodológica.

## Tecnologias definidas

- Aplicativo: Flutter.
- API: Python e FastAPI.
- Visão computacional: MediaPipe e OpenCV.
- Análise numérica: NumPy.
- Autenticação e persistência estruturada: Firebase Authentication e Cloud Firestore.
- Vídeos compartilhados opcionalmente: Firebase Storage.
- Relatórios: ReportLab e, quando necessário, Matplotlib.

## Documentos relacionados

- [Sistema](./SISTEMA.md)
- [Arquitetura](./ARQUITETURA.md)
- [Plano de desenvolvimento](./PLANO_DESENVOLVIMENTO.md)
- [Progresso](./PROGRESSO.md)
- [API](./API.md)
- [Acessibilidade](./ACESSIBILIDADE.md)
- [Sistema visual](./SISTEMA_VISUAL.md)
- [Configuração](./CONFIGURACAO.md)
- [Dados de pesquisa](./DADOS_PESQUISA.md)
