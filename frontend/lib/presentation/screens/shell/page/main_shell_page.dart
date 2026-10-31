import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/enums/usage_focus.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import '../../auth/session/bloc/session_bloc.dart';
import '../widgets/achievements_host.dart';

/// Estructura principal con las pestañas de [StatefulNavigationShell]:
/// barra inferior en móvil y riel lateral en pantallas anchas. Según el
/// enfoque de uso se ocultan Académico (solo deporte) o Rutinas (solo
/// estudios); las ramas del router no cambian, así que se traduce entre la
/// posición visible y el índice de rama. Los logros
/// ([AchievementsHost]) se celebran aquí para que se vean desde cualquier
/// pestaña.
class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key, required this.shell});

  final StatefulNavigationShell shell;

  /// Índices de rama, en orden: inicio, académico, rutinas, retos, progreso.
  static const _academicBranch = 1;
  static const _trainingBranch = 2;

  void _select(int branch) =>
      shell.goBranch(branch, initialLocation: branch == shell.currentIndex);

  static List<int> _visibleBranches(UsageFocus focus) => [
    0,
    if (focus.includesAcademic) _academicBranch,
    if (focus.includesFitness) _trainingBranch,
    3,
    4,
  ];

  List<({IconData icon, IconData selected, String label})> _destinations(
    BuildContext context,
  ) {
    final l10n = context.localizations;
    return [
      (
        icon: Icons.home_outlined,
        selected: Icons.home_rounded,
        label: l10n.tabHome,
      ),
      (
        icon: Icons.school_outlined,
        selected: Icons.school_rounded,
        label: l10n.tabAcademic,
      ),
      (
        icon: Icons.fitness_center_outlined,
        selected: Icons.fitness_center_rounded,
        label: l10n.tabTraining,
      ),
      (
        icon: Icons.flag_outlined,
        selected: Icons.flag_rounded,
        label: l10n.tabChallenges,
      ),
      (
        icon: Icons.insights_outlined,
        selected: Icons.insights_rounded,
        label: l10n.tabProgress,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) =>
      AchievementsHost(child: _layout(context));

  Widget _layout(BuildContext context) {
    final focus = context.select(
      (SessionBloc bloc) => bloc.account?.usageFocus ?? UsageFocus.both,
    );
    final branches = _visibleBranches(focus);
    final all = _destinations(context);
    final destinations = [for (final b in branches) all[b]];
    final selected = branches.indexOf(shell.currentIndex);
    if (selected < 0) {
      // La pestaña actual ya no existe con este enfoque: se va a Inicio en
      // vez de marcar una pestaña que no es la que se ve.
      WidgetsBinding.instance.addPostFrameCallback((_) => _select(0));
    }
    void onSelected(int i) => _select(branches[i]);
    final wide =
        MediaQuery.sizeOf(context).width >= TokensLayout.railBreakpoint;
    // Navegación y contenido son grupos de foco separados: sin ellos, el orden
    // geométrico por defecto intercala destinos del riel con el contenido.
    if (!wide) {
      return Scaffold(
        body: AppFocusGroup(child: shell),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: context.colors.outlineVariant),
            ),
          ),
          child: AppFocusGroup(
            child: NavigationBar(
              selectedIndex: selected < 0 ? 0 : selected,
              onDestinationSelected: onSelected,
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: AppNavFocusRing(child: Icon(d.icon)),
                    selectedIcon: AppNavFocusRing(child: Icon(d.selected)),
                    label: d.label,
                    // La etiqueta ya está visible: un tooltip la repetiría.
                    tooltip: '',
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            right: false,
            child: AppFocusGroup(
              child: NavigationRail(
                selectedIndex: selected < 0 ? 0 : selected,
                onDestinationSelected: onSelected,
                groupAlignment: -0.9,
                leading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: TokensSpacing.m),
                  child: AppBrandMark(size: TokensSize.iconXl),
                ),
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: AppNavFocusRing(rail: true, child: Icon(d.icon)),
                      selectedIcon: AppNavFocusRing(
                        rail: true,
                        child: Icon(d.selected),
                      ),
                      label: Text(d.label),
                      padding: const EdgeInsets.symmetric(
                        vertical: TokensSpacing.xs,
                      ),
                    ),
                ],
              ),
            ),
          ),
          VerticalDivider(width: 1, color: context.colors.outlineVariant),
          Expanded(child: AppFocusGroup(child: shell)),
        ],
      ),
    );
  }
}
