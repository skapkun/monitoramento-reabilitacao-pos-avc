import 'package:flutter/material.dart';

class Exercise {
  const Exercise({
    required this.type,
    required this.name,
    required this.description,
    required this.instructions,
    required this.icon,
    this.available = false,
  });

  final String type;
  final String name;
  final String description;
  final List<String> instructions;
  final IconData icon;
  final bool available;
}

abstract final class MockExercises {
  static const elbowFlexion = Exercise(
    type: 'elbow_flexion',
    name: 'Flexão de cotovelo',
    description: 'Movimento do braço com orientação passo a passo.',
    instructions: [
      'Sente-se ou fique em pé em uma posição confortável.',
      'Mantenha o braço visível para a câmera.',
      'Dobre e estenda o cotovelo devagar.',
      'Interrompa o exercício se sentir desconforto.',
    ],
    icon: Icons.accessibility_new,
    available: true,
  );

  static const squat = Exercise(
    type: 'squat',
    name: 'Agachamento',
    description: 'Movimento de membros inferiores.',
    instructions: [
      'Posicione a câmera a aproximadamente 1,5 m, em ângulo oblíquo de 45°.',
      'Mantenha ombros, quadris, joelhos e tornozelos visíveis.',
      'Desça e retorne lentamente, respeitando seus limites.',
      'Interrompa se sentir dor, tontura ou desconforto.',
    ],
    icon: Icons.airline_seat_legroom_reduced,
    available: true,
  );

  static const pinch = Exercise(
    type: 'pinch',
    name: 'Pinça',
    description: 'Movimento de aproximação dos dedos.',
    instructions: [
      'Posicione a câmera a aproximadamente 40 cm da mão.',
      'Mantenha polegar e indicador inteiros e bem iluminados.',
      'Aproxime e afaste as pontas dos dedos lentamente.',
      'Interrompa se sentir dor ou desconforto.',
    ],
    icon: Icons.pan_tool_alt_outlined,
    available: true,
  );

  static const all = [elbowFlexion, squat, pinch];
}
