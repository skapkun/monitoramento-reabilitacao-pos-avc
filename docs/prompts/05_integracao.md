# Etapa 5 — Integração completa

Use [SISTEMA.md](../SISTEMA.md) como fonte de verdade e consulte todos os documentos técnicos da pasta `docs/`.

## Objetivo

Integrar primeiro o fluxo Flutter → FastAPI → módulo de flexão de cotovelo → resultado → Flutter. Firestore, relatórios e os demais exercícios permanecem fora desta primeira integração.

## Pré-condições

- Fluxo simulado do Flutter funcionando isoladamente.
- API básica testada isoladamente.
- Módulo de flexão de cotovelo testado isoladamente.

## Fluxo

1. Usuário seleciona flexão de cotovelo.
2. Usuário grava ou seleciona um vídeo.
3. Flutter envia vídeo e identificação do exercício.
4. FastAPI valida e recebe o arquivo temporário.
5. A API chama o módulo de flexão de cotovelo.
6. O módulo processa vídeo, landmarks e métricas.
7. O resultado retorna para a API.
8. A API retorna resultado, falha ou análise inconclusiva.
9. O Flutter apresenta a resposta de forma acessível.
10. O backend remove o arquivo temporário quando possível.

## Instruções

1. Analise o estado do aplicativo, da API e dos módulos de análise.
2. Integre uma etapa por vez e não substitua componentes funcionais sem necessidade.
3. Exiba claramente envio, processamento, conclusão, falha e análise inconclusiva.
4. Remova vídeos temporários depois do processamento sempre que possível.
5. Não iniciar agachamento, pinça, relatórios ou Firebase durante esta integração.
6. Teste falhas de rede, vídeo inválido, análise inconclusiva e erro de processamento.

## Entrega

Informe fluxos integrados, arquivos alterados, testes executados, problemas encontrados e como executar a solução localmente.
