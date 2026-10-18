import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../services/auth_repository.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';
import '../../widgets/form_field_group.dart';
import '../../widgets/status_banner.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({AuthRepository? authRepository, super.key})
    : authRepository = authRepository ?? const DemoAuthRepository();

  final AuthRepository authRepository;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  bool sent = false;
  bool submitting = false;

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => submitting = true);
    try {
      await widget.authRepository.sendPasswordReset(emailController.text);
      if (mounted) setState(() => sent = true);
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
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Recuperar senha',
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sent)
              StatusBanner(
                icon: Icons.check_circle_outline,
                title: widget.authRepository.isDemo
                    ? 'Orientação simulada enviada'
                    : 'E-mail enviado',
                message: widget.authRepository.isDemo
                    ? 'Em uma integração real, as instruções seriam enviadas ao e-mail informado.'
                    : 'Se existir uma conta para esse endereço, você receberá as instruções de recuperação.',
                backgroundColor: AppColors.primarySoft,
                foregroundColor: AppColors.primarySoftText,
              )
            else ...[
              Text(
                'Informe seu e-mail',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Você receberá orientações para criar uma nova senha.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              FormFieldGroup(
                label: 'E-mail',
                child: TextFormField(
                  key: const Key('recuperacao_email'),
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) {
                      return 'Informe seu e-mail.';
                    }
                    if (!email.contains('@') || !email.contains('.')) {
                      return 'Informe um e-mail válido.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                key: const Key('enviar_recuperacao'),
                onPressed: submitting ? null : submit,
                child: Text(submitting ? 'Enviando…' : 'Enviar orientações'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
