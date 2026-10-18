import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_repository.dart';
import '../theme/app_spacing.dart';

Future<UserProfile?> showProfileEditDialog(
  BuildContext context, {
  required UserProfile profile,
  required AuthRepository repository,
}) => showDialog<UserProfile>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _ProfileEditDialog(profile: profile, repository: repository),
);

class _ProfileEditDialog extends StatefulWidget {
  const _ProfileEditDialog({required this.profile, required this.repository});

  final UserProfile profile;
  final AuthRepository repository;

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController registrationController;
  late final TextEditingController monthsSinceStrokeController;
  bool saving = false;
  String? error;
  late String affectedSide;
  late String strokeType;
  late String mobility;
  late String ageRange;
  late String dominantSide;
  late String assistiveDevice;
  late String participantContext;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.profile.name);
    phoneController = TextEditingController(text: widget.profile.phone);
    registrationController = TextEditingController(
      text: widget.profile.professionalRegistration,
    );
    affectedSide = widget.profile.affectedSide ?? 'not_informed';
    strokeType = widget.profile.strokeType ?? 'not_informed';
    mobility = widget.profile.mobility ?? 'not_informed';
    ageRange = widget.profile.ageRange ?? 'not_informed';
    dominantSide = widget.profile.dominantSide ?? 'not_informed';
    assistiveDevice = widget.profile.assistiveDevice ?? 'not_informed';
    participantContext = widget.profile.participantContext;
    monthsSinceStrokeController = TextEditingController(
      text: widget.profile.monthsSinceStroke?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    registrationController.dispose();
    monthsSinceStrokeController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final updated = await widget.repository.updateProfile(
        name: nameController.text,
        phone: phoneController.text,
        professionalRegistration: registrationController.text,
        affectedSide: participantContext == 'healthy_volunteer'
            ? 'not_informed'
            : affectedSide,
        strokeType: participantContext == 'healthy_volunteer'
            ? 'not_informed'
            : strokeType,
        mobility: mobility,
        ageRange: ageRange,
        monthsSinceStroke: participantContext == 'healthy_volunteer'
            ? null
            : int.tryParse(monthsSinceStrokeController.text),
        dominantSide: dominantSide,
        assistiveDevice: assistiveDevice,
        participantContext: participantContext,
      );
      if (mounted) Navigator.pop(context, updated);
    } on AuthRepositoryException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Editar perfil'),
    content: SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('editar_nome'),
              controller: nameController,
              enabled: !saving,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome completo'),
              validator: (value) {
                final length = value?.trim().length ?? 0;
                if (length < 2) return 'Informe seu nome completo.';
                if (length > 120) return 'Use no máximo 120 caracteres.';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('editar_telefone'),
              controller: phoneController,
              enabled: !saving,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: const InputDecoration(
                labelText: 'Telefone',
                hintText: 'Opcional',
              ),
              validator: (value) => (value?.trim().length ?? 0) > 30
                  ? 'Use no máximo 30 caracteres.'
                  : null,
            ),
            if (widget.profile.role == UserRole.therapist) ...[
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('editar_registro_profissional'),
                controller: registrationController,
                enabled: !saving,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Registro profissional',
                  helperText: 'Número e região do CREFITO',
                ),
                validator: (value) {
                  final length = value?.trim().length ?? 0;
                  if (length < 2) return 'Informe o registro profissional.';
                  if (length > 60) return 'Use no máximo 60 caracteres.';
                  return null;
                },
              ),
            ],
            if (widget.profile.role == UserRole.patient) ...[
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                key: const Key('editar_contexto_participante'),
                isExpanded: true,
                initialValue: participantContext,
                decoration: const InputDecoration(
                  labelText: 'Contexto deste perfil',
                  helperText:
                      'Use voluntário saudável somente em testes técnicos.',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'post_stroke',
                    child: Text('Pessoa em acompanhamento pós-AVC'),
                  ),
                  DropdownMenuItem(
                    value: 'healthy_volunteer',
                    child: Text('Voluntário saudável — teste técnico'),
                  ),
                  DropdownMenuItem(
                    value: 'not_informed',
                    child: Text('Não informado'),
                  ),
                ],
                onChanged: saving
                    ? null
                    : (value) => setState(
                        () => participantContext = value ?? participantContext,
                      ),
              ),
              if (participantContext == 'healthy_volunteer') ...[
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Os resultados deste perfil demonstram funcionamento e usabilidade. Não validam aplicação clínica pós-AVC.',
                ),
              ],
              if (participantContext != 'healthy_volunteer') ...[
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: affectedSide,
                  decoration: const InputDecoration(labelText: 'Lado afetado'),
                  items: const [
                    DropdownMenuItem(value: 'left', child: Text('Esquerdo')),
                    DropdownMenuItem(value: 'right', child: Text('Direito')),
                    DropdownMenuItem(value: 'bilateral', child: Text('Ambos')),
                    DropdownMenuItem(
                      value: 'not_informed',
                      child: Text('Não informado'),
                    ),
                  ],
                  onChanged: saving
                      ? null
                      : (value) => setState(
                          () => affectedSide = value ?? affectedSide,
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: strokeType,
                  decoration: const InputDecoration(labelText: 'Tipo do AVC'),
                  items: const [
                    DropdownMenuItem(
                      value: 'ischemic',
                      child: Text('Isquêmico'),
                    ),
                    DropdownMenuItem(
                      value: 'hemorrhagic',
                      child: Text('Hemorrágico'),
                    ),
                    DropdownMenuItem(
                      value: 'not_informed',
                      child: Text('Não informado'),
                    ),
                  ],
                  onChanged: saving
                      ? null
                      : (value) =>
                            setState(() => strokeType = value ?? strokeType),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: mobility,
                decoration: const InputDecoration(labelText: 'Mobilidade'),
                items: const [
                  DropdownMenuItem(
                    value: 'independent',
                    child: Text('Independente'),
                  ),
                  DropdownMenuItem(
                    value: 'with_support',
                    child: Text('Com apoio'),
                  ),
                  DropdownMenuItem(
                    value: 'wheelchair',
                    child: Text('Cadeira de rodas'),
                  ),
                  DropdownMenuItem(
                    value: 'not_informed',
                    child: Text('Não informado'),
                  ),
                ],
                onChanged: saving
                    ? null
                    : (value) => setState(() => mobility = value ?? mobility),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: ageRange,
                decoration: const InputDecoration(labelText: 'Faixa etária'),
                items: const [
                  DropdownMenuItem(
                    value: 'not_informed',
                    child: Text('Não informado'),
                  ),
                  DropdownMenuItem(
                    value: 'under_40',
                    child: Text('Até 39 anos'),
                  ),
                  DropdownMenuItem(value: '40_49', child: Text('40 a 49 anos')),
                  DropdownMenuItem(value: '50_59', child: Text('50 a 59 anos')),
                  DropdownMenuItem(value: '60_69', child: Text('60 a 69 anos')),
                  DropdownMenuItem(value: '70_79', child: Text('70 a 79 anos')),
                  DropdownMenuItem(
                    value: '80_plus',
                    child: Text('80 anos ou mais'),
                  ),
                ],
                onChanged: saving
                    ? null
                    : (value) => setState(() => ageRange = value ?? ageRange),
              ),
              if (participantContext != 'healthy_volunteer') ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('editar_meses_desde_avc'),
                  controller: monthsSinceStrokeController,
                  enabled: !saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Meses desde o AVC',
                    hintText: 'Opcional',
                  ),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) return null;
                    final months = int.tryParse(value!.trim());
                    return months == null || months < 0 || months > 600
                        ? 'Informe um valor entre 0 e 600.'
                        : null;
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: dominantSide,
                decoration: InputDecoration(
                  labelText: participantContext == 'healthy_volunteer'
                      ? 'Lado dominante'
                      : 'Lado dominante antes do AVC',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'not_informed',
                    child: Text('Não informado'),
                  ),
                  DropdownMenuItem(value: 'left', child: Text('Esquerdo')),
                  DropdownMenuItem(value: 'right', child: Text('Direito')),
                  DropdownMenuItem(
                    value: 'ambidextrous',
                    child: Text('Ambidestro'),
                  ),
                ],
                onChanged: saving
                    ? null
                    : (value) =>
                          setState(() => dominantSide = value ?? dominantSide),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: assistiveDevice,
                decoration: const InputDecoration(
                  labelText: 'Apoio ou dispositivo auxiliar',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'not_informed',
                    child: Text('Não informado'),
                  ),
                  DropdownMenuItem(value: 'none', child: Text('Nenhum')),
                  DropdownMenuItem(value: 'cane', child: Text('Bengala')),
                  DropdownMenuItem(value: 'walker', child: Text('Andador')),
                  DropdownMenuItem(
                    value: 'wheelchair',
                    child: Text('Cadeira de rodas'),
                  ),
                  DropdownMenuItem(value: 'other', child: Text('Outro')),
                ],
                onChanged: saving
                    ? null
                    : (value) => setState(
                        () => assistiveDevice = value ?? assistiveDevice,
                      ),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                error!,
                key: const Key('erro_editar_perfil'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        key: const Key('salvar_perfil'),
        onPressed: saving ? null : save,
        icon: saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        label: Text(saving ? 'Salvando…' : 'Salvar'),
      ),
    ],
  );
}
