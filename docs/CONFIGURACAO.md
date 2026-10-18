# Configuração do ambiente

Instruções passo a passo para configurar o ambiente de desenvolvimento local.

---

## Pré-requisitos

### Sistema Operacional
- macOS 11.0+ (ou Linux/Windows com WSL)
- Git instalado

### Hardware Recomendado
- RAM: 8 GB mínimo (16 GB recomendado)
- Armazenamento: 20 GB disponível
- Processador: Multi-core

### Docker opcional

Docker Desktop ou Docker Engine com o plugin Compose pode ser utilizado para executar somente o backend. Ele não é necessário para iniciar o desenvolvimento e não deve ser usado para executar o Flutter.

---

## Ferramentas básicas

### 1. Instalar Git (se não tiver)

**macOS:**
```bash
brew install git
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt install git
```

**Verificar:**
```bash
git --version
```

### 2. Clonar o Repositório

```bash
cd ~/Documents/projeto
git clone <seu-repositorio> movere
cd movere
```

---

## Configuração do Flutter

### 1. Instalar Flutter SDK

Baixar em: https://flutter.dev/docs/get-started/install

**macOS via Homebrew:**
```bash
brew install flutter
```

**Ou manual:**
```bash
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:~/development/flutter/bin"
```

### 2. Verificar Instalação

```bash
flutter --version
flutter doctor
```

Resolver qualquer problema reportado por `flutter doctor`.

### 3. Configurar Android/iOS (Necessário para teste real)

#### Android
```bash
flutter config --android-studio-dir </path/to/android/studio>
flutter config --enable-android
```

#### iOS (macOS apenas)
```bash
flutter config --enable-ios
```

### 4. Projeto Flutter existente

```bash
cd ~/Documents/projeto/movere
cd frontend
```

O projeto já existe. Não execute `flutter create` novamente. O identificador nativo configurado no Android e no iOS é `com.app.movere`.

### 5. Instalar Dependências

```bash
flutter pub get
```

### 6. Executar Aplicativo

```bash
# Listar dispositivos conectados
flutter devices

# Executar em emulador/dispositivo
flutter run

# Executar com hot reload
flutter run -v
```

Em dispositivo físico, informe o endereço IP do computador que executa o FastAPI:

```bash
flutter run --dart-define=API_BASE_URL=http://SEU_IP_LOCAL:8000
```

No Android Emulator, o aplicativo usa `http://10.0.2.2:8000`; no simulador iOS e no navegador, usa `http://localhost:8000` por padrão. Para o Flutter Web, fixe a porta permitida pelo backend com `flutter run -d chrome --web-port 8080`.

---

## Configuração do backend

### 1. Verificar Instalação do Python

```bash
python3 --version  # Deve ser 3.11+
```

Se não tiver Python 3.11+:

**macOS:**
```bash
brew install python@3.11
```

**Linux (Ubuntu):**
```bash
sudo apt install python3.11 python3.11-venv
```

### 2. Criar Ambiente Virtual

```bash
cd ~/Documents/projeto/movere
python3 -m venv backend/.venv

# Ativar
source backend/.venv/bin/activate  # macOS/Linux
# ou
backend\.venv\Scripts\activate     # Windows
```

Você verá `(.venv)` no terminal.

### 3. Dependências

As dependências executáveis estão versionadas em `backend/requirements.txt`. As ferramentas de teste estão em `backend/requirements-dev.txt`. Bibliotecas de visão computacional, Firebase e relatórios serão adicionadas somente nas fases correspondentes.

### 4. Instalar Dependências

```bash
# Certificar que (.venv) está ativo
pip install -r requirements-dev.txt
```

Nesta fase são instalados apenas FastAPI, servidor HTTP e ferramentas de teste.

### 5. Estrutura implementada

```text
backend/
├── app/
│   ├── main.py
│   ├── config.py
│   ├── routes/
│   ├── schemas/
│   └── services/
├── tests/
├── main.py
├── requirements.txt
└── requirements-dev.txt
```

### 6. Executar FastAPI

O modo padrão é a demonstração segura, sem visão computacional real:

```bash
# Certificar que (.venv) está ativo
cd backend
python main.py

# Ou
uvicorn main:app --reload
```

Para validar um vídeo real de flexão de cotovelo, agachamento ou pinça:

```bash
ANALYSIS_MODE=real python main.py
```

Valores aceitos para `ANALYSIS_MODE`: `mock` e `real`. Os três exercícios estão
integrados ao modo real, mas ainda exigem validação com vídeos humanos
representativos antes de qualquer afirmação de precisão clínica.

Servidor estará disponível em: `http://localhost:8000`
Documentação Swagger: `http://localhost:8000/docs`

### 7. Executar o backend com Docker (opcional)

Depois que o `Dockerfile` e o `compose.yaml` forem criados na fase 3, execute a partir da raiz do projeto:

```bash
docker compose up --build backend
```

