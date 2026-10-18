# Etapa 4 — Visão computacional

Use [SISTEMA.md](../SISTEMA.md) como fonte de verdade e consulte [ARQUITETURA.md](../ARQUITETURA.md) e [REQUISITOS.md](../REQUISITOS.md).

## Objetivo

Implementar o pipeline de análise de movimento usando Python, OpenCV, MediaPipe e NumPy. Começar exclusivamente pela flexão de cotovelo; agachamento e pinça só devem ser iniciados após o primeiro módulo ser testado e integrado.

## Pipeline

```text
Vídeo
  ↓
OpenCV e frames
  ↓
MediaPipe e landmarks
  ↓
NumPy e métricas
  ↓
Regras parametrizadas do exercício
  ↓
Repetições, compensações ou análise inconclusiva
  ↓
Resultado
```

## Ordem dos exercícios

1. Flexão de cotovelo.
2. Agachamento, somente depois da validação técnica da flexão.
3. Pinça, somente depois da validação técnica do agachamento.

## Instruções

1. Preserve a separação entre processamento de vídeo, extração de landmarks, métricas, estados, repetições, compensações e relatórios.
2. Parametrize e documente todos os limiares e regras.
3. Não invente critérios clínicos ou declare precisão clínica.
4. Trate perda de landmarks, enquadramento inadequado e dados insuficientes como análise inconclusiva.
5. Não apresente uma análise inconclusiva como resultado confiável.
6. Utilize linguagem neutra nos alertas produzidos.
7. Teste cada exercício com dados controlados e registre as limitações observadas.
8. Não misture a lógica dos exercícios: cada exercício deve possuir módulo próprio.
9. Não inicie agachamento ou pinça durante a implementação da flexão de cotovelo.

## Entrega

Informe módulos implementados, parâmetros utilizados, testes executados, limitações e casos inconclusivos.
