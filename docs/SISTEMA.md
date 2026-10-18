# Sistema de telereabilitação pós-AVC

## Título do projeto

**Uma Aplicação para Monitoramento de Progresso em Terapias de Reabilitação Pós-AVC por meio de Visão Computacional**

## Escopo

O Movere é um protótipo acadêmico. Não foi projetado para diagnosticar doenças, substituir o fisioterapeuta ou confirmar a segurança clínica de uma execução.

A visão computacional fornece medidas e alertas técnicos. A interpretação e a decisão clínica permanecem sob responsabilidade do profissional.

## 1. Objetivo geral

Desenvolver uma aplicação móvel acessível de telereabilitação pós-AVC que permita:

### Paciente
- Acessar seu plano de exercícios
- Receber instruções claras para cada exercício
- Executar os exercícios utilizando a câmera do dispositivo
- Registrar vídeos das sessões
- Analisar automaticamente os movimentos por visão computacional
- Identificar possíveis erros de execução e compensações
- Alertar quando houver uma execução inadequada ou uma condição que possa aumentar o risco de acidente
- Registrar o histórico das sessões
- Acompanhar a evolução do paciente ao longo do tempo

### Fisioterapeuta
- Acompanhar seus pacientes remotamente
- Visualizar resultados individuais e tendências gerais
- Identificar pacientes que necessitam de maior atenção
- Registrar observações e orientações profissionais
- Gerar relatórios organizados sobre a evolução

O foco é o acompanhamento longitudinal, e não somente a análise isolada de uma sessão.

---

## 2. Arquitetura

### Tecnologias

```
        Flutter (Aplicativo Móvel)
               ↓
        FastAPI REST API
               ↓
      Serviço Python de Análise
      ├── OpenCV
      ├── MediaPipe
      ├── NumPy
      └── Regras dos Exercícios
               ↓
        Resultados da Análise
               ↓
   Firestore / Relatório PDF
               ↓
        Flutter (Visualização)
```

### Componentes

**Aplicativo:**
- Flutter
- Aplicativo móvel para pacientes e profissionais

**Backend:**
- Python
- FastAPI
- API REST

**Visão computacional:**
- MediaPipe
- OpenCV

**Análise numérica:**
- NumPy

**Relatórios:**
- ReportLab
- Matplotlib (somente quando necessário para gráficos)

**Autenticação e persistência:**
- Firebase Authentication
- Cloud Firestore

Durante o desenvolvimento e a apresentação, o backend pode ser executado localmente. Não há necessidade de contratar hospedagem para esse uso.

---

## 3. Perfis de usuário

### 3.1 Paciente

O paciente deve conseguir:

- Fazer login
- Visualizar seu perfil
- Visualizar seu plano de exercícios
- Visualizar instruções
- Iniciar uma sessão
- Posicionar o dispositivo corretamente
- Gravar ou selecionar um vídeo
- Enviar o vídeo para análise
- Acompanhar o processamento
- Visualizar o resultado
- Visualizar seu histórico
- Acompanhar sua própria evolução
- Acessar relatórios
- Visualizar orientações do fisioterapeuta

### 3.2 Fisioterapeuta

O fisioterapeuta deve conseguir:

- Fazer login
- Visualizar seus pacientes
- Cadastrar/vincular pacientes
- Visualizar o perfil de cada paciente
- Definir ou acompanhar prescrições individualizadas com exercício, séries,
  repetições, frequência semanal, lado trabalhado, cadência, intervalo,
  período, orientações e meta opcional de amplitude quando tecnicamente
  aplicável
- Ativar, quando necessário, uma calibração experimental dos limiares de ciclo,
  separada da meta terapêutica, dentro de faixas protegidas e com justificativa
  profissional registrada
- Acompanhar sessões realizadas
- Visualizar resultados individuais
- Visualizar evolução ao longo do tempo
- Comparar sessões
- Visualizar gráficos
- Registrar observações
- Registrar orientações
- Acompanhar adesão aos exercícios
- Identificar sessões com possíveis problemas
- Registrar início e fim de cada repetição, amplitude, duração e classificação
  técnica por repetição
- Destacar no vídeo privado os segundos da melhor repetição, movimentos abaixo
  da referência técnica e possíveis desvios observáveis
- Gerar até quatro capturas compactadas dos momentos destacados e, somente com
  consentimento do paciente, armazená-las de forma privada no Firestore para
  revisão profissional e inclusão no PDF
- Comparar lado afetado e não afetado somente quando ambos estiverem visíveis
  e o lado afetado estiver informado no perfil
