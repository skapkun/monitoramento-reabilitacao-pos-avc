# Dados contextuais e de pesquisa

Este documento registra por que cada dado adicional existe. Todos os campos
abaixo são opcionais e descritivos. Eles não geram diagnóstico, prescrição ou
classificação clínica automática.

## Dados do perfil

| Campo | Finalidade prevista | Representação |
|---|---|---|
| Faixa etária | Estratificar resultados sem armazenar data de nascimento exata | Categorias de idade |
| Tempo desde o AVC | Contextualizar a fase temporal da recuperação | Meses aproximados, de 0 a 600 |
| Lado afetado | Relacionar o movimento analisado ao lado informado | Esquerdo, direito, ambos ou não informado |
| Dominância anterior ao AVC | Diferenciar lado dominante e não dominante | Esquerdo, direito, ambidestro ou não informado |
| Tipo de AVC | Descrição autorreferida para agrupamentos futuros | Isquêmico, hemorrágico ou não informado |
| Mobilidade | Contextualizar execução e necessidade de apoio | Independente, com apoio, cadeira de rodas ou não informado |
| Dispositivo auxiliar | Contextualizar apoio usado pelo paciente | Nenhum, bengala, andador, cadeira de rodas, outro ou não informado |

Os dados são editáveis pelo próprio paciente e visíveis somente a ele e ao
fisioterapeuta com vínculo aceito, conforme as regras do Firestore.

## Dados de cada sessão

| Campo | Escala | Uso permitido |
|---|---|---|
| Bem-estar | 1 a 5 | Relato subjetivo e acompanhamento longitudinal |
| Dor ou desconforto | 0 a 10 | Relato subjetivo pós-sessão; não é inferido pelo vídeo |
| Fadiga | 0 a 10 | Relato subjetivo pós-sessão; não é inferido pelo vídeo |
| Motivo técnico | Código categórico | Explicar por que a análise falhou ou foi inconclusiva |
| Vídeo original | Arquivo audiovisual opcional | Revisão da execução pelo fisioterapeuta vinculado por até 30 dias |
| Versão dos parâmetros | Identificador técnico | Rastreabilidade da configuração do algoritmo usada na sessão |
| Quadros válidos e totais | Contagens | Avaliação técnica da cobertura da detecção |
| Proporção de detecção | 0 a 1 | Indicador de qualidade técnica, sem significado diagnóstico |

Os códigos técnicos distinguem falha de processamento, poucos quadros,
visibilidade insuficiente, ausência de ciclo completo e análise inconclusiva.
Eles não representam uma condição de saúde.

## Exportação para pesquisa

O profissional pode gerar um CSV local com código de participante derivado por
SHA-256, ordem da sessão, dias desde a primeira sessão, métricas técnicas,
qualidade da detecção, versão dos parâmetros, revisão dos eventos e relatos
subjetivos. A exportação não contém nome, identificador original, identificador
da sessão ou datas absolutas.

Esse processo é **pseudonimização**, não anonimização. O arquivo continua sendo
dado de saúde e somente pode ser usado e compartilhado conforme o TCLE, o
protocolo de pesquisa e as medidas de segurança aprovadas. O aplicativo exibe
esse aviso antes de gerar o arquivo.

O vídeo é dado pessoal sensível e é apagado após o processamento por padrão.
Capturas técnicas e vídeo completo possuem escolhas separadas, ambas
desativadas inicialmente. O vídeo autorizado é cifrado no servidor, acessível
somente ao paciente e ao fisioterapeuta escolhido e removido em até 30 dias.
O paciente pode apagá-lo antes. Data e versão do consentimento ficam na sessão.
Vídeo e capturas não devem ser reutilizados para pesquisa sem base ética e
consentimento específicos para essa finalidade.

## Dados deliberadamente não coletados

- **Altura:** não é necessária para as métricas atuais, que usam ângulos e
  coordenadas normalizadas.
- **Sexo:** não participa das regras atuais de análise nem de uma hipótese de
  pesquisa definida.
- **Idade ou data de nascimento exata:** a faixa etária é suficiente para a
  finalidade prevista e reduz a precisão do dado pessoal armazenado.
- **“Grau de paralisia”:** não existe como campo genérico. Caso a pesquisa
  necessite de gravidade motora, primeiro deve ser escolhido um instrumento
  validado, definido quem pode aplicá-lo e obtida a aprovação ética pertinente.

## Antes de usar em resultados científicos

Definir protocolo, hipótese, critérios de inclusão, consentimento, plano de
análise e responsável pela avaliação clínica. A existência dos campos no
software não valida correlações nem autoriza conclusões clínicas.
