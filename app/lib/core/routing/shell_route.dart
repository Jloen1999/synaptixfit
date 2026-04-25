import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/bottom_nav_bar.dart';

class SynaptixShellRoute extends StatelessWidget {
  const SynaptixShellRoute(
      {required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  static const List<String> _tabs = [
    '/dashboard',
    '/academico',
    '/perfil',
    '/retos',
    '/social',
  ];

  int get _selectedIndex {
    final index = _tabs.indexWhere((tab) => location.startsWith(tab));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => context.go(_tabs[index]),
      ),
    );
  }
}
