import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';
import '../../widgets/status_banner.dart';

class AnalysisMethodScreen extends StatelessWidget {
  const AnalysisMethodScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Como a análise funciona',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StatusBanner(
          icon: Icons.science_outlined,
          title: 'Métricas técnicas experimentais',
          message:
              'Os resultados apoiam a revisão profissional. Não são diagnóstico, laudo, medida clínica validada nem indicação automática de segurança.',
          backgroundColor: AppColors.warningBackground,
          foregroundColor: AppColors.warningText,
        ),
        const SizedBox(height: AppSpacing.lg),
        _heading(context, 'Etapas do processamento'),
        const _MethodCard(
          icon: Icons.video_file_outlined,
          title: 'Do vídeo ao resultado',
          body:
              'O vídeo é dividido em frames. O MediaPipe estima pontos do corpo ou da mão. O Movere usa esses pontos em regras matemáticas para contar ciclos, calcular métricas e destacar momentos para revisão. O vídeo temporário é apagado após o processamento.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _heading(context, 'Como cada métrica é calculada'),
        const _MethodCard(
          icon: Icons.architecture_outlined,
          title: 'Ângulo e amplitude',
          body:
              'O ângulo 2D é calculado entre três pontos por produto escalar. A amplitude de uma repetição é o maior ângulo menos o menor ângulo observados naquele ciclo.',
        ),
        const _MethodCard(
          icon: Icons.repeat,
          title: 'Repetições',
          body:
              'Uma repetição só é contada quando o movimento atravessa os limiares de início, flexão ou fechamento e retorna ao estado inicial. Movimentos parciais podem ficar sem contagem.',
        ),
        const _MethodCard(
          icon: Icons.timer_outlined,
          title: 'Duração e velocidade média',
          body:
              'Duração é o tempo entre início e fim do ciclo. Velocidade média é a amplitude dividida pela duração; não representa a velocidade instantânea do membro.',
        ),
        const _MethodCard(
          icon: Icons.compare_arrows,
          title: 'Diferença entre lados',
          body:
              'Quando os dois lados estão visíveis, é calculada a média da diferença absoluta entre seus ângulos no mesmo frame. A interpretação só é adequada quando o protocolo pede movimentos comparáveis dos dois lados.',
        ),
        const _MethodCard(
          icon: Icons.visibility_outlined,
          title: 'Qualidade técnica',
          body:
              'Frames válidos são aqueles com os pontos necessários e visibilidade suficiente. A confiança exibida é uma medida heurística de qualidade da detecção, não uma probabilidade de correção clínica.',
        ),
        const _MethodCard(
          icon: Icons.pinch_outlined,
          title: 'Pinça',
          body:
              'A distância entre polegar e indicador usa coordenadas normalizadas da imagem. Ela varia com enquadramento e distância da câmera e não corresponde a centímetros.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _heading(context, 'Valores técnicos padrão'),
        const _ThresholdTable(),
        const SizedBox(height: AppSpacing.lg),
        _heading(context, 'Meta do paciente e limiar do algoritmo'),
        const StatusBanner(
          icon: Icons.tune,
          title: 'São valores diferentes',
          message:
              'Séries, repetições, frequência, lado, cadência, intervalo e meta de amplitude são metas da prescrição. Separadamente, o profissional pode ativar uma calibração experimental dos limiares de detecção, que altera a contagem automática e fica registrada na sessão.',
          backgroundColor: AppColors.primarySoft,
          foregroundColor: AppColors.primarySoftText,
        ),
        const SizedBox(height: AppSpacing.md),
        const _MethodCard(
          icon: Icons.accessible_forward,
          title: 'Mobilidade reduzida',
          body:
              'O nível de mobilidade não adapta o algoritmo automaticamente. Quando necessário, o fisioterapeuta pode calibrar manualmente a faixa observada, dentro de limites protegidos e com justificativa. O ajuste não é recomendação clínica nem comprovação de movimento correto.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _heading(context, 'Limitações de gravação'),
        const _MethodCard(
          icon: Icons.camera_alt_outlined,
          title: 'Imagem 2D',
          body:
              'Perspectiva, rotação do corpo, distância, iluminação, roupas, oclusões e câmera em movimento podem alterar os pontos estimados. Compare sessões somente com condições de gravação semelhantes.',
        ),
        const _MethodCard(
          icon: Icons.health_and_safety_outlined,
          title: 'Teste com voluntário saudável',
          body:
              'Esse teste verifica funcionamento, repetibilidade e usabilidade. Ele não demonstra eficácia, validade clínica ou segurança para pessoas pós-AVC.',
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Versões atuais: elbow-flexion-v1, squat-v1 e pinch-v1.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  static Widget _heading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(text, style: Theme.of(context).textTheme.headlineMedium),
  );
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ThresholdTable extends StatelessWidget {
  const _ThresholdTable();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const [
        DataColumn(label: Text('Exercício')),
        DataColumn(label: Text('Início')),
        DataColumn(label: Text('Mudança')),
        DataColumn(label: Text('Retorno')),
      ],
      rows: const [
        DataRow(
          cells: [
            DataCell(Text('Cotovelo')),
            DataCell(Text('≥ 160°')),
            DataCell(Text('≤ 90°')),
            DataCell(Text('≥ 160°')),
          ],
        ),
        DataRow(
          cells: [
            DataCell(Text('Agachamento')),
            DataCell(Text('≥ 160°')),
            DataCell(Text('≤ 100°')),
            DataCell(Text('≥ 160°')),
          ],
        ),
        DataRow(
          cells: [
            DataCell(Text('Pinça')),
            DataCell(Text('≥ 0,10')),
            DataCell(Text('≤ 0,05')),
            DataCell(Text('≥ 0,10')),
          ],
        ),
      ],
    ),
  );
}
