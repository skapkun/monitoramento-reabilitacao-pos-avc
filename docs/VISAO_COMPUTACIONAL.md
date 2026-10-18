# Visão computacional — implementação técnica

## Escopo

O backend implementa módulos independentes para flexão de cotovelo, agachamento e pinça, usando OpenCV, MediaPipe e NumPy. Eles geram métricas observáveis para revisão profissional; não diagnosticam, não prescrevem condutas, não atestam segurança e ainda não possuem validação clínica.

## Pipeline

```text
vídeo → OpenCV → frames → MediaPipe Pose/Hands → landmarks
      → NumPy → regras do exercício → métricas → FastAPI → Flutter
```

- `video_processor.py`: leitura, amostragem e limite de frames;
- `mediapipe_processor.py`: pontos de pose e mão;
- `metrics.py`: ângulos 2D e distância euclidiana;
- `exercises/elbow_flexion.py`, `squat.py` e `pinch.py`: regras isoladas;
- `pipeline.py`: coordenação e tratamento explícito de falhas.

## Parâmetros técnicos iniciais

| Exercício | Estado inicial | Estado intermediário | Ciclo contado | Versão |
|---|---:|---:|---|---|
| Flexão de cotovelo | extensão ≥ 160° | flexão ≤ 90° | extensão → flexão → extensão | `elbow-flexion-v1` |
| Agachamento | joelho ≥ 160° | joelho ≤ 100° | em pé → descida → retorno | `squat-v1` |
| Pinça | distância ≥ 0,10 | distância ≤ 0,05 | aberta → fechada → aberta | `pinch-v1` |

Todos exigem pelo menos 15 frames válidos e taxa de detecção mínima de 70%. A visibilidade mínima dos landmarks de pose é 0,60. Esses valores reproduzem os parâmetros técnicos descritos no artigo aceito e continuam sendo heurísticas sem validação clínica.

O fisioterapeuta pode ativar uma calibração individual experimental dos dois
limiares que definem o ciclo. Para cotovelo e agachamento, o início/retorno é
limitado a 120°–175°, a mudança a 40°–140° e a diferença mínima é 20°. Para
pinça, a abertura é limitada a 0,06–0,20, o fechamento a 0,01–0,09 e a
diferença mínima é 0,02. O ajuste exige justificativa, é validado no Flutter,
FastAPI e Firestore e fica registrado na sessão e no PDF. Qualidade mínima de
imagem e regras de compensação não são alteradas pela calibração.

## Métricas e observações

- Todos: repetições, duração média, confiança técnica, frames válidos e taxa de detecção.
- Cotovelo: amplitude, velocidade angular média, diferença angular bilateral média e possível elevação do ombro.
- Agachamento: amplitude do joelho, velocidade média e possível inclinação excessiva do tronco pela heurística do ângulo do quadril.
- Pinça: distância média normalizada nas coordenadas 2D da imagem; ela não corresponde a centímetros.

A diferença bilateral só é produzida quando os dois braços estão visíveis. A ausência dessa métrica não transforma automaticamente o resultado em falha.

## Resultados inconclusivos e falhas

O resultado é `inconclusive` quando faltam frames/landmarks confiáveis ou nenhum ciclo completo é observado. Arquivo ilegível, erro do OpenCV ou falha ao iniciar/processar MediaPipe são `failed`. Em nenhum desses casos o sistema inventa repetições.

## Limitações

- Cálculos 2D variam com perspectiva, enquadramento e iluminação.
- A escolha automática do lado usa visibilidade, não o lado clinicamente afetado.
- Compensações são sinais técnicos observáveis, não conclusões clínicas.
- A calibração individual altera somente a detecção técnica do ciclo; não é
  parâmetro clínico validado nem recomendação de segurança.
- Não há referência física de distância nem validação em população clínica.
- A análise atual ocorre após a gravação; não é feedback contínuo durante o movimento.
- A cópia recebida pelo backend é temporária e removida após o processamento.
  Se o paciente der consentimento explícito, o aplicativo mantém no Firestore
  até quatro capturas JPEG compactadas dos eventos técnicos para revisão
  profissional e inclusão no PDF. O vídeo original não é persistido.
- Ainda faltam amostras humanas autorizadas e avaliação por fisioterapeuta conforme `VALIDACAO_VIDEOS.md`.

## Testes

Os testes automatizados cobrem ângulos e distâncias conhecidos, ciclos completos e incompletos, baixa visibilidade, seleção de lado, compensações, vídeo ilegível e os três analisadores. Eles validam comportamento de software com dados controlados, não precisão clínica.

```bash
cd backend
source .venv/bin/activate
pytest
```