Para ativar a análise real no Compose, altere `ANALYSIS_MODE` para `real` somente durante a validação controlada.

O serviço deve expor a porta `8000`, carregar configurações por variáveis de ambiente e montar somente os diretórios temporários necessários durante o desenvolvimento. A credencial do Firebase não deve ser copiada para a imagem nem versionada.

Para encerrar:

```bash
docker compose down
```

O modo Docker é uma alternativa reproduzível. O comando `python main.py` deve continuar funcionando sem Docker.

---

## Configuração do Firebase

O aplicativo está associado ao projeto Firebase `movere-dc610`. Os aplicativos Android e iOS usam o mesmo identificador: `com.app.movere`.

### 1. Criar Projeto no Firebase

O projeto já foi criado. Não crie outro projeto nem registre novos aplicativos para continuar esta configuração.

### 2. Ativar Autenticação

1. No Firebase Console
2. Authentication → Começar
3. Em Métodos de login, ativar **E-mail/senha**

O login anônimo não é utilizado e deve permanecer desativado.

### 3. Ativar Firestore

1. No Firebase Console
2. Firestore Database → Criar banco de dados
3. Selecionar o banco padrão `(default)`
4. Localização atual do projeto: `southamerica-east1` (São Paulo)
5. Criar o banco e publicar imediatamente as regras versionadas em `frontend/firestore.rules`

O banco foi criado em `southamerica-east1`, conforme o planejamento. Não use o modo de teste aberto. As regras publicadas protegem perfis, vínculos, planos, sessões e observações conforme o usuário autenticado e o vínculo aceito.

### 4. Configuração Flutter já aplicada

```bash
cd frontend
flutter pub get
```

Foram configurados `firebase_core`, `firebase_auth`, `cloud_firestore` e
`firebase_storage`. Os arquivos nativos e `lib/firebase_options.dart` foram
gerados pelo FlutterFire CLI para `com.app.movere`.

O alvo mínimo é iOS 15. As versões do FlutterFire estão fixadas no `pubspec.yaml` para permanecer compatíveis com o Flutter 3.35 utilizado no projeto; atualize esse conjunto de forma coordenada ao atualizar o Flutter.

### 5. Publicar regras do Firestore

As regras já foram publicadas. Para republicá-las depois de uma alteração revisada:

```bash
cd frontend
firebase deploy --only firestore:rules,firestore:indexes
```

### 6. Validar no aplicativo

```bash
cd frontend
flutter run
```

1. Criar uma conta de teste.
2. Sair e entrar novamente com e-mail e senha.
3. Fechar e reabrir o aplicativo para validar a restauração da sessão.
4. Abrir o perfil e confirmar nome, e-mail e tipo de usuário.
5. Solicitar recuperação de senha.

Na compilação normal, os atalhos de demonstração ficam ocultos. Vínculos, planos, sessões, orientações, histórico e métricas são persistidos no Firestore. O modo demonstrativo continua disponível apenas para testes automatizados por meio dos repositórios em memória.

### 7. Credenciais do backend

O backend valida assinatura, emissor, projeto e expiração dos tokens Firebase quando `AUTH_MODE=firebase`. Essa validação padrão não exige armazenar uma chave administrativa:

```bash
cd backend
AUTH_MODE=firebase \
FIREBASE_PROJECT_ID=movere-dc610 \
python main.py
```

Para verificar também se o token foi revogado, configure uma identidade do ambiente ou `GOOGLE_APPLICATION_CREDENTIALS` fora do repositório e use `FIREBASE_CHECK_REVOKED=true`. Nunca copie a credencial para a imagem Docker nem a versione. Use `AUTH_MODE=disabled` somente no desenvolvimento local isolado.

### 8. Ativar o compartilhamento privado de vídeos

O vídeo completo usa o próprio FastAPI, sem Firebase Storage. Para teste local,
os padrões do `.env.example` criam `backend/data/`, um banco SQLite e uma chave
local com permissão restrita. Esse diretório não é versionado.

Em um servidor, monte `backend/data/` em disco persistente e defina uma chave
fora do repositório:

```bash
python -c "import base64,secrets; print(base64.urlsafe_b64encode(secrets.token_bytes(32)).decode())"
```

Copie o resultado para o gerenciador de segredos da hospedagem como
`VIDEO_ENCRYPTION_KEY`. Configure também:

```text
VIDEO_STORAGE_DIR=/app/data/videos
VIDEO_DATABASE_PATH=/app/data/video_metadata.sqlite3
VIDEO_RETENTION_DAYS=30
VIDEO_CLEANUP_INTERVAL_SECONDS=21600
AUTH_MODE=firebase
```

Não troque nem perca a chave enquanto existirem vídeos: sem ela, os arquivos e
os metadados não podem ser recuperados. O servidor precisa usar HTTPS. A rotina
de limpeza remove itens vencidos periodicamente e qualquer acesso depois da
expiração também é negado.

