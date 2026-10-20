import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../models/clinical_data.dart';
import '../../services/clinical_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';
import '../../widgets/status_banner.dart';

class SessionVideoScreen extends StatefulWidget {
  const SessionVideoScreen({
    required this.repository,
    required this.session,
    required this.allowDelete,
    super.key,
  });

  final ClinicalRepository repository;
  final RehabilitationSession session;
  final bool allowDelete;

  @override
  State<SessionVideoScreen> createState() => _SessionVideoScreenState();
}

class _SessionVideoScreenState extends State<SessionVideoScreen> {
  VideoPlayerController? controller;
  File? temporaryFile;
  String? error;
  bool deleting = false;
  late bool annotated;
  final Map<int, Uint8List> thumbnails = {};

  @override
  void initState() {
    super.initState();
    annotated = true;
    load();
  }

  Future<void> load() async {
    final previousController = controller;
    final previousFile = temporaryFile;
    if (previousController != null) {
      previousController.removeListener(_onVideoChanged);
      await previousController.dispose();
    }
    if (previousFile != null) {
      await previousFile.delete().catchError((_) => previousFile);
    }
    if (mounted) {
      setState(() {
        controller = null;
        temporaryFile = null;
        error = null;
        thumbnails.clear();
      });
    }
    try {
      final path = await widget.repository.downloadSessionVideo(
        widget.session,
        annotated: annotated,
      );
      final file = File(path);
      final player = VideoPlayerController.file(file);
      await player.initialize();
      if (!mounted) {
        await player.dispose();
        await file.delete().catchError((_) => file);
        return;
      }
      setState(() {
        temporaryFile = file;
        controller = player;
      });
      player.addListener(_onVideoChanged);
      await _createThumbnails(file.path);
    } on ClinicalRepositoryException catch (failure) {
      if (mounted) setState(() => error = failure.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Não foi possível carregar o vídeo da sessão.');
      }
    }
  }

  void _onVideoChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _createThumbnails(String path) async {
    for (
      var index = 0;
      index < widget.session.movementEvents.length && index < 8;
      index++
    ) {
      try {
        final event = widget.session.movementEvents[index];
        final bytes = await VideoThumbnail.thumbnailData(
          video: path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 640,
          timeMs: (event.startSeconds * 1000).round(),
          quality: 80,
        );
        if (bytes != null && mounted) {
          setState(() => thumbnails[index] = bytes);
        }
      } catch (_) {}
    }
  }

  MovementEvent? get _currentEvent {
    final position = controller?.value.position.inMilliseconds ?? 0;
    final seconds = position / 1000;
    for (final event in widget.session.movementEvents) {
      if (seconds >= event.startSeconds && seconds <= event.endSeconds) {
        return event;
      }
    }
    return null;
  }

  Future<void> _openEvent(MovementEvent event) async {
    final player = controller;
    if (player == null) return;
    await player.seekTo(
      Duration(milliseconds: (event.startSeconds * 1000).round()),
    );
    await player.pause();
    if (mounted) setState(() {});
  }

  Future<void> deleteVideo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir vídeo compartilhado?'),
        content: const Text(
          'O arquivo será removido e não poderá mais ser assistido pelo fisioterapeuta. As métricas da sessão serão mantidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir vídeo'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => deleting = true);
    try {
      await widget.repository.deleteSessionVideo(widget.session);
      if (mounted) Navigator.pop(context, true);
    } on ClinicalRepositoryException catch (failure) {
      if (mounted) {
        setState(() {
          deleting = false;
          error = failure.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          deleting = false;
          error = 'Não foi possível excluir o vídeo.';
        });
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    temporaryFile?.delete().catchError((_) => temporaryFile!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Vídeo da sessão',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusBanner(
          icon: annotated ? Icons.analytics_outlined : Icons.lock_outline,
          title: annotated ? 'Vídeo anotado privado' : 'Vídeo original privado',
          message: annotated
              ? 'O esqueleto, a medida e a contagem são experimentais e precisam de revisão profissional.'
              : 'Este arquivo contém imagem pessoal e só pode ser acessado pelo paciente e pelo fisioterapeuta vinculado.',
          backgroundColor: AppColors.primarySoft,
          foregroundColor: AppColors.primarySoftText,
        ),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              icon: Icon(Icons.analytics_outlined),
              label: Text('Anotado'),
            ),
            ButtonSegment(
              value: false,
              icon: Icon(Icons.video_file_outlined),
              label: Text('Original'),
            ),
          ],
          selected: {annotated},
          onSelectionChanged: (selection) {
            final next = selection.first;
            if (next == annotated) return;
            setState(() => annotated = next);
            load();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        if (error != null)
          StatusBanner(
            icon: Icons.error_outline,
            title: 'Vídeo indisponível',
            message: error!,
            backgroundColor: AppColors.errorBackground,
            foregroundColor: AppColors.errorText,
          )
        else if (controller == null)
          const Center(child: CircularProgressIndicator())
        else ...[
          AspectRatio(
            aspectRatio: controller!.value.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                VideoPlayer(controller!),
                if (_currentEvent != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Semantics(
                      liveRegion: true,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        color: _currentEvent!.severity == 'positive'
                            ? AppColors.successSoftText.withValues(alpha: 0.92)
                            : AppColors.warningText.withValues(alpha: 0.92),
                        child: Text(
                          _currentEvent!.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                controller!.value.isPlaying
                    ? controller!.pause()
                    : controller!.play();
              });
            },
            icon: Icon(
              controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
            label: Text(
              controller!.value.isPlaying ? 'Pausar vídeo' : 'Reproduzir vídeo',
            ),
          ),
          if (widget.session.movementEvents.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Momentos destacados',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Toque em uma imagem para pausar o vídeo naquele momento. As marcações são técnicas e precisam de revisão profissional.',
            ),
            const SizedBox(height: AppSpacing.md),
            for (
              var index = 0;
              index < widget.session.movementEvents.length && index < 8;
              index++
            )
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () =>
                        _openEvent(widget.session.movementEvents[index]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (thumbnails[index] != null)
                          Semantics(
                            image: true,
                            label:
                                'Captura do vídeo: ${widget.session.movementEvents[index].title}',
                            child: Image.memory(
                              thumbnails[index]!,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          const SizedBox(
                            height: 100,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.session.movementEvents[index].title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                widget
                                    .session
                                    .movementEvents[index]
                                    .description,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Abrir em ${_duration(widget.session.movementEvents[index].startSeconds)}',
                                style: const TextStyle(
                                  color: AppColors.primarySoftText,
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
          ],
        ],
        if (widget.session.videoRetentionUntil != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Exclusão programada até ${_date(widget.session.videoRetentionUntil!)}.',
            textAlign: TextAlign.center,
          ),
        ],
        if (widget.allowDelete) ...[
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: deleting ? null : deleteVideo,
            icon: const Icon(Icons.delete_outline),
            label: Text(deleting ? 'Excluindo…' : 'Excluir vídeo agora'),
          ),
        ],
      ],
    ),
  );

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _duration(double seconds) {
    final value = Duration(milliseconds: (seconds * 1000).round());
    return '${value.inMinutes}:${value.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }
}
