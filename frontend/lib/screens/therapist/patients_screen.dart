import 'package:flutter/material.dart';

import '../../models/patient_summary.dart';
import '../../routes/app_routes.dart';
import '../../services/clinical_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/portuguese_text.dart';
import '../../widgets/app_page.dart';
import '../../widgets/empty_state.dart';

enum PatientFilter { all, attention, inactive, review, noSessions }

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({
    ClinicalRepository? repository,
    this.initialFilter = PatientFilter.all,
    super.key,
  }) : repository = repository ?? const DemoClinicalRepository();

  final ClinicalRepository repository;
  final PatientFilter initialFilter;

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final searchController = TextEditingController();
  late PatientFilter filter;
  List<PatientSummary> allPatients = const [];

  @override
  void initState() {
    super.initState();
    filter = widget.initialFilter;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<PatientSummary> get filteredPatients {
    final search = searchController.text.trim().toLowerCase();
    return allPatients.where((patient) {
      final matchesSearch = patient.name.toLowerCase().contains(search);
      final matchesFilter = switch (filter) {
        PatientFilter.all => true,
        PatientFilter.attention => patient.needsAttention,
        PatientFilter.inactive => patient.isInactive,
        PatientFilter.review => patient.requiresReview,
        PatientFilter.noSessions => patient.sessions == 0,
      };
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> requestLink() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vincular paciente'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Código do paciente',
            helperText: 'O paciente encontra este código no próprio perfil.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Enviar convite'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.trim().isEmpty) return;
    try {
      await widget.repository.requestPatientLink(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Convite enviado ao paciente.')),
        );
      }
    } on ClinicalRepositoryException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PatientSummary>>(
      stream: widget.repository.watchLinkedPatients(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const AppPage(
            title: 'Pacientes',
            child: Text('Não foi possível carregar os pacientes.'),
          );
        }
        if (!snapshot.hasData) {
          return const AppPage(
            title: 'Pacientes',
            child: Center(child: CircularProgressIndicator()),
          );
        }
        allPatients = snapshot.data!;
        final patients = filteredPatients;
        return AppPage(
          title: 'Pacientes',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('buscar_paciente'),
                controller: searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Buscar paciente',
                  hintText: 'Digite o nome',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: filter == PatientFilter.all,
                    onSelected: (_) =>
                        setState(() => filter = PatientFilter.all),
                  ),
                  FilterChip(
                    label: const Text('Precisam de atenção'),
                    selected: filter == PatientFilter.attention,
                    onSelected: (_) =>
                        setState(() => filter = PatientFilter.attention),
                  ),
                  FilterChip(
                    label: const Text('Sem atividade'),
                    selected: filter == PatientFilter.inactive,
                    onSelected: (_) =>
                        setState(() => filter = PatientFilter.inactive),
                  ),
                  FilterChip(
                    label: const Text('Sessões para revisar'),
                    selected: filter == PatientFilter.review,
                    onSelected: (_) =>
                        setState(() => filter = PatientFilter.review),
                  ),
                  FilterChip(
                    label: const Text('Sem sessões'),
                    selected: filter == PatientFilter.noSessions,
                    onSelected: (_) =>
                        setState(() => filter = PatientFilter.noSessions),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                quantity(patients.length, 'paciente', 'pacientes'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: requestLink,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Vincular paciente'),
              ),
              const SizedBox(height: AppSpacing.md),
              if (patients.isEmpty)
                EmptyState(
                  title: 'Nenhum paciente encontrado',
                  message: 'Revise a busca ou limpe os filtros.',
                  actionLabel: 'Limpar filtros',
                  onAction: () => setState(() {
                    searchController.clear();
                    filter = PatientFilter.all;
                  }),
                )
              else
                ...patients.map(
                  (patient) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.patientDetails,
                          arguments: patient,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                child: Text(patient.initials),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patient.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    Text(
                                      patient.lastSession,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Wrap(
                                      spacing: AppSpacing.sm,
                                      runSpacing: AppSpacing.xs,
                                      children: [
                                        _PatientIndicator(
                                          icon: Icons.event_available_outlined,
                                          label: '${patient.sessions} sessões',
                                        ),
                                        _PatientIndicator(
                                          icon: Icons.trending_up,
                                          label: '${patient.adherence}% adesão',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Row(
                                      children: [
                                        Icon(
                                          patient.requiresReview
                                              ? Icons.warning_amber
                                              : Icons.check_circle_outline,
                                          size: 20,
                                          color: patient.requiresReview
                                              ? AppColors.warningText
                                              : AppColors.success,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Expanded(child: Text(patient.status)),
                                      ],
                                    ),
                                    if (patient.alerts.isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      ...patient.alerts
                                          .take(2)
                                          .map(
                                            (alert) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: AppSpacing.xs,
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(
                                                    Icons.priority_high,
                                                    size: 20,
                                                    color:
                                                        AppColors.warningText,
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpacing.xs,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      alert.title,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      if (patient.alerts.length > 2)
                                        Text(
                                          '+ ${quantity(patient.alerts.length - 2, 'alerta', 'alertas')} ao abrir o perfil',
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PatientIndicator extends StatelessWidget {
  const _PatientIndicator({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 200),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.successSoft,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppColors.successSoftText),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.successSoftText),
          ),
        ),
      ],
    ),
  );
}