Para validar, use duas contas vinculadas: o paciente compartilha um vídeo, os
dois o reproduzem, uma terceira conta recebe negação e somente o paciente
consegue apagá-lo antes do prazo. Reinicie o servidor e repita a reprodução
para confirmar que o volume é realmente persistente.

---

## 🔑 Configurar Variáveis de Ambiente

### Backend

Variáveis aceitas: `ENVIRONMENT`, `ANALYSIS_MODE`, `AUTH_MODE`,
`FIREBASE_PROJECT_ID`, `FIREBASE_CHECK_REVOKED`, `MAX_UPLOAD_BYTES`,
`ANALYSIS_TEMP_DIR`, `ALLOWED_ORIGINS`, `VIDEO_STORAGE_DIR`,
`VIDEO_DATABASE_PATH`, `VIDEO_KEY_PATH`, `VIDEO_ENCRYPTION_KEY`,
`VIDEO_RETENTION_DAYS` e `VIDEO_CLEANUP_INTERVAL_SECONDS`. Quando a checagem de
revogação estiver ativa, use também `GOOGLE_APPLICATION_CREDENTIALS`.

### Frontend

O endereço da API é informado em compilação, sem arquivo `.env`:

```bash
flutter run --dart-define=API_BASE_URL=http://SEU_IP_LOCAL:8000
```

---

## Estrutura de diretórios

```
movere/
├── .gitignore
├── .git/
├── compose.yaml
├── README.md
├── docs/
│   ├── SISTEMA.md
│   ├── REQUISITOS.md
│   ├── PLANO_DESENVOLVIMENTO.md
│   ├── PROGRESSO.md
│   ├── ARQUITETURA.md
│   ├── API.md
│   ├── CONFIGURACAO.md
│   ├── ACESSIBILIDADE.md
│   ├── SISTEMA_VISUAL.md
│   ├── VALIDACAO_VIDEOS.md
│   └── prompts/
│
├── frontend/
│   ├── pubspec.yaml
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── test/
│
└── backend/
    ├── .gitignore
    ├── .dockerignore
    ├── Dockerfile
    ├── requirements.txt
    ├── main.py
    ├── app/
    ├── tests/
    └── .venv/
```

---

## Verificação da instalação

### 1. Backend

```bash
cd backend
source .venv/bin/activate
python main.py

# Em outro terminal, testar
curl http://localhost:8000/health
# Deve retornar: {"status":"healthy","service":"movere-api"}

curl http://localhost:8000/docs
# Abre documentação Swagger no navegador
```

### 2. Frontend

```bash
cd frontend
flutter pub get
flutter run
# Emulador deve abrir com o app

# O fluxo HTTP já está implementado; mantenha o backend ativo para a análise real.
```

---

## Arquivo `.gitignore`

Criar `movere/.gitignore`:

```
# Python
backend/.venv/
backend/.env
backend/firebase_key.json
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
*.egg-info/
dist/
build/

# Flutter
frontend/.dart_tool/
frontend/.flutter-plugins
frontend/.flutter-plugins-dependencies
frontend/.packages
frontend/.pub-cache/
frontend/.pub/
frontend/build/
frontend/.env
frontend/android/local.properties

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Logs
*.log

# Vídeos temporários
backend/temp/
backend/uploads/
```

---

## 🐛 Troubleshooting

### Flutter doctor com problemas

```bash
flutter doctor -v  # Mostrar detalhes
flutter doctor --android-licenses  # Aceitar licenças Android
```

### Erro ao instalar dependências Python

```bash
# Atualizar pip
pip install --upgrade pip

# Limpar cache
pip cache purge

# Reinstalar
pip install -r requirements.txt
```

### MediaPipe lento na primeira importação

Normal - leva uns minutos na primeira vez.

### Erro de porta 8000 em uso

```bash
# macOS/Linux
lsof -i :8000  # Encontrar processo
kill -9 <PID>  # Matar processo

# Ou usar porta diferente
uvicorn main:app --reload --port 8001
```

### Flutter não consegue acessar backend

1. Verificar se backend está rodando
2. Verificar IP certo (não localhost de emulador - usar IP da máquina)
3. No emulador Android, usar `http://10.0.2.2:8000` para acessar o backend executado na máquina

---

## Próximos passos

1. Executar o aplicativo em um dispositivo ou emulador conectado.
2. Validar cadastro, vínculo, plano, sessão e relatório pela interface.
3. Seguir `VALIDACAO_VIDEOS.md` com amostras autorizadas de flexão de cotovelo.
4. Registrar os resultados em `PROGRESSO.md`.
5. Avançar para outro exercício somente após essa validação e a definição profissional de seus critérios.

---

## 💾 Salvar Progresso

Após finalizar cada fase:

```bash
git add .
git commit -m "Fase 1: aplicativo base"
git push origin main
```

---

**Versão**: 1.0
**Atualizado**: Outubro 2026
**Próxima atualização**: Após validação com vídeos humanos representativos
