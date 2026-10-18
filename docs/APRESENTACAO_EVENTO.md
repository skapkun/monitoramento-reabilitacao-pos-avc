# Guia de testes e apresentação do Movere

## Objetivo

Este guia descreve a execução do protótipo em testes individuais e em uma
apresentação acadêmica. O cenário previsto possui uma pessoa utilizando o
aplicativo, um celular e um notebook responsável pela análise de movimento.

Não é necessário contratar hospedagem mensal para esse uso. O FastAPI pode ser
executado no notebook durante toda a demonstração.

## Arquitetura da demonstração

```text
Celular com o aplicativo
        │
        │ rede local
        ▼
Notebook com FastAPI
        │
        ├── OpenCV
        ├── MediaPipe
        ├── métricas e capturas técnicas
        └── geração de PDF

Celular e notebook
        │
        └── internet → Firebase Authentication e Firestore
```

O vídeo é recebido temporariamente pelo backend, processado e apagado. Quando
o paciente autoriza, somente até quatro capturas JPEG compactadas são mantidas
no Firestore. O Firebase Storage não é necessário nesse modo.

## Custo previsto

O custo de hospedagem é zero enquanto o backend for executado no notebook.
Continuam aplicáveis as cotas gratuitas do Firebase Authentication e do
Firestore. O Firebase Storage permanece desativado.

Não é recomendável contratar um servidor apenas para uma apresentação. Os
planos gratuitos com 512 MB de memória podem não executar MediaPipe e OpenCV de
forma estável. Uma hospedagem será reavaliada somente se o aplicativo precisar
funcionar sem o notebook.

## Preparação inicial

No notebook, instale as dependências do backend:

```bash
cd /Users/carla/Documents/projeto/movere/backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
```

No Flutter:

```bash
cd /Users/carla/Documents/projeto/movere/frontend
flutter pub get
flutter devices
```

## Configurar a rede local

O celular e o notebook devem estar na mesma rede. Para descobrir o endereço do
notebook no Wi-Fi do macOS:

```bash
ipconfig getifaddr en0
```

O resultado deve ser semelhante a `192.168.1.10`. Se o comando não retornar um
endereço, consulte **Ajustes do Sistema → Wi-Fi → Detalhes → TCP/IP**.

Não dependa da rede pública do evento. A ordem de preferência é:

1. roteador próprio ou portátil;
2. ponto de acesso criado por um segundo celular;
3. Wi-Fi do evento, somente após teste antecipado.

Algumas redes públicas impedem que dispositivos se comuniquem entre si. O
firewall do macOS também pode solicitar autorização para aceitar conexões do
Python; permita somente na rede usada para a demonstração.

## Iniciar o backend real

Execute sem recarga automática e com autenticação Firebase:

```bash
cd /Users/carla/Documents/projeto/movere/backend
source .venv/bin/activate
ENVIRONMENT=event \
ANALYSIS_MODE=real \
AUTH_MODE=firebase \
FIREBASE_PROJECT_ID=movere-dc610 \
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Mantenha esse terminal aberto. Antes de iniciar o aplicativo, teste no notebook:

```bash
curl http://127.0.0.1:8000/health
```

Resultado esperado:

```json
{"status":"healthy","service":"movere-api"}
```

Depois, abra no navegador do celular, substituindo pelo IP real:

```text
http://192.168.1.10:8000/health
```

Se a resposta não aparecer, verifique a rede, o endereço IP, o firewall e se o
backend continua em execução.

## Executar o aplicativo no celular

Com o aparelho conectado para desenvolvimento, substitua o endereço abaixo
pelo IP do notebook:

```bash
cd /Users/carla/Documents/projeto/movere/frontend
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

O endereço é incorporado nessa execução do aplicativo. Se o notebook mudar de
rede e receber outro IP, execute o Flutter novamente com o novo endereço.

No Android, o acesso HTTP local está liberado na variante de desenvolvimento.
Uma versão de produção instalada separadamente deve usar HTTPS ou uma política
de rede específica e restrita ao ambiente de demonstração. No iOS, o projeto
permite comunicação com serviços da rede local.

## Roteiro de teste completo