- Priorizar pacientes sem atividade recente, com poucas sessões na semana,
  dificuldades técnicas repetidas, resultados abaixo da prescrição, relatos
  altos de dor/cansaço ou tendência de queda nas repetições
- Gerar relatórios

---

## 4. Acessibilidade

A acessibilidade deve ser uma característica central do sistema.

### Padrões de Conformidade

- Seguir WCAG 2.1 nível AA sempre que aplicável

### Limitações Esperadas (Pós-AVC)

Considerar especialmente:
- Hemiparesia
- Tremores
- Dificuldade de coordenação
- Dificuldade de precisão motora
- Alterações visuais
- Dificuldade cognitiva
- Dificuldade de leitura
- Dificuldade de compreensão de instruções
- Fadiga

### Diretrizes de Interface

- Botões grandes
- Área de toque mínima de 48×48 dp
- Contraste adequado
- Textos legíveis
- Linguagem simples
- Instruções curtas
- Uma ação principal por tela quando possível
- Navegação simples
- Poucos elementos simultâneos
- Feedback visual claro
- Mensagens de erro compreensíveis
- Confirmação de ações importantes
- Possibilidade de repetir instruções
- Indicação clara do estado do processamento
- Não depender exclusivamente de cores
- Utilizar ícones + texto
- Evitar informações importantes apenas por áudio
- Evitar excesso de elementos visuais

### Experiência do Exercício

#### ANTES DO EXERCÍCIO:
- Explicar o movimento
- Mostrar uma demonstração
- Explicar o posicionamento da câmera
- Explicar a posição inicial
- Informar cuidados importantes
- Solicitar confirmação de que o ambiente está preparado
- Tornar toda a área de cada confirmação tocável, com ícone, texto e estado
  explícito, sem exigir precisão para acertar uma caixa pequena

#### DURANTE:
- Mostrar orientação visual
- Informar quando o corpo estiver fora da área adequada para análise
- Evitar mensagens excessivamente complexas

#### DEPOIS:
- Apresentar resultado de forma simples
- Explicar o que foi detectado
- Mostrar evolução
- Permitir consultar detalhes

---

## 5. SEGURANÇA DO PACIENTE

A segurança deve ser considerada desde o desenho do sistema.

### Limites do sistema

O sistema não deve afirmar que um exercício é seguro ou inseguro do ponto de vista médico.

### Comportamento esperado

Em vez disso, deve **identificar condições observáveis** relacionadas à execução e **emitir alertas apropriados**.

### Exemplos de Condições Monitoradas

- Paciente muito fora da área de enquadramento
- Câmera posicionada inadequadamente
- Corpo parcialmente fora da imagem
- Movimento incompatível com o padrão esperado
- Compensação excessiva detectável pelo algoritmo
- Perda dos landmarks
- Movimento muito rápido para análise confiável
- Postura inicial inadequada
- Execução interrompida
- Repetição incompleta

### Quando a Análise Não For Confiável

O resultado não pode ser apresentado como preciso quando faltarem dados confiáveis.

**Mostrar** algo como:

> "Não foi possível analisar adequadamente este movimento. Tente novamente seguindo as orientações."

### Para Situações que Possam Exigir Avaliação Profissional

> "Foi identificado um padrão de movimento que merece atenção. Consulte as orientações do seu fisioterapeuta."

**NUNCA criar diagnósticos automáticos.**

---

## 6. PREVENÇÃO DE EXECUÇÕES INCORRETAS

O sistema deve utilizar visão computacional para auxiliar na **identificação de padrões de movimento previamente definidos**.

### Fluxo de Análise

```
vídeo
  ↓
frames
  ↓
landmarks
  ↓
métricas
  ↓
regras do exercício
  ↓
resultado
```

### Capacidades Esperadas

- Detectar posição inicial
- Acompanhar o movimento
- Identificar fases
- Contar repetições
- Calcular amplitude
- Identificar assimetrias quando aplicável
- Identificar compensações previamente definidas
- Indicar quando uma repetição não atende aos critérios estabelecidos
- Fornecer feedback após a análise

### Importante

- **Não inventar critérios clínicos**
- Os critérios devem ser **parametrizados e documentados**
- A calibração individual pode alterar somente os limiares técnicos de
  reconhecimento do ciclo. Deve manter valores padrão, faixas protegidas,
  justificativa, versão do plano e fotografia dos valores utilizados na sessão.
- Metas da prescrição e limiares do algoritmo são conceitos distintos.

---

## 7. EXERCÍCIOS

O sistema deve inicialmente trabalhar com:

1. **Flexão de cotovelo**
2. **Agachamento**
3. **Pinça**

### Estrutura de Módulos

