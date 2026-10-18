# Arquitetura do Movere

Este documento registra as decisões de arquitetura e a organização técnica do projeto.

O documento [SISTEMA.md](./SISTEMA.md) é a fonte de verdade dos requisitos. Este documento somente detalha como esses requisitos serão organizados tecnicamente.

## Padrão arquitetural adotado

O projeto não utilizará MVC clássico como padrão único. A divisão por responsabilidades é mais adequada às tecnologias escolhidas:

- No Flutter: apresentação, componentes, gerenciamento de estado, modelos e serviços.
- No FastAPI: rotas, esquemas de entrada e saída, serviços, modelos, análise de visão computacional e utilitários.
- A lógica de negócio permanece nos serviços; rotas e telas não devem concentrar regras.
- Os módulos de análise permanecem independentes da API e da interface.

Essa organização preserva os benefícios do MVC, como separação de responsabilidades e facilidade de testes, sem forçar controladores e visualizações onde esse formato não corresponde naturalmente ao Flutter ou ao FastAPI.

---

## Visão geral

```
┌─────────────────────────────────────────────────────────┐
│                   CLIENTE Flutter                        │
│  (Paciente / Fisioterapeuta)                            │
│  ├── Autenticação (Firebase)                            │
│  ├── Visualização (UI/UX)                               │
│  ├── Captura de Vídeo                                   │
│  └── Comunicação HTTP (FastAPI)                         │
└────────────────┬──────────────────────────────────────────┘
                 │ REST API (JSON)
                 ↓
┌─────────────────────────────────────────────────────────┐
│                  SERVIDOR FastAPI                        │
│  ├── Autenticação (Firebase)                            │
│  ├── Roteamento                                         │
│  ├── Validação                                          │
│  ├── Persistência (Firestore)                           │
│  └── Orquestração de Análise                            │
└────────────────┬──────────────────────────────────────────┘
                 │
         ┌───────┼───────┐
         ↓       ↓       ↓
    ┌─────────┐ ┌──────────┐ ┌──────────────┐
    │ Firestore│ │Processador│ │Relatórios PDF│
    │ (Dados) │ │ de Vídeos │ │ (ReportLab) │
    └─────────┘ └────┬─────┘ └──────────────┘
                     ↓
            ┌────────────────────┐
            │   Análise (Python) │
            │ ┌────────────────┐ │
            │ │ MediaPipe      │ │
            │ │ OpenCV         │ │
            │ │ NumPy          │ │
            │ │ Regras Customizadas│
            │ └────────────────┘ │
            └────────────────────┘
                     ↓
            ┌────────────────────┐
            │ Resultados (JSON)  │
            │ ├── Repetições     │
            │ ├── Amplitude      │
            │ ├── Compensações   │
            │ └── Métricas       │
            └────────────────────┘
```

---

## Estrutura de diretórios

As árvores abaixo descrevem a separação lógica pretendida, não uma lista literal de todos os arquivos. O estado implementado deve ser conferido em [PROGRESSO.md](./PROGRESSO.md); serviços menores podem permanecer consolidados enquanto conservarem as responsabilidades e os testes definidos aqui.

### Frontend (Flutter)

