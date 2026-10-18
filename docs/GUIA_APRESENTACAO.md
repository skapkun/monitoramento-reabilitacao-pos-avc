# Guia da apresentação do Movere

Este é o roteiro operacional para preparar, testar e apresentar o Movere em 10
minutos. As credenciais ficam apenas no arquivo local
`docs/APRESENTACAO_CREDENCIAIS.md`, ignorado pelo Git.

## O que já está preparado

- conta de paciente de apresentação;
- conta de fisioterapeuta de apresentação;
- vínculo entre as duas contas aceito;
- planos ativos de flexão de cotovelo, agachamento e pinça;
- paciente identificado como voluntário saudável para teste técnico;
- três repetições previstas em cada plano.

## Criar ou restaurar os dados da apresentação

O seed cria, sem duplicar dados, as contas **Maria Oliveira** (paciente) e
**Dra. Ana Souza** (fisioterapeuta), o vínculo aceito, três planos, sessões
sintéticas, orientação e mensagens. Os registros gerados permanecem marcados
como simulados e não representam dados clínicos reais.

macOS/Linux:

```bash
export MOVERE_SEED_PASSWORD='escolha-uma-senha-forte'
python3 tools/seed_presentation.py
unset MOVERE_SEED_PASSWORD
```

Windows PowerShell:

```powershell
$env:MOVERE_SEED_PASSWORD = "escolha-uma-senha-forte"
python tools/seed_presentation.py
Remove-Item Env:MOVERE_SEED_PASSWORD
```

A senha nunca é adicionada ao Git. Depois da execução, as credenciais ficam em
`docs/APRESENTACAO_CREDENCIAIS.md`, arquivo local já ignorado pelo repositório.
Para reutilizar contas existentes, informe a mesma senha usada na primeira
execução. Para trocar uma senha esquecida, use a recuperação de senha do app ou
o Firebase Console.

Se paciente e profissional tiverem senhas diferentes, use
`MOVERE_PATIENT_PASSWORD` e `MOVERE_THERAPIST_PASSWORD` no lugar de
`MOVERE_SEED_PASSWORD`.

## Materiais para levar

- notebook carregado e conectado à energia;
- celular carregado com o aplicativo;
- cabo USB compatível;
- segundo celular ou roteador para criar uma rede própria;
- vídeos curtos dos três movimentos salvos no celular;
- um vídeo propositalmente inadequado;
- PDF de demonstração já gerado;
- gravação de tela do fluxo completo;
- slides exportados também em PDF.

Não dependa exclusivamente do Wi-Fi do evento. Redes públicas podem impedir a
comunicação entre o celular e o notebook.

## Preparar os vídeos

Use apenas uma pessoa que autorizou a gravação. Para a apresentação, prefira um
voluntário saudável e evite mostrar rosto, voz, documentos ou outros elementos
identificáveis.

Regras comuns aos três vídeos:

1. Apoie o celular; não grave segurando-o.
2. Use fundo simples, roupa contrastante e iluminação frontal uniforme.
3. Aguarde de 1 a 2 segundos na posição inicial.
4. Faça três ciclos lentos e completos.
5. Aguarde de 1 a 2 segundos ao final.
6. Grave entre 8 e 15 segundos.
7. Não use zoom digital nem câmera ultrawide.
8. Interrompa diante de dor, tontura, desequilíbrio ou desconforto.

### Flexão de cotovelo

- Pessoa sentada ou em pé, de lado ou em ângulo de 30° a 45°.
- Câmera na altura do tronco, a aproximadamente 1,5 a 2 metros.
- Manter ombro, cotovelo, punho e quadril do lado analisado visíveis.
- Começar com o braço estendido, dobrar o cotovelo e retornar à extensão.
- Fazer três ciclos sem levantar o ombro nem inclinar o tronco.

O ciclo padrão atravessa aproximadamente 160° → 90° → 160°. Esses valores são
limiares técnicos experimentais, não critérios clínicos.

### Agachamento

