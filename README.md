# Movere

Protótipo de uma aplicação para acompanhar o progresso em terapias de reabilitação pós-AVC com apoio de visão computacional.

## Documentação

- [SISTEMA.md](./docs/SISTEMA.md): escopo e regras gerais do projeto.
- [REQUISITOS.md](./docs/REQUISITOS.md): requisitos funcionais e não funcionais.
- [ARQUITETURA.md](./docs/ARQUITETURA.md): organização técnica da aplicação.
- [PROGRESSO.md](./docs/PROGRESSO.md): estado atual da implementação.
- [VALIDACAO_VIDEOS.md](./docs/VALIDACAO_VIDEOS.md): protocolo de validação com vídeos reais.
- [VALIDACAO_ACESSIBILIDADE.md](./docs/VALIDACAO_ACESSIBILIDADE.md): roteiro de testes manuais de acessibilidade.
- [APRESENTACAO_EVENTO.md](./docs/APRESENTACAO_EVENTO.md): preparação e roteiro da demonstração.
- [GUIA_APRESENTACAO.md](./docs/GUIA_APRESENTACAO.md): execução completa da apresentação em 10 minutos.
- [ALINHAMENTO_ARTIGO.md](./docs/ALINHAMENTO_ARTIGO.md): relação entre o artigo e o que foi implementado.

## Sobre o projeto

O Movere foi desenvolvido como protótipo acadêmico. O paciente pode realizar os exercícios prescritos e enviar a gravação para análise. O fisioterapeuta acompanha as sessões, a adesão e a evolução ao longo do tempo.

O sistema serve como apoio ao acompanhamento. Ele não realiza diagnósticos, não substitui a avaliação do fisioterapeuta e não determina que um movimento é clinicamente seguro. O escopo completo está em [SISTEMA.md](./docs/SISTEMA.md).

## Estrutura do projeto

```
movere/
├── README.md                      # Este arquivo
│
├── frontend/                      # Aplicação Flutter
│   ├── analysis/
│   ├── lib/
│   ├── pubspec.yaml
│   └── ...
│
├── backend/                       # FastAPI
│   ├── app/
│   │   ├── routes/
│   │   ├── services/
│   │   ├── models/
│   │   ├── schemas/
│   │   ├── analysis/
│   │   └── utils/
│   ├── main.py
│   ├── requirements.txt
│   └── ...
│
└── docs/                          # Documentação adicional
    ├── SISTEMA.md                 # Escopo principal
    ├── REQUISITOS.md              # Índice de requisitos
    ├── PLANO_DESENVOLVIMENTO.md   # Fases e progresso
    ├── PROGRESSO.md               # Estado real da implementação
    ├── ARQUITETURA.md             # Decisões arquiteturais
    ├── API.md
    ├── CONFIGURACAO.md
    ├── ACESSIBILIDADE.md
    ├── SISTEMA_VISUAL.md          # Cores, tipografia, ícones e componentes
    └── prompts/
        ├── 01_analisar_projeto.md
        ├── 02_flutter.md
        ├── 03_api.md
        ├── 04_visao_computacional.md
        └── 05_integracao.md
```

## Como executar

### Pré-requisitos
- Flutter SDK
- Python 3.11+ (o Python 3.9 local ainda executa os testes, mas está fora de suporte)
- Git
- Docker Desktop ou Docker Engine com Compose (opcional, somente para o backend)

Use o terminal do seu sistema: Terminal no macOS/Linux ou PowerShell no
Windows. Para preparar Flutter, Android Studio, emuladores e dispositivos,
consulte o guia detalhado em [CONFIGURACAO.md](./docs/CONFIGURACAO.md).

### Instalação

#### Backend (FastAPI)

macOS/Linux:

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
python main.py
```

Windows PowerShell:

```powershell
cd backend
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements-dev.txt
python main.py
```

Se o PowerShell bloquear a ativação, execute uma vez na sessão atual:
`Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`.

Servidor disponível em: `http://localhost:8000`

Como alternativa, a estrutura de conteinerização preparada na fase 3 pode ser executada com:

```bash
docker compose up --build backend
```

O uso de Docker é opcional. O Flutter deve continuar sendo executado diretamente no computador, emulador ou dispositivo físico.

#### Frontend (Flutter)

Os comandos são os mesmos no macOS, Linux e Windows:

```bash
cd frontend
flutter pub get
flutter doctor
flutter run
```

## Fluxos principais

### Paciente

1. Login → Home → Meu Plano → Selecionar Exercício
2. Preparação (instruções + posicionamento)
3. Gravação do Vídeo
4. Processamento (análise por visão computacional)
5. Resultado (feedback + métricas)
6. Histórico e Evolução