```
frontend/
├── lib/
│   ├── main.dart                          # Entry point
│   │
│   ├── screens/                           # Telas da aplicação
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── splash_screen.dart
│   │   │
│   │   ├── patient/                       # Telas do paciente
│   │   │   ├── home_screen.dart
│   │   │   ├── exercise_plan_screen.dart
│   │   │   ├── exercise_detail_screen.dart
│   │   │   ├── preparation_screen.dart
│   │   │   ├── recording_screen.dart
│   │   │   ├── processing_screen.dart
│   │   │   ├── result_screen.dart
│   │   │   ├── history_screen.dart
│   │   │   ├── progress_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   └── reports_screen.dart
│   │   │
│   │   └── therapist/                    # Telas do fisioterapeuta
│   │       ├── dashboard_screen.dart
│   │       ├── patients_list_screen.dart
│   │       ├── patient_detail_screen.dart
│   │       ├── sessions_screen.dart
│   │       ├── progress_screen.dart
│   │       ├── reports_screen.dart
│   │       └── notes_screen.dart
│   │
│   ├── widgets/                           # Componentes reutilizáveis
│   │   ├── common/
│   │   │   ├── custom_button.dart
│   │   │   ├── custom_text_field.dart
│   │   │   ├── loading_indicator.dart
│   │   │   ├── error_dialog.dart
│   │   │   └── success_dialog.dart
│   │   │
│   │   └── accessibility/
│   │       ├── accessible_button.dart
│   │       ├── accessible_text.dart
│   │       ├── high_contrast_theme.dart
│   │       └── large_text_widget.dart
│   │
│   ├── models/                            # Modelos de dados
│   │   ├── user_model.dart
│   │   ├── patient_model.dart
│   │   ├── therapist_model.dart
│   │   ├── exercise_model.dart
│   │   ├── session_model.dart
│   │   ├── analysis_result_model.dart
│   │   └── metric_model.dart
│   │
│   ├── services/                          # Serviços da aplicação
│   │   ├── api/
│   │   │   ├── api_client.dart            # Cliente HTTP (Dio)
│   │   │   ├── auth_api.dart
│   │   │   ├── patient_api.dart
│   │   │   ├── therapist_api.dart
│   │   │   ├── exercise_api.dart
│   │   │   ├── session_api.dart
│   │   │   └── analysis_api.dart
│   │   │
│   │   ├── auth/
│   │   │   ├── auth_service.dart          # Firebase Auth
│   │   │   └── auth_provider.dart
│   │   │
│   │   ├── storage/
│   │   │   ├── local_storage.dart         # SharedPreferences
│   │   │   └── video_storage.dart
│   │   │
│   │   └── video/
│   │       ├── video_capture_service.dart
│   │       ├── video_gallery_service.dart
│   │       └── video_processor_service.dart
│   │
│   ├── state_management/                  # Gerenciamento de estado (Provider)
│   │   ├── auth_provider.dart
│   │   ├── patient_provider.dart
│   │   ├── therapist_provider.dart
│   │   ├── exercise_provider.dart
│   │   ├── session_provider.dart
│   │   └── notification_provider.dart
│   │
│   ├── routes/
│   │   └── app_routes.dart                # Definição de rotas
│   │
│   ├── theme/
│   │   ├── colors.dart
│   │   ├── text_styles.dart
│   │   └── app_theme.dart                 # Tema com acessibilidade
│   │
│   └── utils/
│       ├── constants.dart
│       ├── validators.dart
│       ├── logger.dart
│       └── helpers.dart
│
├── pubspec.yaml                           # Dependências Flutter
├── pubspec.lock
└── README.md
```

### Backend (FastAPI)