```
analysis/
    exercises/
        elbow_flexion.py
        squat.py
        pinch.py

    mediapipe_processor.py
    metrics.py
    repetition_counter.py
    compensation_detector.py
    report_generator.py
```

### Componentes de Cada Exercício

Cada exercício deve possuir:

- Landmarks necessários
- Métricas
- Thresholds
- Estados do movimento
- Regras de repetição
- Regras de compensação
- Critérios para considerar a análise inconclusiva

---

## 8. ACOMPANHAMENTO LONGITUDINAL

Esta é uma parte **fundamental** do sistema.

### Abordagem descartada

Não querer apenas: "Hoje o paciente fez 10 repetições."

### O que FAZER

Querer: "Como o paciente está evoluindo ao longo das sessões?"

### Dados a Registrar

Quando disponível:
- Data
- Exercício
- Número de repetições
- Amplitude
- Métricas de movimento
- Versão e limiares técnicos efetivamente utilizados
- Assimetria
- Compensações detectadas
- Duração
- Resultado da sessão
- Observações do profissional

### Visualizações

Criar gráficos de evolução com exemplos:
- Amplitude ao longo das sessões
- Número de repetições
- Frequência de compensações
- Simetria
- Adesão ao plano
- Quantidade de sessões realizadas

### Perspectivas

O sistema deve permitir visualizar:

- **SESSÃO INDIVIDUAL** (dados de uma execução específica)
- **EVOLUÇÃO GERAL** (tendências ao longo do tempo)

---

## 9. DASHBOARD DO FISIOTERAPEUTA

Criar uma visão geral dos pacientes.

### Informações por Paciente

- Nome
- Quantidade de sessões
- Última sessão
- Exercícios realizados
- Evolução recente
- Adesão
- Resultados que merecem atenção
- Observações recentes

### Filtros Disponíveis

- Pacientes
- Período
- Exercício
- Sessões pendentes de avaliação
- Sessões com alertas

### Navegação do Perfil do Paciente

```
PERFIL
  ↓
PLANO DE EXERCÍCIOS
  ↓
HISTÓRICO
  ↓
SESSÕES
  ↓
MÉTRICAS
  ↓
GRÁFICOS
  ↓
RELATÓRIOS
  ↓
OBSERVAÇÕES DO PROFISSIONAL
```

---

## 10. ACOMPANHAMENTO À DISTÂNCIA

O sistema deve facilitar o acompanhamento remoto.

### O Fisioterapeuta Deve Conseguir Visualizar

- Quando o paciente realizou a última sessão
- Frequência das sessões
- Evolução das métricas
- Exercícios realizados
- Possíveis dificuldades
- Sessões que precisam de revisão

### Linguagem Apropriada

O sistema pode destacar informações que merecem atenção, mas não deve classificar automaticamente o paciente como "grave", "pior" ou equivalente sem um critério clínico definido.

**Utilizar linguagem neutra:**

- "Sessão requer revisão"
- "Resultado fora do padrão definido para esta análise"
- "Análise inconclusiva"
- "Possível compensação detectada"

---

## 11. PLANO DE EXERCÍCIOS

O fisioterapeuta deve poder associar exercícios ao paciente.

### Atributos de um Exercício

Cada exercício pode possuir:

- Nome
- Descrição
- Instruções
- Quantidade recomendada
- Número de sessões
- Observações
- Orientação profissional

### Visualização do Paciente

O paciente visualiza somente os exercícios atribuídos a ele.

O sistema deve registrar a execução.

---

## 12. RELATÓRIO

Utilizar **ReportLab** para gerar PDF.

### Relatório Individual (Sessão)

O relatório deve apresentar:

- Identificação da sessão
- Paciente
- Data
- Exercício
- Repetições
- Métricas
- Compensações detectadas
- Observações
- Gráficos de evolução quando disponíveis

### Relatório Longitudinal

**Evolução do paciente no período selecionado**

Esse relatório deve apresentar os dados das várias sessões, **não apenas uma execução**.

---

## 13. PRIVACIDADE

Aplicar **princípio de minimização de dados**.

### Armazenamento de Vídeos

Não armazenar vídeos permanentemente sem necessidade.

Quando possível:

```
vídeo
  ↓
processamento
  ↓
resultados
  ↓
remoção do arquivo temporário
```

O compartilhamento com o fisioterapeuta é opcional e permanece desativado por
padrão. Há escolhas separadas para as capturas técnicas e para o vídeo completo.
As capturas JPEG compactadas ficam no Firestore e podem integrar o PDF. Quando
o paciente autoriza o vídeo completo, ele é cifrado no servidor com AES-256-GCM,
tem os metadados protegidos e fica disponível somente ao paciente e ao
fisioterapeuta escolhido por até 30 dias. O paciente pode removê-lo antes do
prazo. Data e versão do consentimento são registradas na sessão. A cópia
temporária usada pela análise continua sendo apagada ao final do processamento.

