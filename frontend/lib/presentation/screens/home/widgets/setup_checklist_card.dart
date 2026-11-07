import 'package:flutter/material.dart';

import '../../../../domain/models/home/home_setup.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Aviso discreto de Inicio con lo que falta por configurar (lo decide el
/// servidor). Cada fila lleva a donde se resuelve; «Ahora no» lo oculta unos
/// días. No bloquea nada ni aparece como diálogo.
class SetupChecklistCard extends StatefulWidget {
  const SetupChecklistCard({
    super.key,
    required this.setup,
    required this.onOpen,
    required this.onLater,
  });

  final HomeSetup setup;
  final ValueChanged<HomeSetupTask> onOpen;
  final VoidCallback onLater;

  @override
  State<SetupChecklistCard> createState() => _SetupChecklistCardState();
}

/// Plegada muestra solo la tarea más importante: no empuja la agenda ni el
/// próximo entreno fuera de la pantalla.
class _SetupChecklistCardState extends State<SetupChecklistCard> {
  bool _expanded = false;

  HomeSetup get setup => widget.setup;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final tasks = _expanded ? setup.pending : setup.pending.take(1).toList();
    final hidden = setup.pending.length - tasks.length;
    final progress = setup.total == 0 ? 0.0 : setup.done / setup.total;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.homeSetupTitle,
              style: context.textStyles.titleMedium,
            ),
          ),
          const SizedBox(height: TokensSpacing.xs),
          Text(
            l10n.homeSetupProgress(setup.done, setup.total),
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TokensRadius.pill),
              child: LinearProgressIndicator(value: progress),
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          for (final task in tasks)
            AppFocusOutline(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                minTileHeight: TokensSize.listTileMin,
                dense: true,
                leading: Icon(_icon(task), color: context.colors.primary),
                title: Text(_title(context, task)),
                subtitle: Text(_hint(context, task)),
                trailing: const Icon(AppIcons.next),
                onTap: () => widget.onOpen(task),
              ),
            ),
          // Con texto grande y en francés los dos botones no caben en una fila.
          OverflowBar(
            alignment: MainAxisAlignment.end,
            overflowAlignment: OverflowBarAlignment.end,
            children: [
              if (hidden > 0 || _expanded)
                Semantics(
                  expanded: _expanded,
                  child: TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded
                          ? l10n.homeAgendaShowLess
                          : l10n.homeSetupShowAll(setup.pending.length),
                    ),
                  ),
                ),
              TextButton(
                onPressed: widget.onLater,
                child: Text(l10n.homeSetupLater),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _icon(HomeSetupTask task) => switch (task) {
    HomeSetupTask.subjects => Icons.class_outlined,
    HomeSetupTask.wellnessProfile => Icons.monitor_weight_outlined,
    HomeSetupTask.routine => Icons.fitness_center_rounded,
    HomeSetupTask.weekPlan => AppIcons.calendar,
    HomeSetupTask.academicProfile => Icons.school_outlined,
  };

  static String _title(BuildContext context, HomeSetupTask task) {
    final l10n = context.localizations;
    return switch (task) {
      HomeSetupTask.subjects => l10n.homeSetupSubjects,
      HomeSetupTask.wellnessProfile => l10n.homeSetupWellness,
      HomeSetupTask.routine => l10n.homeSetupRoutine,
      HomeSetupTask.weekPlan => l10n.homeSetupWeekPlan,
      HomeSetupTask.academicProfile => l10n.homeSetupAcademic,
    };
  }

  static String _hint(BuildContext context, HomeSetupTask task) {
    final l10n = context.localizations;
    return switch (task) {
      HomeSetupTask.subjects => l10n.homeSetupSubjectsHint,
      HomeSetupTask.wellnessProfile => l10n.homeSetupWellnessHint,
      HomeSetupTask.routine => l10n.homeSetupRoutineHint,
      HomeSetupTask.weekPlan => l10n.homeSetupWeekPlanHint,
      HomeSetupTask.academicProfile => l10n.homeSetupAcademicHint,
    };
  }
}