```
backend/
├── main.py                                # Entry point
├── requirements.txt                       # Dependências Python
│
├── app/
│   ├── __init__.py
│   │
│   ├── config.py                          # Configurações (dev, prod)
│   │
│   ├── routes/                            # Endpoints da API
│   │   ├── __init__.py
│   │   ├── auth.py                        # POST /auth/login, /auth/register
│   │   ├── patients.py                    # GET/POST /patients
│   │   ├── therapists.py                  # GET/POST /therapists
│   │   ├── exercises.py                   # GET /exercises
│   │   ├── sessions.py                    # GET/POST /sessions
│   │   ├── analysis.py                    # POST /analysis (upload vídeo)
│   │   ├── progress.py                    # GET /progress
│   │   └── reports.py                     # GET /reports
│   │
│   ├── services/                          # Lógica de negócio
│   │   ├── __init__.py
│   │   ├── auth_service.py                # Autenticação
│   │   ├── firebase_service.py            # Conexão Firestore
│   │   ├── patient_service.py             # Lógica de paciente
│   │   ├── therapist_service.py           # Lógica de fisioterapeuta
│   │   ├── exercise_service.py            # Gerenciamento de exercícios
│   │   ├── session_service.py             # Gerenciamento de sessões
│   │   ├── analysis_service.py            # Orquestração de análise
│   │   ├── report_service.py              # Geração de relatórios
│   │   └── notification_service.py        # Notificações (futuro)
│   │
│   ├── models/                            # Modelos de dados internos
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── patient.py
│   │   ├── therapist.py
│   │   ├── exercise.py
│   │   ├── session.py
│   │   ├── analysis_result.py
│   │   └── metric.py
│   │
│   ├── schemas/                           # Schemas para validação (Pydantic)
│   │   ├── __init__.py
│   │   ├── user_schema.py
│   │   ├── auth_schema.py
│   │   ├── patient_schema.py
│   │   ├── therapist_schema.py
│   │   ├── exercise_schema.py
│   │   ├── session_schema.py
│   │   ├── analysis_schema.py
│   │   ├── metric_schema.py
│   │   └── report_schema.py
│   │
│   ├── analysis/                          # Motor de análise de vídeos
│   │   ├── __init__.py
│   │   │
│   │   ├── base_analyzer.py               # Classe base
│   │   │   └── BaseAnalyzer (classe abstrata)
│   │   │       ├── process_video()
│   │   │       ├── extract_landmarks()
│   │   │       └── analyze()
│   │   │
│   │   ├── exercises/                     # Analisadores de exercícios
│   │   │   ├── __init__.py
│   │   │   ├── elbow_flexion.py           # Flexão de cotovelo
│   │   │   │   └── ElbowFlexionAnalyzer
│   │   │   ├── squat.py                   # Agachamento
│   │   │   │   └── SquatAnalyzer
│   │   │   └── pinch.py                   # Pinça
│   │   │       └── PinchAnalyzer
│   │   │
│   │   ├── mediapipe_processor.py         # Processamento com MediaPipe
│   │   │   └── MediaPipeProcessor
│   │   │       ├── detect_landmarks()
│   │   │       ├── get_pose_landmarks()
│   │   │       ├── get_hand_landmarks()
│   │   │       └── visualize()
│   │   │
│   │   ├── metrics.py                     # Cálculo de métricas
│   │   │   └── MetricsCalculator
│   │   │       ├── calculate_angle()
│   │   │       ├── calculate_amplitude()
│   │   │       ├── calculate_symmetry()
│   │   │       └── calculate_speed()
│   │   │
│   │   ├── repetition_counter.py          # Contador de repetições
│   │   │   └── RepetitionCounter
│   │   │       ├── count_repetitions()
│   │   │       ├── identify_phases()
│   │   │       └── get_rep_quality()
│   │   │
│   │   ├── compensation_detector.py       # Detector de compensações
│   │   │   └── CompensationDetector
│   │   │       ├── detect_shoulder_elevation()
│   │   │       ├── detect_trunk_lean()
│   │   │       └── detect_asymmetry()
│   │   │
│   │   ├── report_generator.py            # Gerador de relatórios
│   │   │   └── ReportGenerator (ReportLab)
│   │   │       ├── generate_individual_pdf()
│   │   │       └── generate_longitudinal_pdf()
│   │   │
│   │   └── video_processor.py             # Processamento de vídeo
│   │       └── VideoProcessor
│   │           ├── load_video()
│   │           ├── extract_frames()
│   │           ├── process_frame()
│   │           └── cleanup_temp_files()
│   │
│   ├── utils/                             # Utilitários
│   │   ├── __init__.py
│   │   ├── validators.py                  # Validações customizadas
│   │   ├── logger.py                      # Logging
│   │   ├── exceptions.py                  # Exceções customizadas
│   │   ├── constants.py                   # Constantes
│   │   ├── decorators.py                  # Decoradores (auth, etc)
│   │   ├── file_handler.py                # Manipulação de arquivos
│   │   └── helpers.py                     # Funções auxiliares
│   │
│   └── middleware/                        # Middleware
│       ├── __init__.py
│       ├── auth_middleware.py
│       ├── error_handler.py
│       └── cors_middleware.py
│
├── tests/                                 # Testes
│   ├── test_auth.py
│   ├── test_analysis.py
│   ├── test_elbow_flexion.py
│   └── ...
│
└── README.md
```

---

## Fluxos principais

### 1. Fluxo do Paciente - Análise de Exercício