### Dados Estruturados

Firestore deve armazenar os dados estruturados necessários.

### Controle de Acesso

- Implementar autenticação e controle de acesso
- Paciente só pode visualizar seus próprios dados
- Fisioterapeuta só pode visualizar pacientes vinculados a ele

### Limite de verificação profissional do protótipo

O cadastro registra o número profissional informado pelo fisioterapeuta, mas o
protótipo acadêmico não consulta automaticamente o conselho profissional nem
atesta a validade desse registro. O vínculo só libera dados após aceite do
paciente. Uma implantação real exigiria verificação administrativa ou
integração com uma fonte oficial antes de habilitar o perfil profissional.

### Disclaimer Legal

Não afirmar conformidade legal definitiva apenas pela implementação técnica.

---

## 14. FASTAPI

Criar uma API organizada.

### Exemplos de Endpoints

```
POST /auth
GET /patients
GET /patients/{id}
GET /patients/{id}/sessions
GET /patients/{id}/progress
POST /sessions
POST /analysis
GET /analysis/{id}
GET /reports/{id}
```

Os nomes podem ser adaptados conforme a implementação.

### Estrutura de Diretórios

```
fastapi_backend/
    routes/
    services/
    models/
    schemas/
    analysis/
    utils/
```

### Responsabilidades

- A API é responsável pela comunicação
- A lógica de visão computacional permanece nos módulos de análise

---

## 15. FLUTTER

Organizar o aplicativo de forma escalável.

### Estrutura de Diretórios

```
lib/
    screens/
    widgets/
    models/
    services/
    auth/
    api/
    state_management/
    accessibility/
```

### Telas Iniciais - PACIENTE

- Login
- Home
- Meu plano
- Exercício
- Preparação
- Gravação
- Processamento
- Resultado
- Histórico
- Evolução
- Perfil

### Telas Iniciais - FISIOTERAPEUTA

- Login
- Dashboard
- Pacientes
- Perfil do paciente
- Plano
- Sessões
- Evolução
- Relatórios
- Observações

---

## 16. DESENVOLVIMENTO INCREMENTAL

As etapas devem ser concluídas e verificadas antes do início da seguinte.

### Fases de Desenvolvimento

0. Planejamento e análise do repositório, sem alterar código.
1. Aplicativo Flutter base com navegação e dados simulados.
2. Fluxo simulado do exercício de ponta a ponta.
3. API FastAPI básica com resposta simulada.
4. Visão computacional para flexão de cotovelo.
5. Primeira integração real entre Flutter, API e análise.
6. Agachamento e pinça em módulos independentes.
7. Histórico, gráficos e acompanhamento longitudinal.
8. Dashboard do fisioterapeuta.
9. Relatórios PDF individual e longitudinal.
10. Firebase Authentication, Firestore e persistência completa.

Cada fase deve terminar funcionando e ser registrada em [PROGRESSO.md](./PROGRESSO.md) antes do início da próxima. Os detalhes e critérios de conclusão estão em [PLANO_DESENVOLVIMENTO.md](./PLANO_DESENVOLVIMENTO.md).

---

## 17. REGRA FUNDAMENTAL PARA DESENVOLVIMENTO

Antes de escrever código:

1. Analise o repositório
2. Identifique o que já existe
3. Não apague código existente sem necessidade
4. Explique a arquitetura encontrada
5. Proponha a estrutura que será utilizada
6. Divida o desenvolvimento em etapas
7. Comece pela primeira etapa
8. Após cada etapa, informe:
   - Arquivos criados
   - Arquivos modificados
   - Funcionalidades implementadas
   - Como testar
   - Problemas encontrados

### Princípios Importantes

- **Não invente funcionalidades** que não foram solicitadas
- **Não invente critérios clínicos**
- **Não invente resultados de análise**
- **Não afirme** que o sistema possui precisão clínica sem testes que demonstrem isso

### Objetivo Final

Criar um **protótipo funcional, acessível e tecnicamente demonstrável** para o TCC, com arquitetura preparada para futura validação clínica.

---

## Próximos passos

1. Analisar o repositório atual
2. Identificar estrutura existente
3. Propor organização completa do projeto
4. Iniciar com FASE 1: Estrutura Flutter e Navegação
5. Complementar com infraestrutura backend (FastAPI)
6. Implementar funcionalidades incrementalmente

---

**Documento de Especificação - Projeto Movere**
**Versão 1.0 - Outubro 2026**
