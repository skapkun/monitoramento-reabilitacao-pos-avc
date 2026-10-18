import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/form_field_group.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({AuthRepository? authRepository, super.key})
    : authRepository = authRepository ?? const DemoAuthRepository();

  final AuthRepository authRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  UserRole role = UserRole.patient;
  bool hidePassword = true;
  bool submitting = false;
  bool restoringSession = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (!widget.authRepository.isDemo) _restoreSession();
  }

  Future<void> _restoreSession() async {
    setState(() => restoringSession = true);
    try {
      final profile = await widget.authRepository.currentProfile();
      if (!mounted || profile == null) return;
      final route = profile.role == UserRole.patient
          ? AppRoutes.patientHome
          : AppRoutes.therapistHome;
      Navigator.pushReplacementNamed(context, route);
    } on AuthRepositoryException catch (error) {
      if (mounted) setState(() => errorMessage = error.message);
    } finally {
      if (mounted) setState(() => restoringSession = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Informe seu e-mail.';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Informe sua senha.';
    }
    if (value!.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    return null;
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() {
      submitting = true;
      errorMessage = null;
    });
    try {
      final profile = await widget.authRepository.signIn(
        email: emailController.text,
        password: passwordController.text,
      );
      if (profile.role != role && !widget.authRepository.isDemo) {
        await widget.authRepository.signOut();
        throw AuthRepositoryException(
          'Esta conta está cadastrada como ${profile.role.label.toLowerCase()}.',
        );
      }
      if (!mounted) return;
      final route = profile.role == UserRole.patient
          ? AppRoutes.patientHome
          : AppRoutes.therapistHome;
      Navigator.pushReplacementNamed(context, route);
    } on AuthRepositoryException catch (error) {
      if (mounted) setState(() => errorMessage = error.message);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  void enterDemo(UserRole selectedRole) {
    final route = selectedRole == UserRole.patient
        ? AppRoutes.patientHome
        : AppRoutes.therapistHome;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    if (restoringSession) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Semantics(
              label: 'Restaurando sessão',
              child: const CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/branding/movere_mark.png',
                      height: 112,
                      fit: BoxFit.contain,
                      semanticLabel: 'Logotipo do Movere',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Movere',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Entre para acompanhar sua reabilitação',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (errorMessage != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          errorMessage!,
                          key: const Key('erro_login'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.errorText),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    FormFieldGroup(
                      label: 'Perfil de acesso',
                      child: SegmentedButton<UserRole>(
                        segments: UserRole.values
                            .map(
                              (item) => ButtonSegment(
                                value: item,
                                label: Text(item.label),
                                icon: Icon(
                                  item == UserRole.patient
                                      ? Icons.person
                                      : Icons.medical_services_outlined,
                                ),
                              ),
                            )
                            .toList(),
                        selected: {role},
                        onSelectionChanged: (selection) =>
                            setState(() => role = selection.first),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FormFieldGroup(
                      label: 'E-mail',
                      child: TextFormField(
                        key: const Key('campo_email'),
                        controller: emailController,
                        validator: validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          hintText: 'nome@exemplo.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FormFieldGroup(
                      label: 'Senha',
                      child: TextFormField(
                        key: const Key('campo_senha'),
                        controller: passwordController,
                        validator: validatePassword,
                        obscureText: hidePassword,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: hidePassword
                                ? 'Mostrar senha'
                                : 'Ocultar senha',
                            onPressed: () =>
                                setState(() => hidePassword = !hidePassword),
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.forgotPassword,
                        ),
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton(
                      key: const Key('entrar'),
                      onPressed: submitting ? null : submit,
                      child: submitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.register),
                      child: const Text('Criar uma conta'),
                    ),
                    if (widget.authRepository.isDemo) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Acesso rápido à demonstração',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        key: const Key('entrar_paciente'),
                        onPressed: submitting
                            ? null
                            : () => enterDemo(UserRole.patient),
                        icon: const Icon(Icons.person),
                        label: const Text('Demonstração do paciente'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        key: const Key('entrar_fisioterapeuta'),
                        onPressed: submitting
                            ? null
                            : () => enterDemo(UserRole.therapist),
                        icon: const Icon(Icons.medical_services_outlined),
                        label: const Text('Demonstração do fisioterapeuta'),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      widget.authRepository.isDemo
                          ? 'Autenticação simulada. Nenhum dado é enviado ou armazenado.'
                          : 'O acesso usa Firebase Authentication. Seus dados de perfil são protegidos por regras do Firestore.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