- Câmera na altura do quadril ou tronco, a aproximadamente 1,5 a 2 metros.
- Pessoa em ângulo oblíquo de aproximadamente 45°.
- Manter ombros, quadris, joelhos, tornozelos e pés visíveis.
- Começar em pé, realizar uma descida confortável e retornar completamente.
- Fazer três ciclos lentos, em piso firme e sem obstáculos.

O ciclo padrão atravessa aproximadamente 160° → 100° → 160° no joelho. Não
force profundidade apenas para atingir o limiar.

### Pinça

- Câmera a aproximadamente 40 cm da mão.
- Fundo liso, boa iluminação e polegar e indicador inteiros no quadro.
- Manter a mão na mesma distância da câmera.
- Começar com os dedos afastados, aproximar as pontas e reabrir.
- Fazer três ciclos lentos.

A distância calculada é normalizada na imagem 2D e não representa centímetros.

### Arquivos recomendados

```text
cotovelo_bom.mp4
cotovelo_compensacao.mp4
agachamento_bom.mp4
pinca_bom.mp4
video_inadequado.mp4
```

Use `cotovelo_bom.mp4` na demonstração principal. Os demais devem ficar prontos
como resultados previamente processados ou plano B.

## Iniciar o sistema no notebook

### 1. Descobrir o IP da rede

```bash
ipconfig getifaddr en0
```

Anote o endereço retornado. Se estiver usando outra interface, consulte
**Ajustes do Sistema → Wi-Fi → Detalhes → TCP/IP**.

### 2. Iniciar o FastAPI real

```bash
cd /Users/carla/Documents/projeto/movere/backend
source .venv/bin/activate

ENVIRONMENT=event \
ANALYSIS_MODE=real \
AUTH_MODE=firebase \
FIREBASE_PROJECT_ID=movere-dc610 \
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Mantenha esse terminal aberto. Em outro terminal, teste:

```bash
curl http://127.0.0.1:8000/health
```

Depois abra no navegador do celular:

```text
http://IP_DO_NOTEBOOK:8000/health
```

O resultado deve indicar `healthy`. Se não abrir, confira o IP, a rede, o
firewall do macOS e o terminal do FastAPI.

### 3. Instalar ou abrir o aplicativo no celular

Com o aparelho conectado:

```bash
cd /Users/carla/Documents/projeto/movere/frontend
flutter devices
flutter run --dart-define=API_BASE_URL=http://IP_DO_NOTEBOOK:8000
```

Troque `IP_DO_NOTEBOOK` pelo endereço anotado. Se a rede mudar, execute o app
novamente com o novo IP.

## Teste completo antes do evento

1. Entrar como fisioterapeuta com a conta local de apresentação.
2. Conferir o paciente no painel e abrir seu perfil.
3. Confirmar os três exercícios no plano.
4. Sair e entrar como paciente.
5. Abrir a flexão de cotovelo.
6. Ler as instruções e confirmar os quatro cartões de preparação.
7. Escolher `cotovelo_bom.mp4` na galeria.
8. Autorizar capturas técnicas.
9. Autorizar o vídeo completo apenas se for demonstrar a reprodução privada.
10. Enviar e aguardar a análise.
11. Conferir repetições, amplitude, duração, velocidade e qualidade técnica.
12. Preencher bem-estar, dor, fadiga e um comentário curto.
13. Voltar para a conta profissional.
14. Abrir a sessão e conferir comentário, métricas e eventos.
15. Abrir as capturas e o vídeo autorizado.
16. Registrar avaliação e conduta profissional.
17. Gerar e abrir o PDF longitudinal.
18. Repetir antecipadamente com agachamento e pinça.
19. Testar `video_inadequado.mp4` e confirmar resultado inconclusivo.
20. Gravar a tela do fluxo que funcionou.

## Roteiro falado de 10 minutos

### 0:00–0:45 — Problema

> A reabilitação pós-AVC exige acompanhamento contínuo, mas o profissional nem
> sempre consegue observar as sessões realizadas em casa. O Movere reúne
> prescrição, registro de sessões e análise técnica do movimento.

### 0:45–1:30 — Objetivo e limites

> O sistema possui perfis de paciente e fisioterapeuta e analisa flexão de
> cotovelo, agachamento e pinça. É um protótipo acadêmico: não realiza
> diagnóstico, não substitui avaliação profissional e ainda requer validação
> clínica. A demonstração usa um voluntário saudável e comprova somente o
> funcionamento técnico.

### 1:30–2:15 — Arquitetura

```text
Flutter → FastAPI → OpenCV/MediaPipe/NumPy → métricas
   └──────── Firebase Authentication e Firestore ────────┘