```
PACIENTE (Flutter)
    │
    ├─→ Login
    ├─→ Visualiza plano
    ├─→ Seleciona exercício
    ├─→ Vê instruções
    ├─→ Grava/seleciona vídeo
    │
    └─→ ENVIO DO VÍDEO
            │
            ↓
    SERVIDOR (FastAPI)
            │
            ├─→ Autentica requisição
            ├─→ Valida vídeo
            ├─→ Armazena temporariamente
            ├─→ Inicia processamento
            │
            └─→ ANÁLISE DO VÍDEO
                    │
                    ├─→ Extrai frames
                    ├─→ Detecta landmarks (MediaPipe)
                    ├─→ Calcula métricas
                    ├─→ Conta repetições
                    ├─→ Detecta compensações
                    ├─→ Valida qualidade da análise
                    │
                    └─→ Gera resultado (JSON)
                            │
                            ├─→ Armazena em Firestore
                            ├─→ Remove vídeo temporário
                            │
                            └─→ Retorna para Flutter
                                    │
                                    ↓
    PACIENTE (Flutter)
            │
            ├─→ Visualiza resultado
            ├─→ Vê métricas
            ├─→ Recebe feedback
            │
            └─→ Resultado armazenado no histórico
```

### 2. Fluxo do Fisioterapeuta - Acompanhamento Longitudinal

```
FISIOTERAPEUTA (Flutter)
    │
    ├─→ Login
    ├─→ Vê dashboard
    ├─→ Seleciona paciente
    │
    └─→ VISUALIZAÇÃO DO PERFIL
            │
            ├─→ Vê dados do paciente
            ├─→ Vê plano de exercícios
            ├─→ Vê histórico de sessões
            │
            └─→ ANÁLISE DE EVOLUÇÃO
                    │
                    ├─→ Visualiza métricas gerais
                    ├─→ Vê gráficos de progresso
                    ├─→ Identifica padrões
                    ├─→ Vê compensações frequentes
                    │
                    └─→ AÇÃO
                            │
                            ├─→ Adiciona observações
                            ├─→ Ajusta plano
                            ├─→ Gera relatório PDF
                            │
                            └─→ Dados sincronizados
```

---

## Autenticação e autorização

### Fluxo de Autenticação

```
CLIENTE
    │
    ├─→ Inserir email/senha
    │
    └─→ POST /auth/login
            │
            ↓
    SERVIDOR
            │
            ├─→ Verificar credenciais (Firebase Auth)
            ├─→ Gerar token JWT
            ├─→ Buscar tipo de usuário (Firestore)
            │
            └─→ Retornar {token, user_type, user_data}
                    │
                    ↓
    CLIENTE
            │
            ├─→ Salvar token (SharedPreferences)
            ├─→ Salvar tipo de usuário
            ├─→ Redirecionar com base no tipo
            │
            └─→ Adicionar token ao header (Authorization: Bearer {token})
```

### Autorização por Recurso

```
- Paciente só acessa:
  - Dados pessoais do próprio paciente
  - Exercícios atribuídos a ele
  - Sessões próprias
  - Resultado de análises próprias

- Fisioterapeuta acessa:
  - Dados pessoais próprios
  - Pacientes vinculados a ele
  - Sessões desses pacientes
  - Resultados de análise desses pacientes
```

---

## Decisões de acessibilidade

### 1. Componentes Acessíveis

Todos os componentes devem ser criados com acessibilidade em mente:

- Tamanho mínimo de toque: 48×48 dp
- Contraste mínimo: 4.5:1
- Fonte mínima: 14 sp (padrão), ajustável pelo usuário
- Labels descritivas para todos os componentes
- Feedback claramente audível e visual

### 2. Navegação

- Navegação por guias (tab order) clara
- Suporte a leitores de tela
- Atalhos de teclado quando possível
- Breadcrumbs em navegação profunda

### 3. Instruções de Exercício

Cada exercício deve ter:

```
ESTRUTURA DE INSTRUÇÕES

1. PREPARAÇÃO
   - Título grande
   - Imagem/vídeo de demonstração
   - Posição recomendada
   - Cuidados importantes (ícones + texto)

2. DURANTE O EXERCÍCIO
   - Feedback visual contínuo
   - Indicação se fora do enquadramento
   - Contadora de repetições (grande)
   - Evitar texto pequeno

3. RESULTADO
   - Resumo simples (sucesso/aviso/análise inconclusiva)
   - Números grandes
   - Gráfico simples se houver
   - Próximos passos claros
```