### Fisioterapeuta

1. Login → Dashboard
2. Seleção de Paciente
3. Visualização de Sessões
4. Análise de Evolução Longitudinal
5. Geração de Relatórios

## Tecnologias

| Camada | Tecnologia |
|--------|-----------|
| Frontend | Flutter |
| Backend | Python + FastAPI |
| Visão Computacional | MediaPipe + OpenCV |
| Análise | NumPy |
| Banco de Dados | Firestore |
| Autenticação | Firebase Auth |
| Relatórios | ReportLab |

Durante o desenvolvimento, o backend deve funcionar localmente. O protótipo não deve depender de serviços pagos de hospedagem.

## Acessibilidade

- WCAG 2.1 nível AA
- Consideração de limitações pós-AVC (hemiparesia, tremores, etc.)
- Interface simples com botões grandes
- Linguagem clara e instruções concisas

## Exercícios

1. **Flexão de cotovelo** - Movimento do braço
2. **Agachamento** - Movimento de perna
3. **Pinça** - Movimento de dedos

## Privacidade e segurança

- Minimização de dados: o vídeo de análise é descartado por padrão. Mediante
  consentimento separado, o vídeo completo pode ser mantido por até 30 dias no
  servidor, criptografado e acessível apenas ao paciente e ao profissional
  vinculado. Capturas técnicas compactadas continuam opcionais no Firestore.
- Controle de acesso por perfil
- Pacientes veem apenas seus dados
- Fisioterapeuta vê apenas pacientes vinculados

## Estado do desenvolvimento

O trabalho foi organizado em 11 fases, da fase 0 à fase 10:

| Fase | Descrição | Status |
|------|-----------|--------|
| 0 | Planejamento | Concluída |
| 1 | Aplicativo base | Concluída |
| 2 | Fluxo simulado do exercício | Concluída |
| 3 | API básica | Concluída |
| 4 | Flexão de cotovelo | Em validação |
| 5 | Primeira integração real | Em validação |
| 6 | Agachamento e pinça | Implementada; validação com vídeos reais pendente |
| 7 | Histórico e progresso | Implementada; validação com série real pendente |
| 8 | Dashboard do fisioterapeuta | Implementada |
| 9 | Relatórios PDF | Implementada; validação visual pendente |
| 10 | Firebase e persistência | Implementada e testada remotamente |

Ver [PLANO_DESENVOLVIMENTO.md](./docs/PLANO_DESENVOLVIMENTO.md) para detalhes.
Consulte [PROGRESSO.md](./docs/PROGRESSO.md) para verificar o estado real das tarefas.

## Limites do protótipo

- Os critérios técnicos não devem ser apresentados como critérios clínicos validados.
- Resultados automáticos precisam admitir falha ou análise inconclusiva.
- Qualquer conclusão clínica continua sob responsabilidade do profissional.
- A análise não depende do armazenamento do vídeo. O compartilhamento privado
  é opcional, começa desativado e expira em até 30 dias.

## Organização do trabalho

1. Consulte a especificação ([SISTEMA.md](./docs/SISTEMA.md))
2. Verifique o plano de desenvolvimento ([PLANO_DESENVOLVIMENTO.md](./docs/PLANO_DESENVOLVIMENTO.md))
3. Siga a arquitetura proposta ([ARQUITETURA.md](./docs/ARQUITETURA.md))
4. Trabalhe em uma fase por vez
5. Documente as mudanças

## Dados sintéticos para apresentação

O script `tools/seed_presentation.py` cria contas, vínculo, planos e histórico
sintético no Firebase sem versionar senhas. Consulte
[GUIA_APRESENTACAO.md](./docs/GUIA_APRESENTACAO.md) antes de executá-lo.

## Onde encontrar cada informação

Para dúvidas sobre:
- **Especificação**: Consulte [SISTEMA.md](./docs/SISTEMA.md)
- **Arquitetura**: Consulte [ARQUITETURA.md](./docs/ARQUITETURA.md)
- **Configuração**: Consulte [CONFIGURACAO.md](./docs/CONFIGURACAO.md)
- **API**: Consulte [docs/API.md](./docs/API.md)
- **Acessibilidade**: Consulte [ACESSIBILIDADE.md](./docs/ACESSIBILIDADE.md)
- **Sistema visual**: Consulte [SISTEMA_VISUAL.md](./docs/SISTEMA_VISUAL.md)

## Licença

Código disponibilizado sob a licença MIT; consulte [LICENSE](./LICENSE).
