import 'package:flutter/material.dart';

import '../../models/clinical_data.dart';
import '../../models/patient_summary.dart';
import '../../services/clinical_repository.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';
import '../../widgets/empty_state.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({required this.repository, this.patient, super.key});

  final ClinicalRepository repository;
  final PatientSummary? patient;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final controller = TextEditingController();
  bool visibleToPatient = true;
  bool saving = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final patient = widget.patient;
    if (patient == null || controller.text.trim().length < 2) return;
    setState(() => saving = true);
    try {
      await widget.repository.addNote(
        patientId: patient.id,
        text: controller.text,
        visibleToPatient: visibleToPatient,
      );
      controller.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Observação registrada.')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    return AppPage(
      title: 'Observações',
      child: patient == null
          ? const Text(
              'Selecione um paciente na lista antes de registrar observações.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  patient.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Nova observação ou orientação',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visível para o paciente'),
                  value: visibleToPatient,
                  onChanged: (value) =>
                      setState(() => visibleToPatient = value),
                ),
                ElevatedButton.icon(
                  onPressed: saving ? null : save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Salvando…' : 'Registrar observação'),
                ),
                const SizedBox(height: AppSpacing.lg),
                StreamBuilder<List<ProfessionalNote>>(
                  stream: widget.repository.watchNotes(patient.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data!.isEmpty) {
                      return const EmptyState(
                        title: 'Sem observações',
                        message:
                            'Registre uma orientação para iniciar o acompanhamento.',
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Observações registradas',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...snapshot.data!.map(
                          (note) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(
                                  AppSpacing.md,
                                ),
                                leading: Icon(
                                  note.visibleToPatient
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                title: Text(note.text),
                                subtitle: Text(
                                  '${_date(note.createdAt)} • ${note.visibleToPatient ? 'Visível ao paciente' : 'Somente profissional'}',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }

  String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