---

## Organização da análise de vídeo

### Pipeline de Processamento

```
VÍDEO
  ↓
[VideoProcessor]
  ├─→ Validar formato
  ├─→ Extrair frames (30 fps recomendado)
  └─→ Gerar lista de frames
        ↓
[MediaPipeProcessor]
  ├─→ Para cada frame:
  │   ├─→ Detectar pose landmarks
  │   ├─→ Detectar hand landmarks
  │   └─→ Armazenar em array
  └─→ Gerar sequência de landmarks
        ↓
[ExerciseAnalyzer] (p.ex., ElbowFlexionAnalyzer)
  ├─→ Para cada frame:
  │   ├─→ Calcular ângulos (ElbowFlexion)
  │   ├─→ Detectar compensações
  │   ├─→ Validar postura
  │   └─→ Identificar fase
  └─→ Gerar metrics por frame
        ↓
[RepetitionCounter]
  ├─→ Agrupar frames por repetição
  ├─→ Calcular qualidade de cada rep
  └─→ Gerar contagem final
        ↓
[MetricsCalculator]
  ├─→ Amplitude média
  ├─→ Simetria (se aplicável)
  ├─→ Velocidade
  ├─→ Frequência de compensações
  └─→ Score geral
        ↓
[QualityValidator]
  ├─→ Verificar se análise é confiável
  ├─→ Definir nível de confiança
  └─→ Retornar "OK" ou "Análise Inconclusiva"
        ↓
RESULTADO (JSON)
```

### Estrutura do Resultado

```json
{
  "session_id": "uuid",
  "exercise_type": "elbow_flexion",
  "timestamp": "2026-10-02T10:30:00Z",

  "analysis_status": "success" | "inconclusive" | "failed",
  "confidence": 0.95,

  "metrics": {
    "total_repetitions": 10,
    "average_amplitude": 85.5,
    "completed_reps": 9,
    "incomplete_reps": 1,
    "average_rom_degrees": 85.5,
    "asymmetry_percent": 5.2,
    "execution_time_seconds": 45.3,
    "average_speed": "normal"
  },

  "per_repetition": [
    {
      "rep_number": 1,
      "amplitude_degrees": 85.0,
      "rom_achieved_percent": 100,
      "compensations": ["slight_shoulder_elevation"],
      "quality": "good",
      "duration_seconds": 4.5
    },
    ...
  ],

  "compensations_detected": [
    {
      "type": "shoulder_elevation",
      "frequency": 3,
      "severity": "mild",
      "frames": [45, 78, 120]
    },
    ...
  ],

  "alerts": [
    {
      "type": "incomplete_range",
      "message": "Amplitude menor que o esperado na repetição 5",
      "severity": "warning"
    }
  ],

  "therapist_note_recommendations": [
    "Prestar atenção na amplitude da repetição 5",
    "Possível elevação de ombro detectada em 3 repetições"
  ]
}
```

---

## Dados longitudinais

### Armazenamento no Firestore

```
firestore/
  ├─ users/{uid}
  │   ├─ email, name, role, active
  │   └─ accessibilityPreferences
  ├─ careLinks/{therapistId}_{patientId}
  │   ├─ therapistId, therapistName, patientId
  │   └─ status: pending | accepted | rejected
  ├─ plans/{patientId}_{exerciseType}
  │   ├─ patientId, therapistId, exerciseType, title
  │   └─ instructions, sessionsPerWeek, targetRepetitions, active
  ├─ sessions/{analysisId}
  │   ├─ patientId, exerciseType, status, createdAt
  │   ├─ repetitions, averageAmplitudeDegrees, confidence
  │   └─ requiresReview, reviewedAt, reviewedBy, simulated, message
  └─ notes/{noteId}
      ├─ patientId, therapistId, text, createdAt
      └─ visibleToPatient
```

---

## Integração com o Firebase

### Firebase Authentication

- Email/Senha
- Integração com Flutter Firebase plugin
- ID tokens gerados pelo Firebase Authentication e enviados ao FastAPI

### Firestore

