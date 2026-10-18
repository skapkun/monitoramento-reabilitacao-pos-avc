# Sistema visual

Este documento define cores, tipografia, ícones e estados visuais do aplicativo. Ele deve ser aplicado em conjunto com [ACESSIBILIDADE.md](./ACESSIBILIDADE.md) e não substitui testes com pessoas usuárias.

## Princípios

- Clareza antes de ornamentação.
- Uma ação principal por tela sempre que possível.
- Aparência calma e previsível, sem infantilizar o usuário.
- Informação nunca transmitida somente por cor.
- Contraste validado para cada par real de primeiro plano e fundo.
- Componentes reutilizáveis, com estados consistentes em todo o aplicativo.

## Paleta semântica

| Uso | Cor | Aplicação |
|---|---|---|
| Fundo principal | `#FFFFFF` | Superfície padrão |
| Fundo alternativo | `#F8FAFC` | Agrupamento de conteúdo |
| Texto principal | `#111827` | Títulos e conteúdo essencial |
| Texto secundário | `#374151` | Descrições e informações auxiliares |
| Primária | `#4F46E5` | Ação principal e navegação ativa; aproxima a identidade do protótipo publicado |
| Primária suave | `#EEF2FF` | Fundo de destaque informativo |
| Texto sobre primária suave | `#3730A3` | Conteúdo do destaque primário |
| Secundária/sucesso | `#0F766E` | Confirmação, progresso e conclusão |
| Fundo de sucesso | `#F0FDFA` | Cartões de evolução e adesão |
| Texto sobre sucesso suave | `#115E59` | Conteúdo de cartões de evolução |
| Acento | `#9A3412` | Destaques complementares e demonstração, nunca único indicador |
| Fundo do acento | `#FFF7ED` | Destaque complementar suave |
| Informação | `#1D4ED8` | Mensagens informativas |
| Fundo de atenção | `#FEF3C7` | Avisos que exigem atenção |
| Texto de atenção | `#78350F` | Texto e ícone do aviso |
| Fundo de erro | `#FEE2E2` | Falha ou impedimento |
| Texto de erro | `#991B1B` | Texto e ícone do erro |
| Foco | `#4F46E5` | Indicador de foco visível |
| Borda | `#9CA3AF` | Divisão e contorno, sem transmitir texto |

As cores de sucesso, atenção, erro e informação sempre devem aparecer com ícone e texto. Não usar apenas verde, amarelo, vermelho ou azul para comunicar o estado.

## Pares de contraste aprovados

Os valores foram calculados pela fórmula de luminância relativa da WCAG. Todos os pares abaixo superam 4,5:1 e podem ser usados para texto normal no nível AA.

| Primeiro plano | Fundo | Contraste |
|---|---|---:|
| `#111827` | `#FFFFFF` | 17,74:1 |
| `#374151` | `#FFFFFF` | 10,31:1 |
| `#111827` | `#F8FAFC` | 16,96:1 |
| `#FFFFFF` | `#4F46E5` | 6,29:1 |
| `#FFFFFF` | `#0F766E` | 5,47:1 |
| `#FFFFFF` | `#9A3412` | 7,31:1 |
| `#FFFFFF` | `#1D4ED8` | 6,70:1 |
| `#78350F` | `#FEF3C7` | 8,15:1 |
| `#991B1B` | `#FEE2E2` | 6,80:1 |
| `#3730A3` | `#EEF2FF` | 8,88:1 |
| `#115E59` | `#F0FDFA` | 7,27:1 |
| `#9A3412` | `#FFF7ED` | 6,88:1 |

## Relação com os protótipos do artigo

A identidade usa roxo, verde-água e laranja para manter continuidade visual
com as Figuras 2 e 3 do artigo. A aplicação implementada não replica os
mockups literalmente: preserva texto ampliado, fluxo real, estados de erro,
minimização de dados e remoção do vídeo após o processamento. A tela inicial
destaca exercício, progresso e acessos rápidos; métricas usam cartões; o
bem-estar combina ícone e rótulo textual; e a lista profissional apresenta
sessões e adesão diretamente em cada paciente.

### Regras de contraste

