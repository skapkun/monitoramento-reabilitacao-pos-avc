# Backend Movere

API FastAPI e módulo de visão computacional do protótipo Movere. A API pode operar em modo simulado ou chamar o pipeline OpenCV, MediaPipe e NumPy da flexão de cotovelo.

Para validar diretamente um vídeo real e gerar um relatório técnico JSON sem
armazenar uma cópia do vídeo:

```bash
python -m app.analysis.validation /caminho/amostra.mp4 \
  --side right \
  --output /caminho/relatorios/amostra.json
```

O protocolo completo está em `../docs/VALIDACAO_VIDEOS.md`.

O módulo não utiliza critérios clínicos validados e não deve ser interpretado como diagnóstico ou avaliação de segurança.

## Instalação local

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
```

## Executar

Modo seguro de demonstração, usado por padrão:

```bash
python main.py
```

Modo de análise real:

```bash
ANALYSIS_MODE=real python main.py
```

Por padrão, `AUTH_MODE=disabled` permite o desenvolvimento local. Para exigir um token Firebase válido nos endpoints de análise:

```bash
AUTH_MODE=firebase FIREBASE_PROJECT_ID=movere-dc610 python main.py
```

Essa configuração valida assinatura, projeto, emissor e expiração do token sem armazenar uma chave administrativa. Para também verificar revogação, configure credenciais fora do repositório e use `FIREBASE_CHECK_REVOKED=true`. Em infraestrutura Google, prefira identidade do ambiente. `GET /health` permanece público; análises e relatórios exigem autenticação quando `AUTH_MODE=firebase`.

Somente ative o modo real para validar vídeos da flexão de cotovelo. Agachamento e pinça ainda não possuem analisadores.

A documentação OpenAPI estará em `http://localhost:8000/docs`.

## Testar

```bash
pytest
```

## Contratos desta fase

- `GET /health`
- `POST /analysis`
- `GET /analysis/{analysis_id}`
- `POST /reports/longitudinal.pdf`

O upload aceita MP4, MOV ou WebM e respeita `MAX_UPLOAD_BYTES`. O arquivo é temporário e removido ao final do processamento. O campo `simulated` impede que dados fictícios sejam confundidos com análise real.

Os estados temporários dos jobs ainda são mantidos em memória: reiniciar o backend interrompe consultas em andamento. Depois da conclusão, o aplicativo persiste a sessão e suas métricas no Firestore, sem armazenar o vídeo por padrão.

## Visão computacional

O módulo de flexão de cotovelo está em `app/analysis/`. Consulte [`../docs/VISAO_COMPUTACIONAL.md`](../docs/VISAO_COMPUTACIONAL.md) para conhecer parâmetros, estados inconclusivos, testes e limitações.