- Armazenamento de dados estruturados
- Queries para histórico
- Índices para performance
- Prescrições são versionadas a cada gravação. A sessão mantém uma fotografia
  das metas utilizadas, evitando que uma edição posterior altere a
  interpretação histórica.
- A meta individual de amplitude permanece separada dos limiares técnicos de
  detecção. O fisioterapeuta pode ativar calibração experimental por exercício,
  dentro de faixas protegidas e mediante justificativa. O plano é versionado e
  a sessão registra os valores efetivamente utilizados. Para pinça, não se usa
  meta em graus porque a métrica disponível é uma distância normalizada 2D.

### Segurança (Firestore Rules)

- O paciente acessa o próprio perfil, plano, sessões e orientações visíveis.
- O fisioterapeuta acessa dados clínicos somente após um vínculo com estado `accepted`.
- Convites começam como `pending` e somente o paciente destinatário pode aceitar ou recusar.
- Alteração de papel, exclusão pelo cliente e coleções não declaradas permanecem bloqueadas.
- A implementação normativa e publicada está em `frontend/firestore.rules`; não duplicar regras parciais neste documento.

---

## Interface e tema

### Paleta de cores, tipografia e ícones

A definição normativa, incluindo os pares de contraste verificados, está em [SISTEMA_VISUAL.md](./SISTEMA_VISUAL.md). O código correspondente está em `frontend/lib/theme/`; não manter uma segunda paleta divergente neste documento.

### Tipografia

- **Heading 1**: 28 sp, Bold
- **Heading 2**: 24 sp, Bold
- **Heading 3**: 20 sp, Semibold
- **Body**: 16 sp, Regular
- **Caption**: 14 sp, Regular
- **Small**: 12 sp, Regular

### Espaçamento

- xs: 4 dp
- sm: 8 dp
- md: 16 dp
- lg: 24 dp
- xl: 32 dp

---

## Testes

### Estratégia de Testes

```
FRONTEND (Flutter)
  ├─ Unit tests
  │   └─ Validadores, formatadores, etc.
  │
  ├─ Widget tests
  │   └─ Componentes individuais
  │
  └─ Integration tests
      └─ Fluxos completos

BACKEND (FastAPI)
  ├─ Unit tests
  │   └─ Services, utils
  │
  ├─ Integration tests
  │   └─ Endpoints, banco de dados
  │
  └─ Analysis tests
      └─ Exercícios com vídeos de teste
```

---

## Convenções de código

### Flutter/Dart

- Nomes de classe: `CapitalCase`
- Nomes de função/variável: `camelCase`
- Constantes: `lowerCamelCase`
- Arquivo: `snake_case.dart`

### Python

- Classe: `CapitalCase`
- Função: `snake_case`
- Constante: `UPPER_SNAKE_CASE`
- Arquivo: `snake_case.py`

---

## Execução e distribuição

### Desenvolvimento

```
BACKEND (Local):
  python main.py  # Executa em localhost:8000

BACKEND (Docker opcional):
  docker compose up --build backend

FRONTEND (Local):
  flutter run     # Conecta ao backend local
```

O contêiner deve abranger somente o backend FastAPI e suas dependências de análise. O Flutter permanece fora do Docker e é executado no computador, emulador ou dispositivo físico. A execução direta com Python continuará disponível.

O Docker será utilizado para reprodução do ambiente local, sem exigir hospedagem paga. Credenciais do Firebase devem ser fornecidas em tempo de execução e nunca incorporadas à imagem.

### Distribuição futura

- Frontend: Play Store / App Store
- Banco de dados: Firestore (já escalável)
- Backend: forma de distribuição a definir, preservando a exigência do protótipo de não utilizar hospedagem paga durante o desenvolvimento

---

## Documentação

### Documentação de API

- OpenAPI/Swagger automático via FastAPI
- Disponível em `http://localhost:8000/docs`

### Documentação de Código

- Docstrings em Python
- Comments descritivos em Dart
- README em cada módulo

### Documentação de Análise

- Documentar thresholds de cada exercício
- Documentar métricas calculadas
- Documentar compensações detectadas

---

**Versão**: 1.0
**Atualizado**: Outubro 2026
**Próxima revisão**: Após FASE 1