- Texto normal: mínimo de 4,5:1.
- Texto grande: mínimo de 3:1, mas preferir 4,5:1 sempre que possível.
- Ícones informativos, bordas essenciais e indicadores de foco: mínimo de 3:1 contra o fundo adjacente.
- Não presumir que uma cor aprovada funciona sobre qualquer fundo.
- Recalcular o contraste sempre que uma cor ou fundo for alterado.
- Cores desabilitadas não podem esconder informações necessárias para concluir uma tarefa.

## Tipografia

Usar a fonte padrão do sistema no Flutter para reduzir dependências e preservar familiaridade: Roboto no Android e San Francisco no iOS. Não usar fontes decorativas.

| Estilo | Tamanho | Peso | Altura de linha | Uso |
|---|---:|---:|---:|---|
| Título principal | 28 sp | 700 | 1,3 | Título único da tela |
| Título de seção | 24 sp | 700 | 1,3 | Divisões principais |
| Subtítulo | 20 sp | 600 | 1,4 | Grupos de conteúdo |
| Corpo | 18 sp | 400 | 1,5 | Texto padrão preferencial |
| Corpo compacto | 16 sp | 400 | 1,5 | Informações secundárias |
| Rótulo de botão | 18 sp | 600 | 1,3 | Ações |
| Legenda | 14 sp | 400 | 1,5 | Uso excepcional e não essencial |

### Regras tipográficas

- Permitir ampliação de texto pelo sistema sem cortar conteúdo.
- Evitar blocos extensos em caixa alta, itálico ou peso leve.
- Alinhar textos longos à esquerda.
- Usar frases curtas e linguagem simples.
- Não inserir texto essencial dentro de imagens.
- Não reduzir texto para fazê-lo caber; adaptar o componente.

## Ícones

- Utilizar inicialmente os ícones do Material disponíveis no Flutter.
- Usar tamanho visual de 24 dp como padrão.
- Garantir área interativa mínima de 48×48 dp.
- Acompanhar ícones de ação com rótulo textual visível sempre que possível.
- Fornecer descrição semântica para leitores de tela.
- Não usar ícones ambíguos sem texto, especialmente em ações clínicas, gravação, envio, erro ou cancelamento.
- Manter o mesmo ícone para a mesma ação em todas as telas.

## Componentes e estados

Todo componente interativo deve prever:

- padrão;
- foco;
- pressionado;
- carregamento;
- desabilitado;
- sucesso;
- erro.

Botões principais devem ter altura mínima de 56 dp e largura adequada ao texto. Campos, cartões e controles devem respeitar área de toque mínima de 48×48 dp e espaçamento de pelo menos 8 dp entre alvos interativos.

## Mensagens

| Estado | Ícone + título sugerido | Exemplo de mensagem |
|---|---|---|
| Processamento | Indicador + “Analisando movimento” | “Aguarde enquanto processamos o vídeo.” |
| Inconclusivo | Ícone informativo + “Não foi possível analisar” | “Tente novamente seguindo as orientações.” |
| Atenção | Ícone de atenção + “Sessão requer revisão” | “Foi identificado um padrão que merece atenção.” |
| Erro | Ícone de erro + “Não foi possível concluir” | “Verifique sua conexão e tente novamente.” |
| Sucesso | Ícone de confirmação + “Sessão registrada” | “O resultado foi salvo no histórico.” |

Mensagens não devem diagnosticar, declarar segurança médica ou responsabilizar o paciente pelo erro.

## Implementação no Flutter

Centralizar as definições em componentes de tema, sem cores ou estilos espalhados diretamente pelas telas:

```text
frontend/lib/theme/
├── app_colors.dart
├── app_typography.dart
├── app_spacing.dart
├── app_icons.dart
└── app_theme.dart
```

Criar componentes reutilizáveis para botões, campos, cartões de estado, mensagens e cabeçalhos. Qualquer exceção ao sistema visual deve ser documentada.

## Validação

- Validar contraste dos pares efetivamente renderizados.
- Testar ampliação de texto e diferentes dimensões de tela.
- Testar navegação por leitor de tela e ordem de foco.
- Verificar áreas de toque em dispositivo ou emulador.
- Conferir que estados continuam compreensíveis em escala de cinza.
- Registrar os resultados da validação em [PROGRESSO.md](./PROGRESSO.md).
