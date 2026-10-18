import 'package:flutter/material.dart';

enum AppNavigationRole { patient, therapist }

class RoleNavigationBar extends StatelessWidget {
  const RoleNavigationBar({required this.role, super.key});

  final AppNavigationRole role;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name ?? '';
    final items = role == AppNavigationRole.patient
        ? const [
            _NavigationItem('/', 'Início', Icons.home_outlined),
            _NavigationItem(
              '/paciente/plano',
              'Rotina',
              Icons.assignment_outlined,
            ),
            _NavigationItem('/paciente/historico', 'Sessões', Icons.history),
            _NavigationItem(
              '/paciente/mensagens',
              'Mensagens',
              Icons.chat_bubble_outline,
            ),
            _NavigationItem('/paciente/perfil', 'Perfil', Icons.person_outline),
          ]
        : const [
            _NavigationItem('/', 'Início', Icons.home_outlined),
            _NavigationItem(
              '/fisioterapeuta/pacientes',
              'Pacientes',
              Icons.groups_outlined,
            ),
            _NavigationItem(
              '/fisioterapeuta/perfil',
              'Perfil',
              Icons.person_outline,
            ),
          ];
    final index = _selectedIndex(route, items);
    return NavigationBar(
      selectedIndex: index,
      destinations: items
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(_selectedIcon(item.icon)),
              label: item.label,
            ),
          )
          .toList(),
      onDestinationSelected: (selected) {
        if (selected == index) return;
        final destination = items[selected].route;
        final resolved = destination == '/'
            ? role == AppNavigationRole.patient
                  ? '/paciente'
                  : '/fisioterapeuta'
            : destination;
        Navigator.pushNamedAndRemoveUntil(context, resolved, (_) => false);
      },
    );
  }

  int _selectedIndex(String route, List<_NavigationItem> items) {
    if (role == AppNavigationRole.patient) {
      if (route.contains('plano') ||
          route.contains('exercicio') ||
          route.contains('preparacao') ||
          route.contains('gravacao') ||
          route.contains('processamento') ||
          route.contains('resultado')) {
        return 1;
      }
      if (route.contains('historico') || route.contains('evolucao')) return 2;
      if (route.contains('mensagens')) return 3;
      if (route.contains('perfil') || route.contains('orientacoes')) return 4;
      return 0;
    }
    if (route.contains('paciente') ||
        route.contains('sessoes') ||
        route.contains('plano') ||
        route.contains('relatorios') ||
        route.contains('observacoes') ||
        route.contains('evolucao')) {
      return 1;
    }
    if (route.contains('perfil')) return 2;
    return 0;
  }

  static IconData _selectedIcon(IconData icon) => switch (icon) {
    Icons.home_outlined => Icons.home,
    Icons.assignment_outlined => Icons.assignment,
    Icons.groups_outlined => Icons.groups,
    Icons.chat_bubble_outline => Icons.chat_bubble,
    Icons.person_outline => Icons.person,
    _ => icon,
  };
}

class _NavigationItem {
  const _NavigationItem(this.route, this.label, this.icon);

  final String route;
  final String label;
  final IconData icon;
}
