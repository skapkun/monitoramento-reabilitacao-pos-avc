# API REST

Documentação dos padrões e endpoints da API FastAPI do Movere.

## Estado de implementação

Atualmente estão implementados `GET /health`, `POST /analysis`, `GET /analysis/{analysis_id}` e `POST /reports/longitudinal.pdf`. Autenticação e dados clínicos estruturados são tratados pelo Firebase Authentication e pelo Firestore no aplicativo. O FastAPI valida tokens Firebase quando iniciado com `AUTH_MODE=firebase`; no modo local padrão, `AUTH_MODE=disabled`, essa exigência fica explicitamente desativada.

---

## Convenções gerais

### Versionamento

```
Base URL (Desenvolvimento): http://localhost:8000
Usar v1, v2, etc para quebra de compatibilidade
```

### Formato de Resposta

**Sucesso (2xx)**:
```json
{
  "status": "success",
  "data": { ... },
  "message": "Operação realizada com sucesso"
}
```

**Erro (4xx, 5xx)**:
```json
{
  "status": "error",
  "error_code": "INVALID_REQUEST",
  "message": "Descrição do erro",
  "details": { ... }
}
```

### Autenticação

Quando `AUTH_MODE=firebase`, todos os endpoints de análise e relatório requerem:

```
Authorization: Bearer {jwt_token}
```

`GET /health` permanece público. A consulta de uma análise também verifica o proprietário que a criou e responde `404` para outro usuário, evitando revelar a existência do identificador.

### `POST /reports/longitudinal.pdf`

Recebe o nome do paciente e uma lista limitada a 500 sessões já autorizadas no cliente. Retorna um PDF descritivo (`application/pdf`) com resumo, gráfico longitudinal, métricas técnicas, bem-estar e revisão profissional. O documento informa explicitamente que não constitui laudo ou diagnóstico.

### Paginação

```
GET /resource?page=1&limit=10

Resposta:
{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 45,
    "pages": 5
  }
}
```

---

## Autenticação

O cadastro, login, recuperação e renovação do token são realizados diretamente pelo Firebase Authentication no aplicativo. As rotas `/auth/*` abaixo são referências conceituais antigas e **não estão implementadas no FastAPI**.

### `POST /auth/register`

Registrar novo usuário.

**Request:**
```json
{
  "email": "usuario@example.com",
  "password": "senha_forte_123",
  "name": "Nome Completo",
  "user_type": "patient" | "therapist"
}
```

**Response (201):**
```json
{
  "status": "success",
  "data": {
    "user_id": "uuid",
    "email": "usuario@example.com",
    "name": "Nome Completo",
    "user_type": "patient",
    "created_at": "2026-10-02T10:30:00Z"
  }
}
```

**Errors:**
- `400`: Email já existe
- `400`: Senha fraca
- `400`: Dados inválidos

---

### `POST /auth/login`

Fazer login.

**Request:**
```json
{
  "email": "usuario@example.com",
  "password": "senha_forte_123"
}
```

**Response (200):**
```json
{
  "status": "success",
  "data": {
    "user_id": "uuid",
    "token": "eyJhbGciOiJIUzI1...",
    "email": "usuario@example.com",
    "user_type": "patient",
    "expires_in": 86400
  }
}
```

**Errors:**
- `401`: Email/senha inválidos
- `404`: Usuário não encontrado

---

### `POST /auth/logout`

Fazer logout (de momento apenas no cliente).

**Headers:**
```
Authorization: Bearer {jwt_token}
```

**Response (200):**
```json
{
  "status": "success",
  "message": "Logout realizado"
}
```

---

### `POST /auth/refresh`

Renovar token.

**Headers:**
```
Authorization: Bearer {jwt_token}
```

**Response (200):**
```json
{
  "status": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1...",
    "expires_in": 86400
  }
}
```

---

## Usuários

### `GET /users/me`

Obter dados do usuário atual.

**Headers:**
```
Authorization: Bearer {jwt_token}
```

**Response (200):**
```json
{
  "status": "success",
  "data": {
    "user_id": "uuid",
    "email": "usuario@example.com",
    "name": "Nome Completo",
    "user_type": "patient",
    "created_at": "2026-10-02T10:30:00Z",
    "updated_at": "2026-10-02T10:30:00Z"
  }
}
```

---

### `PUT /users/me`

Atualizar perfil do usuário.

**Request:**
```json
{
  "name": "Novo Nome",
  "email": "novo.email@example.com"
}
```

**Response (200):**
```json
{
  "status": "success",
  "data": { ... }
}
```

---

## Pacientes

