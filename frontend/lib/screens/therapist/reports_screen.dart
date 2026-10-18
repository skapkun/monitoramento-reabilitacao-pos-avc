import 'package:flutter/material.dart';

import '../../models/clinical_data.dart';
import '../../models/patient_summary.dart';
import '../../services/clinical_repository.dart';
import '../../services/report_api_service.dart';
import '../../services/research_export_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/portuguese_text.dart';
import '../../widgets/app_page.dart';
import '../../widgets/status_banner.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({required this.repository, this.patient, super.key});

  final ClinicalRepository repository;
  final PatientSummary? patient;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool generating = false;
  bool exporting = false;

  Future<void> generate(List<RehabilitationSession> sessions) async {
    final patient = widget.patient;
    if (patient == null) return;
    setState(() => generating = true);
    final service = ReportApiService();
    try {
      await service.generateAndShare(
        patientId: patient.id,
        patientName: patient.name,
        sessions: sessions,
      );
    } on ReportApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível compartilhar o relatório.'),
          ),
        );
      }
    } finally {
      service.close();
      if (mounted) setState(() => generating = false);
    }
  }

  Future<void> exportResearchData(List<RehabilitationSession> sessions) async {
    final patient = widget.patient;
    if (patient == null || sessions.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar dados para pesquisa?'),
        content: const Text(
          'O arquivo não inclui nome, identificador original nem datas absolutas. Mesmo assim, contém dados de saúde pseudonimizados. Use somente conforme o TCLE e o protocolo ético, e mantenha o arquivo protegido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exportar CSV'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => exporting = true);
    try {
      await ResearchExportService().generateAndShare(
        patientId: patient.id,
        sessions: sessions,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível exportar os dados.')),
        );
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.patient;
    return AppPage(
      title: 'Relatório longitudinal',
      child: selected == null
          ? const Text(
              'Selecione um paciente na lista para preparar um relatório.',
            )
          : StreamBuilder<List<RehabilitationSession>>(
              stream: widget.repository.watchPatientSessions(selected.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sessions = snapshot.data!;
                final completed = sessions
                    .where((item) => item.status == 'completed')
                    .length;
                final repetitions = sessions.fold<int>(
                  0,
                  (sum, item) => sum + item.repetitions,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      selected.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      onPressed: generating ? null : () => generate(sessions),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(
                        generating
                            ? 'Gerando PDF…'
                            : 'Gerar e compartilhar PDF',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: exporting || sessions.isEmpty
                          ? null
                          : () => exportResearchData(sessions),
                      icon: const Icon(Icons.table_view_outlined),
                      label: Text(
                        exporting
                            ? 'Preparando CSV…'
                            : 'Exportar CSV pseudonimizado',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resumo',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              quantity(
                                sessions.length,
                                'sessão registrada',
                                'sessões registradas',
                              ),
                            ),
                            Text(
                              quantity(
                                completed,
                                'sessão concluída',
                                'sessões concluídas',
                              ),
                            ),
                            Text(
                              quantity(
                                repetitions,
                                'repetição observada',
                                'repetições observadas',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const StatusBanner(
                      icon: Icons.info_outline,
                      title: 'Documento descritivo',
                      message:
                          'O relatório organiza dados técnicos do sistema e não constitui laudo, diagnóstico ou avaliação clínica.',
                      backgroundColor: AppColors.primarySoft,
                      foregroundColor: AppColors.primarySoftText,
                    ),
                  ],
                );
              },
            ),
    );
  }
}