```

Explique que o Flutter oferece a interface, o FastAPI coordena análise e PDF,
o OpenCV lê os frames, o MediaPipe extrai landmarks, o NumPy apoia os cálculos
e o Firestore mantém os dados estruturados.

### 2:15–3:00 — Fisioterapeuta

Mostre o painel, o paciente vinculado e os três exercícios. Destaque frequência,
repetições, lado, cadência e a separação entre meta da prescrição e limiar do
algoritmo.

### 3:00–5:40 — Paciente e análise

Mostre o plano, as instruções, a preparação, a seleção do vídeo, os dois
consentimentos separados, o processamento e o resultado da flexão de cotovelo.

> Uma repetição só é contada quando o movimento atravessa os limiares de início
> e mudança e retorna à posição inicial. Movimento parcial pode não ser contado
> e vídeo sem qualidade suficiente deve resultar em análise inconclusiva.

### 5:40–7:10 — Revisão profissional

Mostre a sessão na conta profissional, o relato de bem-estar, dor, fadiga,
comentário, melhor repetição, eventos técnicos, capturas e vídeo autorizado.
Registre uma revisão profissional.

### 7:10–8:00 — Relatório

Abra o PDF previamente gerado e mostre evolução, métricas, parâmetros, eventos,
capturas e o aviso de que o documento não constitui laudo.

### 8:00–9:00 — Privacidade e acessibilidade

> O vídeo é descartado por padrão. O compartilhamento completo começa
> desativado, exige consentimento separado, utiliza AES-256-GCM e expira em até
> 30 dias. A interface utiliza controles grandes, linguagem direta, contraste,
> texto ampliado e indicadores que não dependem apenas de cor.

### 9:00–9:40 — Limitações

> As métricas dependem do enquadramento, iluminação e perspectiva 2D. As
> compensações são heurísticas para revisão profissional. Testes automatizados
> verificam consistência do software, não eficácia clínica.

### 9:40–10:00 — Encerramento

> A contribuição do Movere é integrar prescrição, execução domiciliar, análise
> técnica explicável e acompanhamento longitudinal. A próxima etapa é a
> validação com amostras autorizadas, profissionais e público-alvo.

## Plano B

Se a análise ao vivo falhar:

1. Não esconda a falha nem apresente resultado simulado como real.
2. Mostre a gravação de tela do teste concluído.
3. Abra sessões previamente processadas.
4. Mostre o PDF já salvo.
5. Explique que Firebase depende de internet e celular–FastAPI depende da rede
   local.

## Frases que devem ser evitadas

Não diga que o sistema diagnostica, garante segurança, comprova movimento
correto, mede centímetros na pinça ou foi validado clinicamente. Use “métrica
técnica experimental”, “possível compensação”, “resultado inconclusivo” e
“evento sujeito à revisão profissional”.

## Checklist do dia anterior

- [ ] Executar `flutter analyze` e `flutter test`.
- [ ] Executar `pytest` no backend.
- [ ] Testar login nas duas contas.
- [ ] Confirmar o vínculo e os três planos.
- [ ] Testar `/health` pelo celular.
- [ ] Analisar ao menos um vídeo real de cada movimento.
- [ ] Testar reprodução privada e exclusão pelo paciente.
- [ ] Gerar um PDF.
- [ ] Gravar a tela do fluxo completo.
- [ ] Ensaiar duas vezes com cronômetro.
- [ ] Levar vídeos, PDF, slides, cabo e carregadores.
- [ ] Desativar notificações pessoais e atualizações automáticas.
- [ ] Preparar uma rede própria.

## Depois do evento

- apagar vídeos e capturas que não precisem mais existir;
- trocar as senhas ou excluir as contas de apresentação;
- remover arquivos exportados de dispositivos compartilhados;
- não reutilizar gravações em pesquisa sem autorização específica.
