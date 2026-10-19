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
    description: 'Movimento de sentar e levantar.',
    instructions: [
      'Coloque a câmera um pouco de lado, mostrando a frente e a lateral do corpo.',
      'Deixe ombros, quadris, joelhos e pés aparecerem na tela.',
      'Desça e levante devagar. Não force o movimento.',
      'Interrompa se sentir dor, tontura ou desconforto.',
    ],
    icon: Icons.airline_seat_legroom_reduced,
    available: true,
  );

  static const pinch = Exercise(
    type: 'pinch',
    name: 'Pinça',
    description: 'Movimento de juntar e afastar os dedos.',
    instructions: [
      'Coloque a câmera perto da mão, a cerca de um palmo de distância.',
      'Deixe o polegar e o indicador inteiros e bem iluminados.',
      'Junte e afaste as pontas dos dedos devagar.',
      'Interrompa se sentir dor ou desconforto.',
    ],
    icon: Icons.pan_tool_alt_outlined,
    available: true,
  );

  static const all = [elbowFlexion, squat, pinch];
}
