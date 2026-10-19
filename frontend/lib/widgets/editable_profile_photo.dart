import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class EditableProfilePhoto extends StatelessWidget {
  const EditableProfilePhoto({
    required this.initials,
    required this.photoBytes,
    required this.enabled,
    required this.saving,
    required this.onEdit,
    this.radius = 40,
    super.key,
  });

  final String initials;
  final Uint8List? photoBytes;
  final bool enabled;
  final bool saving;
  final VoidCallback onEdit;
  final double radius;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        backgroundImage: photoBytes == null ? null : MemoryImage(photoBytes!),
        child: photoBytes == null
            ? Text(
                initials,
                style: TextStyle(
                  fontSize: radius * 0.62,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      if (enabled)
        Positioned(
          right: -8,
          bottom: -8,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(
              side: BorderSide(color: Colors.white, width: 2),
            ),
            child: IconButton(
              key: const Key('alterar_foto_perfil'),
              tooltip: 'Alterar foto de perfil',
              onPressed: saving ? null : onEdit,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.photo_camera_outlined,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
    ],
  );
}
