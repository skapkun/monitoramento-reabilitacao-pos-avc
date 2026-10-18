# Validação manual de acessibilidade

## O que já é automatizado

O arquivo `frontend/test/accessibility_test.dart` percorre as 25 rotas em telefone estreito e verifica:

- alvos de toque Android;
- controles interativos rotulados;
- contraste textual verificável pelo Flutter;
- ausência de exceções de layout;
- renderização com texto do sistema a 200%.

Isso reduz regressões, mas não certifica conformidade integral com a WCAG 2.1 AA.

## Roteiro TalkBack — Android

1. Ativar TalkBack nas configurações de acessibilidade.
2. Percorrer cadastro, login e recuperação de senha por gestos, sem tocar por coordenadas.
3. Confirmar que cada campo anuncia rótulo, valor, erro e obrigatoriedade.
4. Entrar como paciente e percorrer plano, preparação, gravação, resultado, bem-estar, histórico, mensagens e perfil.
5. Entrar como fisioterapeuta e percorrer pacientes, plano, sessões, avaliação, observações, mensagens e relatório.
6. Confirmar ordem lógica de foco, ausência de foco preso e anúncio das mudanças de estado.
7. Confirmar que ícones decorativos não são anunciados como ações duplicadas.

## Roteiro VoiceOver — iOS

Repetir os fluxos acima usando navegação por deslize, rotor, exploração por toque e ação padrão. Confirmar que voltar, fechar diálogos e sair permanecem acessíveis.

## Ampliação e adaptação visual

- Testar tamanhos de texto padrão, 150% e 200% no sistema.
- Testar Android e iPhone físicos, orientação retrato e paisagem.
- Confirmar que teclado virtual não encobre o campo ativo ou o botão necessário.
- Verificar estados em escala de cinza e com filtros de daltonismo.
- Verificar foco visível com teclado externo ou Switch Access.

## Teste com público-alvo

Com autorização ética e consentimento aplicáveis, observar pessoas com diferentes limitações motoras, visuais, cognitivas ou de linguagem após AVC. Registrar tarefa, necessidade de ajuda, erro, tempo, fadiga e comentário da pessoa. Não transformar resultados de teste automatizado em evidência de usabilidade clínica.

## Registro

Para cada sessão manual, registrar dispositivo, sistema, tecnologia assistiva, versão do aplicativo, fluxo executado, resultado, problema e correção. Só marcar validação humana como concluída depois da execução documentada.
