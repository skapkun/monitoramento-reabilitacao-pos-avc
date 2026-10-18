import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/auth_repository.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';
import '../../widgets/form_field_group.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({AuthRepository? authRepository, super.key})
    : authRepository = authRepository ?? const DemoAuthRepository();

  final AuthRepository authRepository;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final registrationController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmationController = TextEditingController();
  final monthsSinceStrokeController = TextEditingController();
  UserRole role = UserRole.patient;
  String affectedSide = 'right';
  String strokeType = 'not_informed';
  String mobility = 'independent';
  String ageRange = 'not_informed';
  String dominantSide = 'not_informed';
  String assistiveDevice = 'not_informed';
  bool accepted = false;
  bool submitting = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    registrationController.dispose();
    passwordController.dispose();
    confirmationController.dispose();
    monthsSinceStrokeController.dispose();
    super.dispose();
  }

  String? requiredField(String? value, String message) =>
      (value?.trim().isEmpty ?? true) ? message : null;

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Confirme que leu as informações do protótipo.'),
        ),
      );
      return;
    }
    setState(() => submitting = true);
    try {
      await widget.authRepository.register(
        name: nameController.text,
        email: emailController.text,
        password: passwordController.text,
        role: role,
        phone: phoneController.text,
        professionalRegistration: registrationController.text,
        affectedSide: affectedSide,
        strokeType: strokeType,
        mobility: mobility,
        ageRange: ageRange,
        monthsSinceStroke: int.tryParse(monthsSinceStrokeController.text),
        dominantSide: dominantSide,
        assistiveDevice: assistiveDevice,
      );
      await widget.authRepository.signOut();
      if (!mounted) return;
      setState(() => submitting = false);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            widget.authRepository.isDemo
                ? 'Cadastro simulado concluído'
                : 'Cadastro concluído',
          ),
          content: Text(
            widget.authRepository.isDemo
                ? 'Nenhuma conta real foi criada. Na integração futura, estes dados serão enviados ao serviço de autenticação.'
                : 'Sua conta foi criada. Volte ao login para entrar no Movere.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('Voltar ao login'),
            ),
          ],
        ),
      );
    } on AuthRepositoryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Criar conta',
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dados de acesso',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.authRepository.isDemo
                  ? 'Preencha os campos para demonstrar o cadastro.'
                  : 'Preencha os campos para criar sua conta.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            FormFieldGroup(
              label: 'Tipo de perfil',
              child: DropdownButtonFormField<UserRole>(
                isExpanded: true,
                initialValue: role,
                items: UserRole.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => role = value ?? role),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FormFieldGroup(
              label: 'Nome completo',
              child: TextFormField(
                key: const Key('cadastro_nome'),
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    requiredField(value, 'Informe seu nome completo.'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FormFieldGroup(
              label: 'E-mail',
              child: TextFormField(
                key: const Key('cadastro_email'),
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Informe seu e-mail.';
                  }
                  if (!value!.contains('@') || !value.contains('.')) {
                    return 'Informe um e-mail válido.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FormFieldGroup(
              label: 'Telefone (opcional)',
              child: TextFormField(
                key: const Key('cadastro_telefone'),
                controller: phoneController,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: (value) => (value?.trim().length ?? 0) > 30
                    ? 'O telefone deve ter no máximo 30 caracteres.'
                    : null,
              ),
            ),
            if (role == UserRole.therapist) ...[
              const SizedBox(height: AppSpacing.md),
              FormFieldGroup(
                label: 'Registro profissional',
                helpText: 'Informe o número e a região do CREFITO.',
                child: TextFormField(
                  key: const Key('cadastro_registro_profissional'),
                  controller: registrationController,
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) =>
                      requiredField(value, 'Informe o registro profissional.'),
                ),
              ),
            ],
            if (role == UserRole.patient) ...[
              const SizedBox(height: AppSpacing.md),
              FormFieldGroup(
                label: 'Lado afetado',
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: affectedSide,
                  items: const [
                    DropdownMenuItem(value: 'left', child: Text('Esquerdo')),
                    DropdownMenuItem(value: 'right', child: Text('Direito')),
                    DropdownMenuItem(value: 'bilateral', child: Text('Ambos')),
                    DropdownMenuItem(
                      value: 'not_informed',
                      child: Text('Prefiro não informar'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => affectedSide = value ?? affectedSide),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FormFieldGroup(
                label: 'Tipo do AVC',
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: strokeType,
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
                  onChanged: (value) =>
                      setState(() => strokeType = value ?? strokeType),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FormFieldGroup(
                label: 'Mobilidade atual',
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: mobility,
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
                  onChanged: (value) =>
                      setState(() => mobility = value ?? mobility),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FormFieldGroup(
                label: 'Faixa etária (opcional)',
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: ageRange,
                  items: const [
                    DropdownMenuItem(
                      value: 'not_informed',
                      child: Text('Prefiro não informar'),
                    ),
                    DropdownMenuItem(
                      value: 'under_40',
                      child: Text('Até 39 anos'),
                    ),
                    DropdownMenuItem(
                      value: '40_49',
                      child: Text('40 a 49 anos'),
                    ),
                    DropdownMenuItem(
                      value: '50_59',
                      child: Text('50 a 59 anos'),
                    ),
                    DropdownMenuItem(
                      value: '60_69',
                      child: Text('60 a 69 anos'),
                    ),
                    DropdownMenuItem(
                      value: '70_79',
                      child: Text('70 a 79 anos'),
                    ),
                    DropdownMenuItem(
                      value: '80_plus',
                      child: Text('80 anos ou mais'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => ageRange = value ?? ageRange),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FormFieldGroup(
                label: 'Tempo desde o AVC (opcional)',
                helpText: 'Informe a quantidade aproximada de meses.',
                child: TextFormField(
                  key: const Key('cadastro_meses_desde_avc'),
                  controller: monthsSinceStrokeController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) return null;
                    final months = int.tryParse(value!.trim());
                    if (months == null || months < 0 || months > 600) {
                      return 'Informe um valor entre 0 e 600 meses.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FormFieldGroup(
                label: 'Lado dominante antes do AVC (opcional)',
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: dominantSide,
                  items: const [
                    DropdownMenuItem(
                      value: 'not_informed',
                      child: Text('Prefiro não informar'),
                    ),
                    DropdownMenuItem(value: 'left', child: Text('Esquerdo')),
                    DropdownMenuItem(value: 'right', child: Text('Direito')),
                    DropdownMenuItem(
                      value: 'ambidextrous',
                      child: Text('Ambidestro'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => dominantSide = value ?? dominantSide),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FormFieldGroup(
                label: 'Apoio ou dispositivo auxiliar (opcional)',
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: assistiveDevice,
                  items: const [
                    DropdownMenuItem(
                      value: 'not_informed',
                      child: Text('Prefiro não informar'),
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
                  onChanged: (value) => setState(
                    () => assistiveDevice = value ?? assistiveDevice,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            FormFieldGroup(
              label: 'Senha',
              helpText: 'Use pelo menos 6 caracteres nesta demonstração.',
              child: TextFormField(
                key: const Key('cadastro_senha'),
                controller: passwordController,
                obscureText: true,
                validator: (value) => (value?.length ?? 0) < 6
                    ? 'A senha deve ter pelo menos 6 caracteres.'
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FormFieldGroup(
              label: 'Confirmar senha',
              child: TextFormField(
                key: const Key('cadastro_confirmacao'),
                controller: confirmationController,
                obscureText: true,
                validator: (value) => value != passwordController.text
                    ? 'As senhas não coincidem.'
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              value: accepted,
              onChanged: (value) => setState(() => accepted = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Li e compreendi que este é um protótipo acadêmico e não substitui avaliação profissional.',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              key: const Key('concluir_cadastro'),
              onPressed: submitting ? null : submit,
              child: submitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : Text(
                      widget.authRepository.isDemo
                          ? 'Concluir cadastro simulado'
                          : 'Criar conta',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
