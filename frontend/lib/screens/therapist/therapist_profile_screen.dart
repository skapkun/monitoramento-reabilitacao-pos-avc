import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_profile.dart';
import '../../services/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';
import '../../widgets/editable_profile_photo.dart';
import '../../widgets/profile_edit_dialog.dart';
import '../../widgets/status_banner.dart';

class TherapistProfileScreen extends StatefulWidget {
  const TherapistProfileScreen({
    AuthRepository? authRepository,
    this.photoPicker,
    super.key,
  }) : authRepository = authRepository ?? const DemoAuthRepository();

  final AuthRepository authRepository;
  final Future<Uint8List?> Function()? photoPicker;

  @override
  State<TherapistProfileScreen> createState() => _TherapistProfileScreenState();
}

class _TherapistProfileScreenState extends State<TherapistProfileScreen> {
  late Future<UserProfile?> profile;
  bool savingPhoto = false;

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

  Future<void> _changePhoto() async {
    final picker = widget.photoPicker ?? _pickPhoto;
    final bytes = await picker();
    if (bytes == null || !mounted) return;
    setState(() => savingPhoto = true);
    try {
      final updated = await widget.authRepository.updateProfilePhoto(bytes);
      if (!mounted) return;
      setState(() {
        profile = Future.value(updated);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil atualizada.')),
      );
    } on AuthRepositoryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => savingPhoto = false);
    }
  }

  Future<Uint8List?> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 60,
    );
    return file?.readAsBytes();
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
      Align(
        child: EditableProfilePhoto(
          radius: 44,
          initials: _initials(user.name),
          photoBytes: user.photoBytes,
          enabled: !widget.authRepository.isDemo,
          saving: savingPhoto,
          onEdit: _changePhoto,
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
