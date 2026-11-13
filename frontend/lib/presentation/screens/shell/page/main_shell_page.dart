import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/enums/usage_focus.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import '../../auth/session/bloc/session_bloc.dart';
import '../widgets/focus_timer_bar.dart';
import '../widgets/open_session_bar.dart';
import '../widgets/achievements_host.dart';

/// Estructura principal con las pestañas de [StatefulNavigationShell]:
/// Inicio · Calendario · Académico · Entreno · Progreso (ADR 0038), en barra
/// inferior en móvil y riel lateral en pantallas anchas. Según el enfoque de
/// uso se ocultan Académico (solo deporte) o Entreno (solo estudios); las
/// ramas del router no cambian, así que se traduce entre la posición visible
/// y el índice de rama. Los logros ([AchievementsHost]) se celebran aquí para
/// que se vean desde cualquier pestaña.
class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key, required this.shell});

  final StatefulNavigationShell shell;

  /// Índices de rama, en orden: inicio, calendario, académico, entreno,
  /// progreso.
  static const _calendarBranch = 1;
  static const _academicBranch = 2;
  static const _trainingBranch = 3;
  static const _progressBranch = 4;

  void _select(int branch) =>
      shell.goBranch(branch, initialLocation: branch == shell.currentIndex);

  static List<int> _visibleBranches(UsageFocus focus) => [
    0,
    _calendarBranch,
    if (focus.includesAcademic) _academicBranch,
    if (focus.includesFitness) _trainingBranch,
    _progressBranch,
  ];

  List<({IconData icon, IconData selected, String label})> _destinations(
    BuildContext context,
  ) {
    final l10n = context.localizations;
    return [
      (
        icon: AppIcons.tabHome,
        selected: AppIcons.tabHomeSelected,
        label: l10n.tabHome,
      ),
      (
        icon: AppIcons.tabCalendar,
        selected: AppIcons.tabCalendarSelected,
        label: l10n.tabCalendar,
      ),
      (
        icon: AppIcons.tabAcademic,
        selected: AppIcons.tabAcademicSelected,
        label: l10n.tabAcademic,
      ),
      (
        icon: AppIcons.tabTraining,
        selected: AppIcons.tabTrainingSelected,
        label: l10n.tabTraining,
      ),
      (
        icon: AppIcons.tabProgress,
        selected: AppIcons.tabProgressSelected,
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
    // Solo cuando el armazón está a la vista: si el modo de uso cambia desde
    // Perfil (pantalla completa encima), saltar ya cerraría Perfil y la
    // persona no vería que se guardó. Al volver, `ModalRoute.of` reconstruye.
    final visible = ModalRoute.of(context)?.isCurrent ?? true;
    if (selected < 0 && visible) {
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
        // El Pomodoro en marcha, justo encima de la navegación.
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OpenSessionBar(),
            const FocusTimerBar(),
            DecoratedBox(
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
          ],
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
          Expanded(
            child: Column(
              children: [
                Expanded(child: AppFocusGroup(child: shell)),
                // Abajo, como en el móvil: lejos de la barra de estado.
                const SafeArea(
                  top: false,
                  left: false,
                  child: OpenSessionBar(),
                ),
                const SafeArea(top: false, left: false, child: FocusTimerBar()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
