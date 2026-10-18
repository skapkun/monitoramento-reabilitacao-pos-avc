import 'package:flutter/material.dart';

import '../../models/clinical_data.dart';
import '../../models/exercise.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';

class PreparationScreen extends StatefulWidget {
  const PreparationScreen({this.plan, super.key});

  final TherapyPlan? plan;

  @override
  State<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends State<PreparationScreen> {
  late final List<_PreparationItem> items;
  late final List<bool> confirmed;

  @override
  void initState() {
    super.initState();
    final type = widget.plan?.exerciseType ?? MockExercises.elbowFlexion.type;
    final visibleBodyPart = switch (type) {
      'squat' => const _PreparationItem(
        label: 'Meu corpo inteiro aparece na tela',
        detail: 'Ombros, quadris, joelhos e pés precisam aparecer.',
        icon: Icons.accessibility_new,
      ),
      'pinch' => const _PreparationItem(
        label: 'Minha mão aparece inteira na tela',
        detail: 'O polegar e o indicador precisam aparecer.',
        icon: Icons.back_hand_outlined,
      ),
      _ => const _PreparationItem(
        label: 'Meu braço inteiro aparece na tela',
        detail: 'O ombro, o cotovelo e a mão precisam aparecer.',
        icon: Icons.accessibility_new,
      ),
    };
    items = [
      const _PreparationItem(
        label: 'Não há objetos no caminho',
        detail: 'Afaste tapetes, móveis e outros obstáculos.',
        icon: Icons.cleaning_services_outlined,
      ),
      const _PreparationItem(
        label: 'O celular está bem apoiado',
        detail: 'Ele não deve se mexer durante a gravação.',
        icon: Icons.phone_android,
      ),
      visibleBodyPart,
      const _PreparationItem(
        label: 'Entendi as instruções e estou pronto',
        detail: 'Se tiver dúvida, volte e leia as instruções novamente.',
        icon: Icons.task_alt,
      ),
    ];
    confirmed = List.filled(items.length, false);
  }

  bool get isReady => confirmed.every((value) => value);

  void toggle(int index) {
    setState(() => confirmed[index] = !confirmed[index]);
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Preparação',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Antes de começar',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Toque em cada cartão quando estiver tudo certo. Se precisar, peça ajuda a alguém.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var index = 0; index < items.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _PreparationCheckCard(
                key: Key('preparacao_item_$index'),
                item: items[index],
                checked: confirmed[index],
                onTap: () => toggle(index),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton.icon(
            key: const Key('iniciar_gravacao'),
            onPressed: isReady
                ? () => Navigator.pushNamed(
                    context,
                    AppRoutes.recording,
                    arguments: widget.plan,
                  )
                : null,
            icon: const Icon(Icons.videocam_outlined),
            label: const Text('Começar gravação'),
          ),
          if (!isReady) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Confirme os quatro cartões acima para continuar.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _PreparationItem {
  const _PreparationItem({
    required this.label,
    required this.detail,
    required this.icon,
  });

  final String label;
  final String detail;
  final IconData icon;
}

class _PreparationCheckCard extends StatelessWidget {
  const _PreparationCheckCard({
    required this.item,
    required this.checked,
    required this.onTap,
    super.key,
  });

  final _PreparationItem item;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    checked: checked,
    label: item.label,
    value: checked ? 'Confirmado' : 'Ainda não confirmado',
    onTap: onTap,
    excludeSemantics: true,
    child: Card(
      color: checked ? AppColors.successSoft : AppColors.surface,
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: checked ? AppColors.success : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    checked ? Icons.check : item.icon,
                    color: checked ? Colors.white : AppColors.primarySoftText,
                    size: 30,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(item.detail),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        checked ? 'Confirmado' : 'Toque para confirmar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: checked
                              ? AppColors.successSoftText
                              : AppColors.primarySoftText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
