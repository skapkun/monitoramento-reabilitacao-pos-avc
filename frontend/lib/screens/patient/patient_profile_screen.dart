import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_profile.dart';
import '../../services/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_page.dart';
import '../../widgets/editable_profile_photo.dart';
import '../../widgets/status_banner.dart';
import '../../widgets/profile_edit_dialog.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({
    AuthRepository? authRepository,
    this.photoPicker,
    super.key,
  }) : authRepository = authRepository ?? const DemoAuthRepository();

  final AuthRepository authRepository;
  final Future<Uint8List?> Function()? photoPicker;

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  bool largerText = true;
  bool reducedMotion = false;
  bool repeatInstructions = true;
  bool savingPreferences = false;
  bool savingPhoto = false;
  late Future<UserProfile?> profile;

  @override
  void initState() {
    super.initState();
    profile = _loadProfile();
  }

  Future<UserProfile?> _loadProfile() async {
    final loaded = widget.authRepository.isDemo
        ? MockUsers.patient
        : await widget.authRepository.currentProfile();
    if (loaded != null) {
      largerText = loaded.accessibilityPreferences.largerText;
      reducedMotion = loaded.accessibilityPreferences.reducedMotion;
      repeatInstructions = loaded.accessibilityPreferences.repeatInstructions;
    }
    return loaded;
  }

  Future<void> _savePreferences() async {
    setState(() => savingPreferences = true);
    try {
      await widget.authRepository.updateAccessibilityPreferences(
        AccessibilityPreferences(
          largerText: largerText,
          reducedMotion: reducedMotion,
          repeatInstructions: repeatInstructions,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preferências salvas.')));
    } on AuthRepositoryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => savingPreferences = false);
    }
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
      title: 'Meu perfil',
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
      Row(
        children: [
          EditableProfilePhoto(
            radius: 36,
            initials: _initials(user.name),
            photoBytes: user.photoBytes,
            enabled: !widget.authRepository.isDemo,
            saving: savingPhoto,
            onEdit: _changePhoto,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  user.role.label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      if (user.participantContext == 'healthy_volunteer') ...[
        const StatusBanner(
          icon: Icons.science_outlined,
          title: 'Voluntário saudável — teste técnico',
          message:
              'Este perfil é usado para verificar funcionamento e usabilidade. Os resultados não demonstram validade clínica pós-AVC.',
          backgroundColor: AppColors.warningBackground,
          foregroundColor: AppColors.warningText,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      _InformationGroup(
        items: [
          _InformationItem(
            'Contexto do perfil',
            _participantContextLabel(user.participantContext),
            Icons.science_outlined,
          ),
          _InformationItem('E-mail', user.email, Icons.email_outlined),
          _InformationItem(
            'Telefone',
            user.phone ?? 'Não informado',
            Icons.phone_outlined,
          ),
          if (user.participantContext != 'healthy_volunteer') ...[
            _InformationItem(
              'Lado afetado',
              _affectedSideLabel(user.affectedSide),
              Icons.accessibility_new,
            ),
            _InformationItem(
              'Tipo do AVC',
              _strokeTypeLabel(user.strokeType),
              Icons.medical_information_outlined,
            ),
          ],
          _InformationItem(
            'Mobilidade',
            _mobilityLabel(user.mobility),
            Icons.directions_walk,
          ),
          _InformationItem(
            'Faixa etária',
            _ageRangeLabel(user.ageRange),
            Icons.cake_outlined,
          ),
          if (user.participantContext != 'healthy_volunteer')
            _InformationItem(
              'Tempo desde o AVC',
              user.monthsSinceStroke == null
                  ? 'Não informado'
                  : '${user.monthsSinceStroke} meses',
              Icons.calendar_month_outlined,
            ),
          _InformationItem(
            user.participantContext == 'healthy_volunteer'
                ? 'Lado dominante'
                : 'Lado dominante antes do AVC',
            _dominantSideLabel(user.dominantSide),
            Icons.back_hand_outlined,
          ),
          _InformationItem(
            'Apoio ou dispositivo auxiliar',
            _assistiveDeviceLabel(user.assistiveDevice),
            Icons.accessible_forward,
          ),
        ],
      ),
      if (!widget.authRepository.isDemo) ...[
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          key: const Key('editar_perfil'),
          onPressed: () => _editProfile(user),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar dados pessoais'),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      Text(
        'Preferências de acessibilidade',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: AppSpacing.sm),
      SwitchListTile(
        value: largerText,
        onChanged: (value) => setState(() => largerText = value),
        title: const Text('Texto ampliado'),
        subtitle: const Text('Preferir textos maiores nas telas.'),
        contentPadding: EdgeInsets.zero,
      ),
      SwitchListTile(
        value: repeatInstructions,
        onChanged: (value) => setState(() => repeatInstructions = value),
        title: const Text('Repetir instruções'),
        subtitle: const Text(
          'Mostrar novamente as orientações antes do exercício.',
        ),
        contentPadding: EdgeInsets.zero,
      ),
      SwitchListTile(
        value: reducedMotion,
        onChanged: (value) => setState(() => reducedMotion = value),
        title: const Text('Reduzir animações'),
        subtitle: const Text(
          'Diminuir movimentos não essenciais na interface.',
        ),
        contentPadding: EdgeInsets.zero,
      ),
      if (!widget.authRepository.isDemo) ...[
        const SizedBox(height: AppSpacing.md),
        ElevatedButton.icon(
          key: const Key('salvar_preferencias'),
          onPressed: savingPreferences ? null : _savePreferences,
          icon: savingPreferences
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : const Icon(Icons.save_outlined),
          label: Text(savingPreferences ? 'Salvando…' : 'Salvar preferências'),
        ),
      ],
      if (!widget.authRepository.isDemo && user.id != null) ...[
        const SizedBox(height: AppSpacing.lg),
        _InformationCard(
          label: 'Código para vínculo profissional',
          value: user.id!,
          icon: Icons.link,
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Compartilhe este código somente com o fisioterapeuta que acompanha você. O vínculo ainda precisará da sua confirmação.',
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      StatusBanner(
        icon: Icons.info_outline,
        title: widget.authRepository.isDemo
            ? 'Dados simulados'
            : 'Preferências sincronizadas',
        message: widget.authRepository.isDemo
            ? 'As alterações permanecem apenas nesta demonstração e não são armazenadas.'
            : 'Seus dados e preferências de acessibilidade são carregados do Firebase.',
        backgroundColor: AppColors.primarySoft,
        foregroundColor: AppColors.primarySoftText,
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

  String _participantContextLabel(String value) => switch (value) {
    'post_stroke' => 'Acompanhamento pós-AVC',
    'healthy_volunteer' => 'Voluntário saudável — teste técnico',
    _ => 'Não informado',
  };

  String _affectedSideLabel(String? value) => switch (value) {
    'left' => 'Esquerdo',
    'right' => 'Direito',
    'bilateral' => 'Ambos',
    _ => 'Não informado',
  };

  String _strokeTypeLabel(String? value) => switch (value) {
    'ischemic' => 'Isquêmico',
    'hemorrhagic' => 'Hemorrágico',
    _ => 'Não informado',
  };

  String _mobilityLabel(String? value) => switch (value) {
    'independent' => 'Independente',
    'with_support' => 'Com apoio',
    'wheelchair' => 'Cadeira de rodas',
    _ => 'Não informado',
  };

  String _ageRangeLabel(String? value) => switch (value) {
    'under_40' => 'Até 39 anos',
    '40_49' => '40 a 49 anos',
    '50_59' => '50 a 59 anos',
    '60_69' => '60 a 69 anos',
    '70_79' => '70 a 79 anos',
    '80_plus' => '80 anos ou mais',
    _ => 'Não informado',
  };

  String _dominantSideLabel(String? value) => switch (value) {
    'left' => 'Esquerdo',
    'right' => 'Direito',
    'ambidextrous' => 'Ambidestro',
    _ => 'Não informado',
  };

  String _assistiveDeviceLabel(String? value) => switch (value) {
    'none' => 'Nenhum',
    'cane' => 'Bengala',
    'walker' => 'Andador',
    'wheelchair' => 'Cadeira de rodas',
    'other' => 'Outro',
    _ => 'Não informado',
  };
}

class _InformationItem {
  const _InformationItem(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _InformationGroup extends StatelessWidget {
  const _InformationGroup({required this.items});

  final List<_InformationItem> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final columns = constraints.maxWidth >= 340 && textScale <= 1.4 ? 2 : 1;
      final width = columns == 2
          ? (constraints.maxWidth - AppSpacing.sm) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: items
            .map(
              (item) => SizedBox(
                width: width,
                child: _InformationTile(item: item),
              ),
            )
            .toList(),
      );
    },
  );
}

class _InformationTile extends StatelessWidget {
  const _InformationTile({required this.item});

  final _InformationItem item;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(item.icon, color: AppColors.primary, size: 22),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                item.value,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      minVerticalPadding: AppSpacing.md,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
    ),
  );
}
