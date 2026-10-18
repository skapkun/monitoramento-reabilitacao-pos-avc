# Validação técnica com vídeos

Este protocolo valida o funcionamento técnico da flexão de cotovelo. Ele não
constitui validação clínica, não mede eficácia terapêutica e não substitui a
avaliação de um fisioterapeuta.

## Privacidade e consentimento

- Utilize somente participantes que tenham autorizado a gravação para o teste.
- Evite registrar rosto, nome, voz, documentos ou elementos identificáveis.
- Não envie vídeos reais ao repositório nem os mantenha em `backend/`.
- Apague as amostras quando deixarem de ser necessárias ao protocolo aprovado.
- O relatório guarda apenas nome do arquivo, tamanho, hash SHA-256 e métricas.

## Preparação da gravação

1. Posicione a câmera de modo estável, preferencialmente na altura do tronco.
2. Mantenha ombro, cotovelo, punho e quadril do lado analisado visíveis.
3. Use iluminação uniforme e fundo com contraste em relação ao participante.
4. Evite roupas largas que ocultem as articulações.
5. Grave o corpo lateralmente ou em ângulo que preserve a visualização do braço.
6. Faça movimentos lentos, dentro do limite confortável orientado pelo profissional.
7. Pare se houver dor, tontura, mal-estar ou qualquer orientação profissional para interromper.

## Conjunto mínimo recomendado

Para validar robustez técnica, use pelo menos:

- um vídeo com braço esquerdo e um com braço direito;
- um vídeo com três ciclos completos e um com apenas um ciclo;
- um vídeo propositalmente inadequado, como braço parcialmente fora do quadro;
- variação controlada de iluminação ou distância;
- repetição da mesma amostra para confirmar resultado determinístico.

As quantidades são um roteiro de teste de software, não uma amostra de pesquisa
nem fundamento para declarar precisão clínica.

## Executar a validação

Ative o ambiente do backend e execute:

```bash
cd backend
source .venv/bin/activate
python -m app.analysis.validation /caminho/amostra.mp4 \
  --side right \
  --output /caminho/relatorios/amostra.json
```

Use `--side left` para o braço esquerdo ou omita a opção para seleção automática.

Os códigos de saída são:

- `0`: análise técnica concluída;
- `2`: análise inconclusiva;
- `1`: falha técnica ou arquivo inexistente.

## O que registrar

Para cada amostra, registre em uma planilha ou diário de testes:

| Campo | Registro esperado |
|---|---|
| Código da amostra | Identificador sem nome da pessoa |
| Condição | Lado, iluminação, distância e enquadramento |
| Ciclos observados manualmente | Apenas referência técnica da gravação |
| Status do sistema | `success`, `inconclusive` ou `failed` |
| Repetições retornadas | Valor do relatório JSON |
| Detecção | `detection_ratio` e `valid_frames` |
| Observação | Divergência, falha ou dificuldade percebida |
| Versão | `parameters_version` do relatório |

## Critérios técnicos para encerrar a fase

- vídeos adequados são processados sem falha da aplicação;
- vídeos inadequados retornam resultado inconclusivo, sem inventar métricas;
- o mesmo arquivo e os mesmos parâmetros produzem o mesmo resultado;
- os ciclos retornados podem ser comparados manualmente com a gravação;
- limitações e divergências são registradas, não ocultadas;
- nenhum resultado é descrito como diagnóstico ou garantia de segurança.

Se os resultados exigirem alteração dos limiares, registre a justificativa e
crie uma nova versão dos parâmetros antes de repetir todo o conjunto.
