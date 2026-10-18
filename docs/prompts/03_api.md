# Etapa 3 — API FastAPI

Use [SISTEMA.md](../SISTEMA.md) como fonte de verdade e consulte [API.md](../API.md), [ARQUITETURA.md](../ARQUITETURA.md) e [REQUISITOS.md](../REQUISITOS.md).

## Objetivo

Criar a API REST responsável pela comunicação entre o Flutter e os módulos de análise. Nesta etapa inicial, utilizar resposta simulada claramente identificada e não bloquear o núcleo do projeto com Firebase.

## Responsabilidades

- Receber o vídeo e a identificação do exercício.
- Validar o arquivo e os dados da requisição.
- Iniciar a análise correspondente.
- Informar o estado do processamento.
- Retornar resultados ou análise inconclusiva.
- Disponibilizar relatórios quando essa fase for implementada.
- Comunicar-se com os módulos de análise por uma interface separada.

## Estrutura esperada

```text
backend/
├── main.py
├── app/
│   ├── routes/
│   ├── schemas/
│   ├── services/
│   ├── models/
│   └── utils/
└── analysis/
    ├── exercises/
    └── ...
```

## Não fazer

- Não colocar MediaPipe, OpenCV ou regras completas dos exercícios nas rotas.
- Não misturar validação HTTP com processamento de vídeo.
- Não apresentar resposta simulada como análise real.
- Não implementar Firebase antes da fase prevista no plano.

## Instruções

1. Analise o repositório e preserve implementações válidas.
2. Mantenha rotas, esquemas, modelos e serviços separados.
3. Deixe regras de negócio nos serviços e validações de contrato nos esquemas.
4. Não coloque a lógica de visão computacional diretamente nas rotas.
5. Não fixe limites, tempos ou critérios sem documentá-los como parâmetros.
6. Não invente critérios clínicos nem resultados de análise.
7. Crie testes dos contratos, validações e respostas de erro.
8. Mantenha a execução direta com Python e adicione Docker como alternativa opcional somente para o backend.
9. Não copie credenciais para a imagem e não coloque o Flutter no Docker.

## Entrega

Informe endpoints implementados, arquivos alterados, testes executados, decisões técnicas e pendências.
