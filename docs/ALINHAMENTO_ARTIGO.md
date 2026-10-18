# Alinhamento com o artigo aceito

Este documento registra o estado do software em relação ao artigo **“Uma Aplicação para Monitoramento de Progresso em Terapias de Reabilitação Pós-AVC por meio de Visão Computacional”**. O artigo aceito é um artefato científico imutável; este registro não altera suas afirmações e não substitui evidência experimental.

## Implementado

| Elemento descrito | Evidência no sistema |
|---|---|
| Aplicativo Flutter Android/iOS | `frontend/`, com builds de depuração gerados para Android e simulador iOS |
| Backend FastAPI | rotas de saúde, análise, consulta do resultado e PDF |
| Firebase | Authentication, Firestore, regras por proprietário/vínculo e índices publicados |
| Três exercícios | módulos separados de flexão de cotovelo, agachamento e pinça |
| MediaPipe, OpenCV e NumPy | extração Pose/Hands, leitura de vídeo e cálculo das métricas |
| Parâmetros descritos | valores padrão: cotovelo 160°/90°, joelho 160°/100° e pinça 0,10/0,05; calibração individual posterior é identificada como extensão experimental |
| Métricas | repetições, amplitude, duração, velocidade, simetria bilateral quando disponível e distância de pinça |
| Acompanhamento longitudinal | sessões, histórico, evolução e gráfico |
| Perfis | paciente e fisioterapeuta, incluindo lado afetado, tipo de AVC, mobilidade e campos contextuais opcionais |
| Experiência subjetiva | bem-estar de 1 a 5, dor/desconforto e fadiga de 0 a 10, com comentário opcional |
| Qualidade técnica | motivo estruturado para análise inconclusiva ou falha, sem produzir resultado falso |
| Revisão profissional | avaliação de 1 a 5 e conduta estruturada |
| Relatórios | ReportLab com gráfico Matplotlib, métricas e aviso de que não é laudo |
| Privacidade operacional | descarte por padrão; capturas opcionais no Firestore e vídeo completo opcional cifrado no FastAPI, com retenção de até 30 dias |
| Revisão do vídeo | reprodução privada pelo paciente e pelo fisioterapeuta escolhido, sem URL pública |
| Licença | MIT em `LICENSE` |

## Implementado com limitação explícita

- O retorno é apresentado depois do upload/processamento, não continuamente durante a execução do movimento.
- Simetria depende de os dois lados estarem visíveis no mesmo vídeo.
- “Compensações” são heurísticas técnicas e sempre exigem interpretação profissional.
- A calibração individual dos limiares é uma extensão experimental do
  protótipo posterior ao artigo. Ela é separada da meta terapêutica, exige
  justificativa e não constitui parâmetro clínico validado.
- A distância da pinça usa coordenadas normalizadas 2D; não é uma medida física.
- O vídeo compartilhado apresenta a gravação original; os eventos técnicos e
  seus instantes aparecem associados à sessão, mas ainda não são desenhados
  quadro a quadro sobre o arquivo reproduzido.
- O vínculo atual é iniciado pelo fisioterapeuta com o identificador do paciente e confirmado pelo paciente. Isso difere do fluxo textual de código gerado pelo profissional, preservando consentimento explícito antes do acesso.
- O Firestore mantém os dados estruturados. Vídeo e metadados audiovisuais são
  cifrados com AES-256-GCM no servidor; o SQLite armazena apenas localizadores,
  tamanho e expiração em claro, sem identificadores pessoais ou de sessão.

## Depende de validação humana ou decisão ética

- Validação com vídeos reais representativos dos três exercícios.
- Avaliação de repetibilidade, falsos positivos, falsos negativos e sensibilidade a câmera/iluminação.
- Comparação das métricas com avaliação de fisioterapeuta e, se aplicável, método de referência.
- Teste de usabilidade e acessibilidade com o público-alvo.
- TCLE/consentimento de pesquisa revogável: deve usar o texto aprovado pelo responsável e, quando aplicável, pelo comitê de ética; não foi inventado no aplicativo.
- Qualquer afirmação de eficácia clínica, segurança médica ou validade diagnóstica.
- Inclusão de escala clínica de comprometimento motor: depende da escolha e
  aplicação de instrumento validado com orientação profissional e protocolo
  ético; o sistema não usa um “grau de paralisia” inventado.

## Extensões posteriores ao artigo

Faixa etária, tempo desde o AVC, dominância anterior, dispositivo auxiliar,
dor/desconforto, fadiga e motivo técnico estruturado foram acrescentados para
contextualizar análises futuras e tornar falhas auditáveis. Esses campos não
ampliam retroativamente os resultados do artigo aceito e não constituem
validação clínica. A finalidade e a minimização estão registradas em
`DADOS_PESQUISA.md`.

O compartilhamento opcional de capturas técnicas e do vídeo completo é uma extensão
posterior ao artigo. Ele aproxima o protótipo do fluxo de revisão profissional
sem transformar a demonstração descrita no artigo em evidência de uma
funcionalidade já validada no workshop.

A prescrição individual versionada, incluindo séries, repetições, frequência,
lado, cadência, intervalo, vigência e meta opcional de amplitude, é outra
extensão posterior. As metas ficam separadas dos parâmetros técnicos da visão
computacional e não representam validação clínica dos valores escolhidos.

Os alertas de acompanhamento no painel profissional também são uma extensão
posterior. Eles usam limites operacionais explícitos: 14 dias sem sessão,
menos de metade da frequência semanal, duas dificuldades ou resultados abaixo
da prescrição entre até três sessões recentes, dor a partir de 7/10, cansaço a
partir de 8/10 e redução superior a 15% nas repetições ao comparar dois pares
de sessões. Servem somente para ordenar a revisão do fisioterapeuta. Esses
limites não foram validados clinicamente e não indicam diagnóstico, risco ou
piora funcional.

A análise explicável por repetição é uma extensão posterior ao artigo. O
sistema registra os segundos da maior amplitude, de amplitudes abaixo da
referência técnica e de possíveis elevações do ombro ou inclinações do tronco.
Quando o paciente autoriza, até quatro desses momentos são persistidos como
JPEGs compactados no Firestore e podem ser incluídos no PDF. Em consentimento
separado, o vídeo completo pode ser mantido cifrado por até 30 dias. Os eventos
são heurísticos experimentais e exigem revisão do fisioterapeuta.

## Verificações automatizadas em 18/10/2026

- `flutter analyze`: sem problemas.
- `flutter test`: 96 testes aprovados, incluindo as 26 rotas em telefone
  estreito, texto a 200%, limites dos alertas operacionais, calibração e
  apresentação dos eventos técnicos.
- `pytest`: 47 testes aprovados, incluindo validação dos limiares
  personalizados, extração de capturas, PDF e armazenamento cifrado de vídeo
  com controle de acesso.
- Dependências Python: sem incompatibilidades detectadas pelo `pip check`.
- Regras do Firestore: compiladas e publicadas no projeto `movere-dc610`.
- APK Android e `Runner.app` para simulador iOS: gerados com sucesso.

Essas verificações comprovam consistência de software, não validação clínica. O protocolo para a próxima etapa está em `VALIDACAO_VIDEOS.md`.