### `GET /patients`

Listar pacientes do fisioterapeuta (apenas para fisioterapeuta).

**Headers:**
```
Authorization: Bearer {jwt_token}
```

**Query Params:**
```
?page=1&limit=10&search=nome&status=active
```

**Response (200):**
```json
{
  "status": "success",
  "data": [
    {
      "patient_id": "uuid",
      "name": "João Silva",
      "email": "joao@example.com",
      "age": 65,
      "therapist_id": "uuid",
      "last_session": "2026-10-01T15:30:00Z",
      "sessions_count": 5,
      "adherence_percentage": 85.0,
      "created_at": "2026-09-01T00:00:00Z"
    }
  ],
  "pagination": { ... }
}
```

**Errors:**
- `401`: Não autenticado
- `403`: Fisioterapeuta não pode acessar

---

### `GET /patients/{patient_id}`

Obter detalhes de um paciente.

**Response (200):**
```json
{
  "status": "success",
  "data": {
    "patient_id": "uuid",
    "name": "João Silva",
    "email": "joao@example.com",
    "age": 65,
    "gender": "M",
    "diagnosis": "AVC isquêmico",
    "therapist_id": "uuid",
    "notes": "Paciente com boa adesão",
    "created_at": "2026-09-01T00:00:00Z"
  }
}
```

---

### `POST /patients`

Criar novo paciente (apenas para fisioterapeuta).

**Request:**
```json
{
  "email": "novo@example.com",
  "name": "Nome Paciente",
  "age": 65,
  "gender": "M",
  "diagnosis": "AVC isquêmico"
}
```

**Response (201):**
```json
{
  "status": "success",
  "data": { ... }
}
```

---

### `PUT /patients/{patient_id}`

Atualizar dados do paciente.

**Request:**
```json
{
  "name": "Novo Nome",
  "notes": "Observações"
}
```

**Response (200):**
```json
{
  "status": "success",
  "data": { ... }
}
```

---

## Exercícios

### `GET /exercises`

Listar todos os exercícios disponíveis.

**Query Params:**
```
?category=upper_limb&difficulty=easy
```

**Response (200):**
```json
{
  "status": "success",
  "data": [
    {
      "exercise_id": "uuid",
      "name": "Flexão de Cotovelo",
      "description": "Movimento de flexão do cotovelo",
      "category": "upper_limb",
      "difficulty": "easy",
      "target_reps": 10,
      "instructions": "...",
      "video_url": "...",
      "cautions": [...]
    }
  ]
}
```

---

### `GET /exercises/{exercise_id}`

Obter detalhes de um exercício.

**Response (200):**
```json
{
  "status": "success",
  "data": { ... }
}
```

---

### `GET /patients/{patient_id}/exercises`

Listar exercícios atribuídos ao paciente.

**Response (200):**
```json
{
  "status": "success",
  "data": [
    {
      "patient_exercise_id": "uuid",
      "exercise_id": "uuid",
      "exercise_name": "Flexão de Cotovelo",
      "assigned_date": "2026-10-01T00:00:00Z",
      "target_reps": 10,
      "sessions_completed": 3,
      "notes": "..."
    }
  ]
}
```

---

### `POST /patients/{patient_id}/exercises/{exercise_id}`

Atribuir exercício ao paciente.

**Request:**
```json
{
  "target_reps": 10,
  "sessions_planned": 5,
  "notes": "Fazer todos os dias"
}
```

**Response (201):**
```json
{
  "status": "success",
  "data": { ... }
}
```

---

## Sessões

### `POST /sessions`

Criar nova sessão (paciente inicia exercício).

**Request:**
```json
{
  "patient_id": "uuid",
  "exercise_id": "uuid"
}
```

**Response (201):**
```json
{
  "status": "success",
  "data": {
    "session_id": "uuid",
    "patient_id": "uuid",
    "exercise_id": "uuid",
    "started_at": "2026-10-02T10:30:00Z",
    "status": "in_progress"
  }
}
```

---

### `GET /sessions/{session_id}`

Obter detalhes da sessão.

**Response (200):**
```json
{
  "status": "success",
  "data": {
    "session_id": "uuid",
    "patient_id": "uuid",
    "exercise_id": "uuid",
    "exercise_name": "Flexão de Cotovelo",
    "status": "completed",
    "started_at": "2026-10-02T10:30:00Z",
    "ended_at": "2026-10-02T10:35:00Z",
    "duration_seconds": 300,
    "analysis_result": { ... }
  }
}
```

---

### `GET /patients/{patient_id}/sessions`

Listar sessões do paciente.

