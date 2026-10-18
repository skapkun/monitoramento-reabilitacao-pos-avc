# Acessibilidade

Diretrizes para garantir que o sistema Movere seja acessível a usuários com limitações pós-AVC.

As definições de cores, tipografia, ícones e componentes estão centralizadas em [SISTEMA_VISUAL.md](./SISTEMA_VISUAL.md). Os pares de cores realmente utilizados devem respeitar os contrastes validados nesse documento.

## Estado implementado

- A preferência **Texto ampliado** garante escala mínima de 115%, preservando qualquer ampliação maior configurada no Android/iOS.
- A preferência **Reduzir animações** ativa `disableAnimations` e `accessibleNavigation` globalmente.
- As preferências são persistidas no perfil do Firestore e restauradas com a sessão.
- Indicadores de evolução possuem rótulos semânticos textuais e não dependem apenas do comprimento ou da cor das barras.
- Controles interativos utilizam as dimensões mínimas definidas pelo tema.
- As 26 rotas passam nas verificações automáticas de contraste, rótulos e alvos de toque no conteúdo inicialmente visível.
- As 26 rotas renderizam sem estouro em viewport de 390×844 dp com texto a 200%.
- Grades de indicadores passam para uma coluna com texto ampliado; dropdowns e painéis visuais se adaptam ao conteúdo.

Esses controles técnicos não substituem os testes manuais descritos em [VALIDACAO_ACESSIBILIDADE.md](./VALIDACAO_ACESSIBILIDADE.md).

---

## Objetivo

Seguir **WCAG 2.1 nível AA** e adaptar especificamente para usuários em reabilitação pós-AVC.

---

## Limitações esperadas após um AVC

Estas condições devem ser consideradas durante o desenvolvimento:

### Motoras
- **Hemiparesia**: Fraqueza ou paralisia em um lado do corpo
- **Tremores**: Movimentos involuntários
- **Dificuldade de Coordenação**: Movimentos descoordenados
- **Dificuldade de Precisão**: Dificuldade em controlar movimento fino
- **Fadiga**: Cansaço rápido

### Visuais
- **Hemianopsia**: Perda de visão em metade do campo visual
- **Diplopia**: Visão dupla
- **Dificuldade de Acomodação**: Focar em diferentes distâncias
- **Sensibilidade**: A luz intensa pode ser prejudicial

### Cognitivas
- **Dificuldade de Memória**: Curto prazo ou longo prazo
- **Dificuldade de Compreensão**: Entender instruções complexas
- **Desatenção**: Dificuldade em focar
- **Afasia**: Dificuldade em processar linguagem

### Fala e Audição
- **Afasia Expressiva**: Dificuldade em falar
- **Dificuldade Auditiva**: Menos comum mas possível

---

## Diretrizes de interface

### 1. Tamanho de Elementos

```
Requisito adotado pelo Movere:
- Área de toque mínima: 48×48 dp

A interface deve seguir a WCAG 2.1 nível AA sempre que aplicável. O tamanho de 48×48 dp é um requisito específico deste projeto para melhorar a acessibilidade motora.

Aplicar em:
- Botões
- Campos de entrada
- Checkboxes
- Radio buttons
- Elementos interativos
```

### 2. Espaçamento

```
Entre elementos interativos: Mínimo 8 dp

Exemplo:
┌─────────────┐
│   Botão 1   │  8 dp  ┌─────────────┐
│             │◄────►│   Botão 2   │
└─────────────┘        └─────────────┘
```

### 3. Contraste

```
Texto normal: Mínimo 4.5:1
Texto grande: Mínimo 3:1
Componentes gráficos: Mínimo 3:1

Exemplo de verificação:
- Preto (#000000) sobre branco (#FFFFFF): 21:1, aprovado.
- Cinza (#999999) sobre branco (#FFFFFF): 3,2:1, precisa ser verificado conforme o tamanho do texto.
```

### 4. Tipografia

```
Tamanho Mínimo: 14 sp (padrão)
Tamanho Corpo: 16-18 sp (preferido)
Títulos: 24-28 sp
Espaçamento entre linhas: 1.5x (mínimo)

Fontes recomendadas:
- Sans-serif: Roboto, Open Sans, Arial
- Fontes com serifa podem ser difíceis para ler

Evitar:
- Texto em itálico exclusivamente
- Texto piscante ou animado
- Fontes decorativas
```

### 5. Cores

```
NÃO depender exclusivamente de cores para transmitir informação.

Exemplo ERRADO:
"Clique no botão verde para confirmar, vermelho para cancelar"

Exemplo CORRETO:
"Clique em [✓ Confirmar] (verde) ou [✗ Cancelar] (vermelho)"

Usar:
- Ícones + Cores
- Texto + Cores
- Padrões + Cores
```

---

## Linguagem e instruções

### 1. Texto Simples

