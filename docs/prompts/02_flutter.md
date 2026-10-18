# Etapa 2 — Desenvolvimento do aplicativo Flutter

## Leia antes

- [SISTEMA.md](../SISTEMA.md)
- [ARQUITETURA.md](../ARQUITETURA.md)
- [REQUISITOS.md](../REQUISITOS.md)
- [ACESSIBILIDADE.md](../ACESSIBILIDADE.md)
- [SISTEMA_VISUAL.md](../SISTEMA_VISUAL.md)
- [PLANO_DESENVOLVIMENTO.md](../PLANO_DESENVOLVIMENTO.md)
- [PROGRESSO.md](../PROGRESSO.md)

## Objetivo

Desenvolver a estrutura, a navegação e a experiência do aplicativo móvel da plataforma de telereabilitação para pacientes e fisioterapeutas.

## Perfil do paciente

Implementar as seguintes telas:

- Login
- Home
- Meu plano
- Exercício
- Preparação
- Gravação ou seleção de vídeo
- Processamento
- Resultado
- Histórico
- Evolução
- Perfil

## Perfil do fisioterapeuta

Implementar as seguintes telas:

- Login
- Dashboard
- Pacientes
- Perfil do paciente
- Plano de exercícios
- Sessões
- Evolução
- Relatórios
- Observações

## Acessibilidade

- Seguir a WCAG 2.1 nível AA sempre que aplicável.
- Utilizar áreas de toque com pelo menos 48×48 dp.
- Manter contraste adequado e textos legíveis.
- Utilizar linguagem simples e instruções curtas.
- Priorizar uma ação principal por tela.
- Manter a navegação simples e previsível.
- Fornecer feedback visual claro.
- Não depender exclusivamente de cores ou áudio.
- Utilizar ícones acompanhados de texto.
- Exibir mensagens de erro compreensíveis.

## Limites desta etapa

- Não implementar MediaPipe, OpenCV ou regras de análise dos exercícios.
- Não implementar o processamento real de visão computacional.
- Não implementar critérios clínicos.
- Não apresentar dados simulados como resultados reais.
- Não iniciar o backend FastAPI neste prompt.
- Não integrar Firebase ou API antes que a navegação e a experiência básica estejam verificadas.

Utilize dados simulados claramente identificados quando forem necessários para demonstrar os fluxos. Prepare contratos e serviços substituíveis para que os dados simulados possam ser trocados posteriormente pelas integrações reais.

## Instruções

1. Analise o repositório antes de alterar arquivos.
2. Preserve o que já estiver funcionando.
3. Estruture telas, componentes, modelos, serviços, autenticação, comunicação futura com a API, gerenciamento de estado e acessibilidade.
4. Crie componentes reutilizáveis e evite telas extensas ou duplicadas.
5. Implemente cores, tipografia, espaçamento e ícones exclusivamente pelo tema e pelos componentes definidos em `SISTEMA_VISUAL.md`.
6. Faça primeiro a navegação completa entre as telas dos dois perfis.
7. Em seguida, implemente estados de carregamento, vazio, erro e sucesso usando dados simulados.
8. Verifique contraste, ampliação de texto, áreas de toque e semântica antes de iniciar integrações externas.
9. Crie testes de componentes, navegação e regras de apresentação.

## Entrega

Informe:

- arquivos criados e modificados;
- telas e componentes implementados;
- fluxos de navegação concluídos;
- dados simulados utilizados;
- verificações de acessibilidade realizadas;
- testes executados;
- pendências para Firebase, FastAPI e visão computacional.