**Query Params:**
```
?page=1&limit=10&exercise_id=uuid&date_from=2026-10-01&date_to=2026-10-02
```

**Response (200):**
```json
{
  "status": "success",
  "data": [
    {
      "session_id": "uuid",
      "exercise_name": "Flexão de Cotovelo",
      "date": "2026-10-02T10:30:00Z",
      "status": "completed",
      "analysis_status": "success",
      "metrics": {
        "repetitions": 10,
        "amplitude": 85.5
      }
    }
  ],
  "pagination": { ... }
}
```

---

## Análise

### `POST /analysis`

Enviar vídeo para análise.

**Request:**
```
Form Data:
- video_file: <binary>
- exercise_type: `elbow_flexion`, `squat` ou `pinch`
- session_id: "uuid"
- affected_side: `left` ou `right` (opcional)
- detection_start_threshold: número (opcional; exige o segundo limiar)
- detection_change_threshold: número (opcional; exige o primeiro limiar)
```

Os dois campos de calibração são aceitos somente em conjunto. Para cotovelo e
agachamento, o início/retorno deve estar entre 120° e 175°, a mudança entre 40°
e 140°, com diferença mínima de 20°. Para pinça, abertura entre 0,06 e 0,20,
fechamento entre 0,01 e 0,09 e diferença mínima de 0,02.

**Response (202 - Accepted):**
```json
{
  "status": "success",
  "data": {
    "analysis_id": "uuid",
    "session_id": "uuid",
    "exercise_type": "elbow_flexion",
    "status": "processing",
    "simulated": false,
    "message": "Vídeo recebido e aguardando processamento."
  },
  "message": "Solicitação de análise real aceita."
}
```

**Errors:**
- `400`: Arquivo inválido
- `400`: Tipo ou conteúdo do arquivo inválido
- `413`: Arquivo maior que o limite configurado e documentado pela aplicação
- `422`: Exercício sem analisador no modo real
- `422`: Calibração incompleta ou fora das faixas permitidas

---

### `GET /analysis/{analysis_id}`

Obter status e resultado da análise.

**Response (200):**
```json
{
  "status": "success",
  "data": {
    "analysis_id": "uuid",
    "session_id": "uuid",
    "exercise_type": "elbow_flexion",
    "status": "completed",
    "simulated": false,
    "message": "Movimento processado tecnicamente.",
    "created_at": "2026-10-04T10:30:00Z",
    "metrics": {
      "repetitions": 3,
      "source": "computer_vision",
      "confidence": 0.91,
      "average_amplitude_degrees": 94.5,
      "valid_frames": 180,
      "total_frames": 190,
      "detection_ratio": 0.947,
      "analyzed_side": "right",
      "possible_compensations": [],
      "warnings": ["Os limiares utilizados ainda não possuem validação clínica."]
    }
  },
  "message": "Estado da análise recuperado."
}
```

**Status possíveis:**
- `"completed"`: processamento técnico concluído
- `"processing"`: Ainda processando (cliente deve fazer poll)
- `"failed"`: Erro na análise
- `"inconclusive"`: dados insuficientes; métricas não são apresentadas

---

### `GET /sessions/{session_id}/analysis`

Obter resultado da análise de uma sessão.

**Response (200):**
```json
{
  "status": "success",
  "data": { ... }  // Mesma estrutura que /analysis/{analysis_id}
}
```

---

## Progresso

### `GET /patients/{patient_id}/progress`

Obter dados de progresso do paciente (longitudinal).

**Query Params:**
```
?exercise_id=uuid&date_from=2026-09-01&date_to=2026-10-02&metric=amplitude
```

**Response (200):**
```json
{
  "status": "success",
  "data": {
    "patient_id": "uuid",
    "exercise_id": "uuid",
    "date_range": {
      "from": "2026-09-01",
      "to": "2026-10-02"
    },
    "metrics": {
      "total_sessions": 10,
      "avg_repetitions": 9.5,
      "avg_amplitude": 82.3,
      "trend": "improving",  // improving | declining | stable
      "improvement_percent": 12.5
    },
    "timeline": [
      {
        "date": "2026-09-01",
        "session_id": "uuid",
        "repetitions": 8,
        "amplitude": 75.0,
        "compensations_count": 2
      },
      {
        "date": "2026-09-02",
        "session_id": "uuid",
        "repetitions": 9,
        "amplitude": 78.5,
        "compensations_count": 1
      },
      ...
    ]
  }
}
```

---

### `GET /patients/{patient_id}/metrics`

Obter métricas gerais do paciente.

