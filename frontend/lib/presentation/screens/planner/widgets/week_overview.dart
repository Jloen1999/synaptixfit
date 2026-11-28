import 'package:flutter/material.dart';

import '../../../../domain/models/planner/calendar_block.dart';
import '../../../../domain/models/planner/weekly_planning.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'planner_visuals.dart';

/// Línea de cifras de la semana bajo la tira de días (ADR 0060): «1 choque de
/// horario» (solo si los hay) y «10 h estudio · 3 h deporte». Cada chip lleva
/// flecha y abre su detalle: la lista de choques o la carga semanal. Las
/// entregas y exámenes no van aquí: los abre su icono de la barra.
class WeekSummaryChips extends StatelessWidget {
  const WeekSummaryChips({
    super.key,
    required this.balance,
    required this.conflicts,
    required this.titleOf,
    required this.onBalanceTap,
    required this.onConflictTap,
  });

  final WeekBalance? balance;
  final List<BlockConflict> conflicts;
  final String Function(CalendarBlock block) titleOf;

  /// Abre la carga semanal (horas planificadas y hechas, estado).
  final VoidCallback onBalanceTap;

  /// Abre el evento tocado en la lista de choques.
  final ValueChanged<CalendarBlock> onConflictTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final b = balance;
    final chips = <Widget>[
      // Un choque es un aviso: va primero para que se vea sin desplazar.
      if (conflicts.isNotEmpty)
        ActionChip(
          avatar: Icon(
            AppIcons.warning,
            size: TokensSize.iconS,
            color: context.palette.warning,
          ),
          label: SummaryChipLabel(l10n.plannerChipConflicts(conflicts.length)),
          onPressed: () => _showConflicts(context),
        ),
      if (b != null) _BalanceChip(balance: b, onTap: onBalanceTap),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    // Una sola línea (se desliza si no cabe): la rejilla no pierde alto. Con
    // el texto grande, los chips bajan de línea en vez de cortarse.
    if (context.largeText) {
      return Wrap(spacing: TokensSpacing.s, children: chips);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, chip) in chips.indexed) ...[
            if (i > 0) const SizedBox(width: TokensSpacing.s),
            chip,
          ],
        ],
      ),
    );
  }

  /// Las parejas que coinciden y a qué hora; tocar una abre su evento.
  Future<void> _showConflicts(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheet) {
          final l10n = sheet.localizations;
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                TokensSpacing.m,
                0,
                TokensSpacing.m,
                TokensSpacing.l,
              ),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.plannerConflictsTitle,
                    style: sheet.textStyles.titleMedium,
                  ),
                ),
                const SizedBox(height: TokensSpacing.xs),
                Text(
                  l10n.plannerConflictsHint,
                  style: sheet.textStyles.bodySmall?.copyWith(
                    color: sheet.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: TokensSpacing.s),
                for (final c in conflicts)
                  AppFocusOutline(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        AppIcons.conflict,
                        color: sheet.palette.warning,
                      ),
                      title: Text(
                        l10n.plannerConflictPair(
                          titleOf(c.first),
                          titleOf(c.second),
                        ),
                      ),
                      // El rato en que coinciden (no el horario de uno solo):
                      // así se entiende por qué es un choque.
                      subtitle: Text(
                        l10n.plannerConflictWhen(
                          PlannerFormats.dayShort(c.overlapStart),
                          PlannerFormats.time(c.overlapStart),
                          PlannerFormats.time(c.overlapEnd),
                        ),
                      ),
                      onTap: () {
                        Navigator.of(sheet).pop();
                        onConflictTap(c.first);
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
}

/// Horas planificadas de estudio y deporte de la semana; el icono es el del
/// estado del balance, que también dice su nombre (tooltip y lector), no solo
/// el color. Abre la carga semanal, que enseña lo hecho frente a lo
/// planificado.
class _BalanceChip extends StatelessWidget {
  const _BalanceChip({required this.balance, required this.onTap});

  final WeekBalance balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final label = l10n.plannerChipBalance(
      PlannerFormats.hours(balance.plannedStudyHours),
      PlannerFormats.hours(balance.plannedSportHours),
    );
    final state = balance.state.label(context);
    // El nombre empieza por el texto visible (WCAG 2.5.3) y añade qué es y
    // el estado; a la vista, el estado lo dice el tooltip («Equilibrada»).
    return Semantics(
      container: true,
      button: true,
      label: l10n.plannerChipBalanceLabel(label, state),
      excludeSemantics: true,
      onTap: onTap,
      child: ActionChip(
        tooltip: state,
        avatar: Icon(
          balance.state.icon,
          size: TokensSize.iconS,
          color: balance.state.color(context),
        ),
        label: SummaryChipLabel(label),
        onPressed: onTap,
      ),
    );
  }
}

/// Texto de un chip de la línea de cifras con la flecha de «abre algo»: así
/// se lee como botón y no como dato suelto. La flecha es decorativa (el chip
/// ya es botón para el lector).
class SummaryChipLabel extends StatelessWidget {
  const SummaryChipLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // En la fila que se desliza el ancho no tiene tope (una línea); con el
      // texto grande los chips van en un Wrap y el texto baja de línea.
      if (context.largeText) Flexible(child: Text(text)) else Text(text),
      const SizedBox(width: TokensSpacing.xxs),
      const ExcludeSemantics(
        child: Icon(AppIcons.next, size: TokensSize.iconXs),
      ),
    ],
  );
}

/// Estado del balance con icono y texto (no solo color).
class BalanceStateChip extends StatelessWidget {
  const BalanceStateChip({super.key, required this.balance});

  final WeekBalance balance;

  @override
  Widget build(BuildContext context) => AppPill(
    label: balance.state.label(context),
    color: balance.state.color(context),
    icon: balance.state.icon,
  );
}