```
EVITAR: "Por favor, proceda ao posicionamento correto da câmera anterior à ejecução do exercício."

USAR: "Posicione a câmera em sua frente."
```

### 2. Frases Curtas

```
EVITAR: "Antes de começar este exercício, é importante que você
entenda completamente como fazer o movimento, pois a execução
incorreta pode resultar em lesão, então preste atenção nesta
demonstração que será rápida."

USAR: "Veja como fazer o exercício.
      Depois você tenta."
```

### 3. Uma Ação Principal por Tela

```
ERRADO: Múltiplas ações na mesma tela
┌─────────────────────┐
│    [Login]  [Help]  │
│    [FAQ]    [About] │
│    [Suporte]        │
└─────────────────────┘

CORRETO: Uma ação principal
┌─────────────────────┐
│                     │
│    [Continuar]      │
│                     │
│  Precisa de ajuda?  │
│       [↓]           │
└─────────────────────┘
```

### 4. Evitar Jargão Clínico

```
EVITAR: "Compensação de elevação glenoumeral com rotação interna"
USAR: "Ombro subindo durante o movimento"

EVITAR: "ROM inadequado"
USAR: "Movimento não completo"
```

### 5. Preparação para a gravação

- Usar cartões inteiros tocáveis com altura mínima de 96 dp.
- Mostrar ícone, frase curta e estado escrito: “Toque para confirmar” ou
  “Confirmado”.
- Adaptar a orientação de enquadramento ao exercício.
- Não depender de uma caixa de seleção pequena nem apenas de mudança de cor.
- Permitir rolagem, leitor de tela e texto ampliado a 200%.
- Manter a confirmação do ambiente por segurança, mesmo que isso exija quatro
  toques amplos.

Essas decisões reduzem a necessidade de precisão motora, mas não comprovam
usabilidade para pessoas pós-AVC. A validação manual com o público-alvo e
tecnologias assistivas continua necessária.

---

## Componentes acessíveis no Flutter

### 1. Botões

```dart
// Exemplo inadequado: botão pequeno
ElevatedButton(
  onPressed: () {},
  child: Text("OK"),
)

// Exemplo adequado: botão acessível
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    minimumSize: Size(double.infinity, 56), // 48 dp mínimo
    backgroundColor: Color(0xFF007AFF),
  ),
  child: Text(
    "Continuar",
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  ),
)
```

### 2. Labels e Hints

```dart
// Exemplo inadequado: sem rótulo
TextField(
  decoration: InputDecoration(hintText: "Digite seu email"),
)

// Exemplo adequado: com rótulo e descrição
TextField(
  decoration: InputDecoration(
    labelText: "Email",               // Label clara
    hintText: "seu@email.com",        // Hint como exemplo
    labelStyle: TextStyle(fontSize: 16),
    border: OutlineInputBorder(),
  ),
)
```

### 3. Ícones + Texto

```dart
// Exemplo inadequado: somente o ícone
IconButton(
  icon: Icon(Icons.close),
  onPressed: () {},
)

// Exemplo adequado: ícone acompanhado de texto
Row(
  children: [
    Icon(Icons.close, size: 24),
    SizedBox(width: 8),
    Text("Cancelar", style: TextStyle(fontSize: 16)),
  ],
)
```

### 4. Feedback Visual

```dart
// Retorno apresentado após a interação
ElevatedButton(
  onPressed: () {
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Adicionado com sucesso!"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  },
  child: Text("Adicionar"),
)
```

### 5. Contraste de Cores

```dart
// Contraste adequado
Color.white // Branco
Color black = Color(0xFF000000) // Preto = 21:1 contraste

// Este par precisa ter o contraste verificado
Color gray = Color(0xFF999999) // Cinza
Color.white // Pode ser insuficiente

// Use ferramenta:
// https://webaim.org/resources/contrastchecker/
```

---

## Modelo de instruções para os exercícios

Cada exercício deve seguir este modelo:

### A. PREPARAÇÃO (Antes)

```
┌──────────────────────────┐
│    FLEXÃO DE COTOVELO     │
├──────────────────────────┤
│                          │
│  [Demonstração em Vídeo] │  ← Grande e clara
│                          │
├──────────────────────────┤
│                          │
│  1. De pé ou sentado     │  ← Instruções curtas
│  2. Braço ao lado        │  ← Texto grande (16+sp)
│  3. Levante o antebraço  │  ← Uma por linha
│  4. Cuidado: Não force   │
│                          │
├──────────────────────────┤
│        [Preparado]       │  ← Botão grande
│                          │
└──────────────────────────┘
```

**Elementos:**
- Título em 28sp, bold
- Vídeo/imagem de demonstração (800×600 mínimo)
- Instruções numeradas em 16sp
- Ícone + texto para cuidados
- Botão grande para confirmar

### B. DURANTE (Ao Exercer)