**Response (200):**
```json
{
  "status": "success",
  "data": {
    "patient_id": "uuid",
    "adherence_percentage": 85.0,
    "total_sessions_completed": 15,
    "total_sessions_planned": 20,
    "exercises_assigned": 3,
    "last_session": "2026-10-02T10:30:00Z",
    "days_since_last_session": 0,
    "overall_progress": "good"
  }
}
```

---

## Relatórios

### `POST /reports`

Gerar relatório em PDF.

**Request:**
```json
{
  "patient_id": "uuid",
  "type": "individual" | "longitudinal",
  "session_id": "uuid",  // Obrigatório se type=individual
  "date_from": "2026-09-01",  // Obrigatório se type=longitudinal
  "date_to": "2026-10-02",    // Obrigatório se type=longitudinal
  "include_graphics": true
}
```

**Response (200):**
```json
{
  "status": "success",
  "data": {
    "report_id": "uuid",
    "file_url": "https://...",
    "file_size": 512000,
    "created_at": "2026-10-02T10:30:00Z"
  }
}
```

---

### `GET /reports/{report_id}`

Baixar relatório.

**Response (200):**
```
Content-Type: application/pdf
[Binary PDF Data]
```

---

## Observações do fisioterapeuta

### `POST /sessions/{session_id}/notes`

Adicionar observação do fisioterapeuta a uma sessão.

**Request:**
```json
{
  "content": "Paciente apresentou elevação de ombro na 3ª e 5ª repetição",
  "visibility": "therapist_only" | "patient_visible"
}
```

**Response (201):**
```json
{
  "status": "success",
  "data": {
    "note_id": "uuid",
    "session_id": "uuid",
    "content": "...",
    "created_at": "2026-10-02T10:30:00Z",
    "created_by": "uuid"
  }
}
```

---

### `GET /sessions/{session_id}/notes`

Listar observações de uma sessão.

**Response (200):**
```json
{
  "status": "success",
  "data": [
    {
      "note_id": "uuid",
      "content": "...",
      "created_at": "2026-10-02T10:30:00Z",
      "created_by": "Dr. Silva"
    }
  ]
}
```

---

### `PUT /notes/{note_id}`

Atualizar observação.

**Request:**
```json
{
  "content": "Novo conteúdo"
}
```

**Response (200):**
```json
{
  "status": "success",
  "data": { ... }
}
```

---

### `DELETE /notes/{note_id}`

Deletar observação.

**Response (204):**
```
[Sem conteúdo]
```

---

## Códigos de erro

| Código | Significado | Exemplo |
|--------|------------|---------|
| `400` | Requisição inválida | Email mal formatado |
| `401` | Não autenticado | Token ausente ou expirado |
| `403` | Não autorizado | Paciente tentando acessar dados de outro |
| `404` | Não encontrado | Usuário ID inválido |
| `409` | Conflito | Email já existente |
| `413` | Arquivo muito grande | Vídeo maior que o limite configurado |
| `422` | Dados inválidos (campo específico) | Campo 'age' não é número |
| `500` | Erro no servidor | Exceção não tratada |

---

## 🔄 Fluxo Completo - Exemplo

### Paciente Exercitando

```
1. POST /auth/login
   → Obter token

2. GET /patients/me
   → Obter dados do paciente

3. GET /patients/{id}/exercises
   → Listar exercícios atribuídos

4. POST /sessions
   → Criar nova sessão

5. POST /analysis
   → Enviar vídeo
   → Recebe analysis_id

6. GET /analysis/{analysis_id}
   → Verificar status (loop até success/failed)

7. GET /sessions/{session_id}/analysis
   → Visualizar resultado

8. GET /patients/{id}/progress
   → Ver progresso geral
```

### Fisioterapeuta Monitorando

```
1. POST /auth/login
   → Obter token

2. GET /patients
   → Listar seus pacientes

3. GET /patients/{patient_id}
   → Ver detalhes do paciente

4. GET /patients/{patient_id}/sessions
   → Ver sessões recentes

5. GET /patients/{patient_id}/progress
   → Analisar evolução

6. POST /sessions/{session_id}/notes
   → Adicionar observação

7. POST /reports
   → Gerar relatório PDF

8. GET /reports/{report_id}
   → Baixar PDF
```

---

## Documentação interativa

A documentação Swagger fica disponível em:

```
http://localhost:8000/docs
```

E ReDoc (alternativa):

```
http://localhost:8000/redoc
```

---

**Versão**: 1.0
**Atualizado**: Outubro 2026
**Links**: [OpenAPI Spec](spec.json)