1. Iniciar o FastAPI e confirmar `/health` no celular.
2. Abrir o aplicativo e entrar com um paciente de teste.
3. Em **Perfil → Editar dados**, definir **Contexto do perfil** como
   **Voluntário saudável (teste técnico)** quando o participante não tiver AVC.
4. Confirmar que o paciente possui plano de exercício ativo e que o lado
   prescrito seja esquerdo, direito ou bilateral, nunca “lado afetado” nesse
   cenário.
5. Abrir as instruções e selecionar o exercício.
6. Marcar ou desmarcar o compartilhamento das capturas técnicas.
7. Gravar ou escolher um vídeo curto, claro e previamente autorizado.
8. Aguardar a análise sem encerrar o backend.
9. Conferir repetições, amplitude, mensagens e estado da análise.
10. Preencher bem-estar, dor e fadiga quando solicitado.
11. Entrar com o fisioterapeuta, abrir **Como as métricas são calculadas** e
    explicar a diferença entre meta individual e limiar técnico.
12. Conferir sessão, métricas e capturas e registrar a revisão profissional.
13. Gerar o PDF e conferir gráfico, métricas, eventos e capturas autorizadas.

Se for necessário demonstrar mobilidade reduzida, o fisioterapeuta pode ativar
**Calibração individual da detecção** ao editar o exercício. O ajuste exige os
dois limiares e uma justificativa, respeita faixas técnicas protegidas e fica
registrado na sessão e no PDF. Para uma comparação controlada, faça primeiro
uma tentativa supervisionada com os valores padrão e não altere os parâmetros
entre sessões sem registrar o motivo.

## Dados e privacidade durante o evento

- Usar contas e nomes fictícios.
- Preferir vídeos encenados e previamente autorizados.
- Não usar imagens identificáveis de pacientes reais durante a apresentação.
- Não apresentar credenciais, tokens ou documentos internos do Firebase.
- Não afirmar diagnóstico ou precisão clínica.
- Explicar que o teste com pessoa saudável avalia viabilidade técnica e
  usabilidade, sem representar validação com a população pós-AVC.
- Explicar que as compensações são sinais técnicos sujeitos à revisão do
  fisioterapeuta.
- Excluir capturas de teste após a demonstração quando não forem necessárias.

## Plano B

Preparar antes do evento:

- pelo menos um vídeo curto de cada exercício;
- um vídeo adequado e um propositalmente inadequado;
- contas de paciente e fisioterapeuta já vinculadas;
- sessões fictícias previamente cadastradas para popular os painéis;
- um PDF previamente gerado;
- cabo e carregadores;
- gravação de tela do fluxo completo;
- modo demonstração do aplicativo.

Se a análise real falhar, use **Continuar sem vídeo real** para apresentar o
fluxo demonstrativo. Esse resultado deve permanecer identificado como
simulado. Se a internet falhar, apresente as telas já carregadas, o PDF e a
gravação de tela, pois autenticação e Firestore dependem de conexão externa.

## Checklist do dia anterior

- [ ] Executar `flutter analyze`.
- [ ] Executar `flutter test`.
- [ ] Executar os testes do backend com `pytest`.
- [ ] Confirmar o IP que será usado na rede da demonstração.
- [ ] Abrir `/health` pelo celular.
- [ ] Testar uma análise real ponta a ponta.
- [ ] Conferir exclusão do vídeo temporário.
- [ ] Conferir capturas no perfil do fisioterapeuta.
- [ ] Gerar e abrir um PDF.
- [ ] Testar o modo demonstração.
- [ ] Carregar notebook e celular.
- [ ] Desativar atualizações automáticas e notificações pessoais durante a apresentação.

## Limitações que devem ser informadas

- O notebook precisa permanecer ligado durante a análise e geração do PDF.
- Reiniciar o FastAPI interrompe análises em andamento porque os jobs ficam em
  memória.
- A análise ainda precisa de validação com amostras humanas representativas.
- O sistema é um protótipo acadêmico e não substitui avaliação clínica.
- O vídeo completo não fica disponível para reprodução posterior.
- As capturas representam instantes técnicos e não constituem laudo.