```
┌──────────────────────────┐
│  Rep 3 / 10              │  ← Número grande
│     ╔════════════════╗   │
│     ║  Câmera OK    ║   │  ← Status visual claro
│     ╚════════════════╝   │
│                          │
│  Levante o seu braço     │  ← Instrução simples
│  (continuando...)        │
│                          │
│     [⏸ Pausar]           │  ← Ícone + texto
│                          │
└──────────────────────────┘
```

**Elementos:**
- Contador de repetições: Grande (28+ sp)
- Status visual acompanhado dos textos "adequado", "atenção" ou "erro".
- Instrução curta: Uma por tipo
- Feedback contínuo: Cores + ícones
- Pausa fácil de acessar

### C. DEPOIS (Resultado)

```
┌──────────────────────────┐
│      PARABÉNS! ✓         │  ← Feedback positivo
│                          │
│  Você completou:         │
│  ✓ 9 / 10 repetições    │  ← Números grandes
│                          │
│  Amplitude: 85°          │  ← Gráfico simples
│  ▓▓▓▓▓░░░░░ 85%          │
│                          │
│  Revisão do Profissional │  ← Se houver
│  "Ótimo trabalho!"       │
│                          │
│  [Próximo Exercício]     │  ← Próxima ação
│                          │
└──────────────────────────┘
```

**Elementos:**
- Resultado claro: Passou/Aviso/Falhou
- Números grandes (24+sp)
- Gráficos simples com cores
- Mensagem do profissional (quando houver)
- Próxima ação clara

---

## Retorno não visual

### 1. Haptic Feedback

```dart
// Vibração para feedback
Future<void> _provideFeedback() async {
  await Haptics.vibrate(
    duration: 100,
    intensity: 0.7,
  );
}
```

### 2. Sonoro (Quando Apropriado)

```dart
// Som para confirmação
await _audioPlayer.play(
  AssetSource('sounds/success.mp3'),
);
```

### 3. Visual + Áudio (Não apenas um)

```
EVITAR: Apenas som "Exercício completo"
USAR: Som + mensagem visual "✓ Exercício completo"
```

---

## Navegação por teclado

### Flutter

```dart
// Suporte para navegação por Tab
FocusScope.of(context).nextFocus();        // Tab
FocusScope.of(context).previousFocus();   // Shift+Tab
```

### Ordem Lógica

```
Login
 ↓
[E-mail] → [Senha] → [Entrar]
              ↑                 ↓
         [Esqueci Senha]   Home (Paciente)
```

---

## Testes de acessibilidade

### 1. Flutter Accessibility Testing

```bash
# Verificar acessibilidade
flutter run --verbose

# Em Android
adb shell uiautomator dump /static/hierarchy.xml
```

### 2. Checklist Manual

- [ ] Testar com leitor de tela (TalkBack Android, VoiceOver iOS)
- [ ] Repetir manualmente no aparelho o teste de texto a 200% já coberto pela
  suíte automatizada
- [ ] Testar com alguém com tremor (usar mouse estável)
- [ ] Complementar a verificação automática de contraste com inspeção manual
  dos estados e conteúdos carregados dinamicamente
- [ ] Testar com uma mão só
- [ ] Testar sem som
- [ ] Testar com daltonismo (simulator)

### 3. Ferramentas

```
Web (se houver versão web):
- WAVE: https://wave.webaim.org/
- Lighthouse (Chrome DevTools)
- axe DevTools

Aplicativo:
- Android Accessibility Scanner
- iOS Accessibility Inspector
- Manual com TalkBack/VoiceOver
```

---

## Lista de verificação

- [ ] Tamanho mínimo de botão: 48×48 dp
- [ ] Contraste 4.5:1 em textos
- [ ] Fonte mínima: 14 sp
- [ ] Espaçamento entre linhas: 1.5x
- [ ] Não depender só de cores
- [ ] Instruções em linguagem simples
- [ ] Uma ação principal por tela
- [ ] Feedback visual e/ou tátil
- [ ] Labels em todos os inputs
- [ ] Ícones + Texto
- [ ] Navegação por teclado funciona
- [ ] Leitor de tela funciona
- [ ] Testado com usuário de verdade
- [ ] Documentação inclui nota sobre limitações

---

## Ordem de implementação

### FASE 1: Base
- [ ] Tamanho de elementos
- [ ] Contraste
- [ ] Tipografia

### FASE 2: Interação
- [ ] Labels
- [ ] Feedback
- [ ] Navegação

### FASE 3: Teste
- [ ] Teste com ferramentas
- [ ] Teste com usuário
- [ ] Ajustes

---

## Referências

- [WCAG 2.1](https://www.w3.org/WAI/WCAG21/quickref/)
- [WebAIM](https://webaim.org/)
- [Flutter Accessibility](https://flutter.dev/docs/accessibility-and-localization/accessibility)
- [Material Design Accessibility](https://material.io/design/usability/accessibility.html)

---

**Versão**: 1.0
**Atualizado**: Outubro 2026
