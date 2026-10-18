import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';
import '../../widgets/profile_edit_dialog.dart';
import '../../widgets/status_banner.dart';

class TherapistProfileScreen extends StatefulWidget {
  const TherapistProfileScreen({AuthRepository? authRepository, super.key})
    : authRepository = authRepository ?? const DemoAuthRepository();

  final AuthRepository authRepository;

  @override
  State<TherapistProfileScreen> createState() => _TherapistProfileScreenState();
}

class _TherapistProfileScreenState extends State<TherapistProfileScreen> {
  late Future<UserProfile?> profile;

  @override
  void initState() {
    super.initState();
    profile = widget.authRepository.isDemo
        ? Future.value(MockUsers.therapist)
        : widget.authRepository.currentProfile();
  }

  Future<void> _editProfile(UserProfile current) async {
    final updated = await showProfileEditDialog(
      context,
      profile: current,
      repository: widget.authRepository,
    );
    if (updated == null || !mounted) return;
    setState(() {
      profile = Future.value(updated);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perfil atualizado.')));
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Perfil profissional',
      child: FutureBuilder<UserProfile?>(
        future: profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const StatusBanner(
              icon: Icons.error_outline,
              title: 'Perfil indisponível',
              message: 'Não foi possível carregar os dados desta conta.',
              backgroundColor: AppColors.errorBackground,
              foregroundColor: AppColors.errorText,
            );
          }
          return _content(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _content(BuildContext context, UserProfile user) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CircleAvatar(
        radius: 44,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: Text(
          _initials(user.name),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        user.name,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      Text(
        user.role.label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: AppSpacing.lg),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dados profissionais',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'E-mail: ${user.email}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Telefone: ${user.phone ?? 'Não informado'}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Registro profissional: ${user.professionalRegistration ?? 'Não informado'}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
      if (!widget.authRepository.isDemo) ...[
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          key: const Key('editar_perfil'),
          onPressed: () => _editProfile(user),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar dados profissionais'),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      StatusBanner(
        icon: Icons.science_outlined,
        title: widget.authRepository.isDemo
            ? 'Perfil simulado'
            : 'Perfil autenticado',
        message: widget.authRepository.isDemo
            ? 'As informações permanecem apenas nesta demonstração.'
            : 'Nome, telefone e registro profissional são sincronizados com o Firebase.',
        backgroundColor: AppColors.warningBackground,
        foregroundColor: AppColors.warningText,
      ),
    ],
  );

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    return [
      parts.first,
      if (parts.length > 1) parts.last,
    ].map((part) => part[0].toUpperCase()).join();
  }
}
