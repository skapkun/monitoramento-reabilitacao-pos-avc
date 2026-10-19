import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/selected_video.dart';
import '../../models/clinical_data.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';
import '../../widgets/status_banner.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({
    this.imagePicker,
    this.allowSimulation = true,
    this.plan,
    super.key,
  });

  final ImagePicker? imagePicker;
  final bool allowSimulation;
  final TherapyPlan? plan;

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late final ImagePicker imagePicker = widget.imagePicker ?? ImagePicker();
  bool selecting = false;
  bool shareWithTherapist = false;
  bool shareFullVideo = false;

  void startMockProcessing(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.processing);
  }

  Future<void> selectVideo(ImageSource source) async {
    setState(() => selecting = true);
    try {
      final video = await imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 2),
      );
      if (!mounted || video == null) return;
      Navigator.pushNamed(
        context,
        AppRoutes.processing,
        arguments: SelectedVideo(
          video,
          exerciseType: widget.plan?.exerciseType ?? 'elbow_flexion',
          shareWithTherapist: shareWithTherapist,
          consentAt: shareWithTherapist ? DateTime.now() : null,
          shareFullVideo: shareFullVideo,
          videoConsentAt: shareFullVideo ? DateTime.now() : null,
          plan: widget.plan,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível acessar o vídeo. Verifique as permissões do dispositivo.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => selecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Gravação',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 260),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 96, color: Colors.white),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Grave ou selecione um vídeo',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const StatusBanner(
            icon: Icons.science_outlined,
            title: 'Como gravar',
            message:
                'Deixe o celular parado, procure um lugar claro e mantenha o movimento inteiro na tela.',
            backgroundColor: AppColors.primarySoft,
            foregroundColor: AppColors.primarySoftText,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Compartilhamento opcional',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Você não precisa marcar nenhuma opção para gravar, selecionar e analisar o vídeo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            color: AppColors.accentSoft,
            child: CheckboxListTile(
              key: const Key('compartilhar_video'),
              value: shareWithTherapist,
              onChanged: selecting
                  ? null
                  : (value) =>
                        setState(() => shareWithTherapist = value ?? false),
              title: const Text('Compartilhar capturas da análise'),
              subtitle: const Text(
                'Opcional. Guarda até 4 imagens para o fisioterapeuta revisar. Não guarda o vídeo completo.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            color: AppColors.primarySoft,
            child: CheckboxListTile(
              key: const Key('compartilhar_video_completo'),
              value: shareFullVideo,
              onChanged: selecting
                  ? null
                  : (value) => setState(() => shareFullVideo = value ?? false),
              title: const Text('Compartilhar vídeo completo por 30 dias'),
              subtitle: const Text(
                'Opcional. Somente você e o fisioterapeuta vinculado poderão assistir. Você pode apagar antes dos 30 dias.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            key: const Key('gravar_video'),
            onPressed: selecting ? null : () => selectVideo(ImageSource.camera),
            icon: const Icon(Icons.fiber_manual_record),
            label: Text(selecting ? 'Aguarde…' : 'Gravar vídeo'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            key: const Key('selecionar_video'),
            onPressed: selecting
                ? null
                : () => selectVideo(ImageSource.gallery),
            icon: const Icon(Icons.video_library_outlined),
            label: const Text('Selecionar vídeo'),
          ),
          if (widget.allowSimulation) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            const Text('Modo demonstração', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              key: const Key('simular_gravacao'),
              onPressed: () => startMockProcessing(context),
              icon: const Icon(Icons.science_outlined),
              label: const Text('Continuar sem vídeo real'),
            ),
          ],
        ],
      ),
    );
  }
}
