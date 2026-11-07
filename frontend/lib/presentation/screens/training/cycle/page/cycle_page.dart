import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/cycle.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../l10n/gen_l10n/app_localizations.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../bloc/cycle_bloc.dart';

/// «Mi ciclo» (`/training/cycle`, opcional, ADR 0033): explicación y
/// consentimiento para activarlo; activo, el momento estimado, apuntar el día
/// y el mes. Solo lo ve quien lo activa.
class CyclePage extends StatelessWidget {
  const CyclePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<CycleBloc>()..add(const CycleEvent.started()),
    child: const _CycleView(),
  );
}

enum _MenuAction { disable, deleteAll }

class _CycleView extends StatelessWidget with ErrorsMessageMixin {
  const _CycleView();

  Future<void> _menu(BuildContext context, _MenuAction action) async {
    final l10n = context.localizations;
    final bloc = context.read<CycleBloc>();
    switch (action) {
      case _MenuAction.disable:
        final delete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.trainingCycleDisableTitle),
            content: Text(l10n.trainingCycleDisableMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  l10n.trainingCycleDisableDelete,
                  style: context.textStyles.labelLarge?.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.trainingCycleDisableKeep),
              ),
            ],
          ),
        );
        if (delete != null) {
          bloc.add(CycleEvent.disabled(deleteHistory: delete));
        }
      case _MenuAction.deleteAll:
        final ok = await showConfirmDialog(
          context,
          title: l10n.trainingCycleDeleteAllTitle,
          message: l10n.trainingCycleDeleteAllMessage,
          confirmLabel: l10n.trainingCycleDeleteAllConfirm,
        );
        if (ok) bloc.add(const CycleEvent.historyDeleted());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<CycleBloc, CycleState>(
      listenWhen: (a, b) =>
          (b.notice != null && a.notice != b.notice) ||
          (b.actionError != null && a.actionError != b.actionError),
      listener: (context, state) {
        if (state.actionError case final error?) {
          context.showSnack(errorMessage(context, error));
          return;
        }
        // Borrar un día se deshace volviendo a apuntarlo tal cual estaba.
        if (state.notice == CycleNotice.deleted) {
          if (state.deletedDay case final day?) {
            final bloc = context.read<CycleBloc>();
            final controller = context.showActionSnack(
              l10n.trainingCycleDayDeleted,
              actionLabel: l10n.commonUndo,
              duration: TokensDuration.undoWindow,
              onAction: () => bloc.add(CycleEvent.dayLogged(day)),
            );
            // Ctrl+Z vale mientras se ve el aviso, como su «Deshacer».
            unawaited(
              controller.closed.then((_) {
                if (!bloc.isClosed) bloc.add(CycleEvent.undoExpired(day.date));
              }),
            );
            return;
          }
        }
        context.showSnack(switch (state.notice!) {
          CycleNotice.saved => l10n.trainingCycleSaved,
          CycleNotice.deleted => l10n.trainingCycleDayDeleted,
          CycleNotice.historyDeleted => l10n.trainingCycleHistoryDeleted,
          CycleNotice.disabled => l10n.trainingCycleDisabled,
        });
      },
      builder: (context, state) {
        final overview = state.overview;
        final enabled = overview?.enabled ?? false;
        // Ctrl+Z (Cmd+Z) deshace el borrado de un día mientras dura su aviso.
        return AppUndoShortcut(
          onUndo: () {
            final day = state.deletedDay;
            if (day == null) return;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            context.read<CycleBloc>().add(CycleEvent.dayLogged(day));
          },
          child: Scaffold(
            appBar: AppPageBar.reading(title: Text(l10n.trainingCycleTitle)),
            body: AppContentWidth.reading(
              child: switch (state) {
                CycleState(loading: true, overview: null) =>
                  const AppSkeletonList(),
                CycleState(error: final error?, overview: null) => AppErrorView(
                  error: error,
                  onRetry: () =>
                      context.read<CycleBloc>().add(const CycleEvent.started()),
                ),
                _ when !enabled => _Intro(saving: state.saving),
                _ => _Tracking(
                  state: state,
                  onManage: (action) => _menu(context, action),
                ),
              },
            ),
          ),
        );
      },
    );
  }
}

/// Qué es, para qué se usa y el consentimiento explícito.
class _Intro extends StatefulWidget {
  const _Intro({required this.saving});

  final bool saving;

  @override
  State<_Intro> createState() => _IntroState();
}

class _IntroState extends State<_Intro> {
  bool _consent = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final muted = context.textStyles.bodyMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        Icon(
          Icons.water_drop_outlined,
          size: TokensSize.iconL,
          color: context.colors.primary,
        ),
        const SizedBox(height: TokensSpacing.m),
        Semantics(
          header: true,
          child: Text(
            l10n.trainingCycleIntroTitle,
            style: context.textStyles.headlineSmall,
          ),
        ),
        const SizedBox(height: TokensSpacing.s),
        Text(l10n.trainingCycleIntro, style: context.textStyles.bodyLarge),
        const SizedBox(height: TokensSpacing.m),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, color: context.colors.primary),
              const SizedBox(width: TokensSpacing.s),
              Expanded(child: Text(l10n.trainingCyclePrivacy, style: muted)),
            ],
          ),
        ),
        const SizedBox(height: TokensSpacing.m),
        AppFocusOutline(
          child: CheckboxListTile(
            value: _consent,
            onChanged: (v) => setState(() => _consent = v ?? false),
            title: Text(l10n.trainingCycleConsent),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: TokensSpacing.m),
        AppPrimaryButton(
          label: l10n.trainingCycleEnable,
          icon: Icons.check_rounded,
          loading: widget.saving,
          onPressed: _consent
              ? () => context.read<CycleBloc>().add(
                  CycleEvent.enabled(consent: _consent),
                )
              : null,
        ),
      ],
    );
  }
}

String _phaseLabel(AppLocalizations l10n, CyclePhase phase) => switch (phase) {
  CyclePhase.period => l10n.trainingCyclePhasePeriod,
  CyclePhase.afterPeriod => l10n.trainingCyclePhaseAfter,
  CyclePhase.midCycle => l10n.trainingCyclePhaseMid,
  CyclePhase.beforePeriod => l10n.trainingCyclePhaseBefore,
};

/// Seguimiento activo: resumen, hoy y el mes.
class _Tracking extends StatelessWidget {
  const _Tracking({required this.state, required this.onManage});

  final CycleState state;
  final ValueChanged<_MenuAction> onManage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final overview = state.overview!;
    final muted = context.textStyles.bodyMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final today = DateUtils.dateOnly(DateTime.now());
    final phase = overview.phase;
    return ListView(
      // Relleno lateral pequeño: así caben siete días de 48 dp en un móvil
      // de 360 dp.
      padding: const EdgeInsets.symmetric(
        horizontal: TokensSpacing.s,
        vertical: TokensSpacing.m,
      ),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (phase != null)
                AppPill(
                  label: _phaseLabel(l10n, phase),
                  icon: Icons.water_drop_outlined,
                )
              else
                Text(l10n.trainingCyclePhaseUnknown, style: muted),
              if (overview.dayOfCycle case final day?) ...[
                const SizedBox(height: TokensSpacing.s),
                Text(
                  l10n.trainingCycleDayOf(day),
                  style: context.textStyles.titleLarge,
                ),
              ],
              if (overview.nextPeriodFrom case final next?) ...[
                const SizedBox(height: TokensSpacing.xs),
                Text(
                  l10n.trainingCycleNext(
                    DateFormat.MMMMd(l10n.localeName).format(next),
                  ),
                  style: context.textStyles.bodyLarge,
                ),
              ],
              const SizedBox(height: TokensSpacing.s),
              Text(l10n.trainingCycleEstimate, style: muted),
            ],
          ),
        ),
        const SizedBox(height: TokensSpacing.m),
        AppSectionHeader(title: l10n.trainingCycleTodayTitle),
        AppPrimaryButton(
          label: overview.today == null
              ? l10n.trainingCycleLogToday
              : l10n.trainingCycleChangeToday,
          icon: Icons.edit_calendar_rounded,
          onPressed: () =>
              showCycleDaySheet(context, date: today, current: overview.today),
        ),
        const SizedBox(height: TokensSpacing.s),
        Text(l10n.trainingCycleAdjustHint, style: muted),
        const SizedBox(height: TokensSpacing.l),
        _Month(state: state),
        // Antes en un menú de tres puntos: a la vista y con texto.
        const SizedBox(height: TokensSpacing.l),
        AppSectionHeader(title: l10n.trainingCycleMenu),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => onManage(_MenuAction.disable),
            icon: const Icon(Icons.toggle_off_outlined),
            label: Text(l10n.trainingCycleDisable),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => onManage(_MenuAction.deleteAll),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            icon: const Icon(AppIcons.delete),
            label: Text(l10n.trainingCycleDeleteAll),
          ),
        ),
      ],
    );
  }
}

/// Calendario del mes: cada día dice si hubo regla o se apuntó algo, con
/// icono además del color. Tocar un día pasado lo abre para apuntarlo.
class _Month extends StatelessWidget with ErrorsMessageMixin {
  const _Month({required this.state});

  final CycleState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final material = MaterialLocalizations.of(context);
    final month = state.month;
    final today = DateUtils.dateOnly(DateTime.now());
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = material.firstDayOfWeekIndex;
    final offset =
        (DateTime(month.year, month.month).weekday % 7 - firstWeekday + 7) % 7;
    final weekdays = [
      for (var i = 0; i < 7; i++)
        material.narrowWeekdays[(firstWeekday + i) % 7],
    ];
    final isCurrentMonth =
        month.year == today.year && month.month == today.month;
    // Con el día de la semana: las cabeceras L-M-X no se leen.
    final dayLabel = DateFormat.MMMMEEEEd(l10n.localeName);
    // Alto de fila: 48 dp como mínimo y más con letra grande, para que la
    // cifra y su marca no se corten.
    final rowHeight = MediaQuery.textScalerOf(context)
        .scale(TokensLayout.minTouchTarget)
        .clamp(TokensLayout.minTouchTarget, double.infinity)
        .toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.trainingCyclePrevMonth,
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => context.read<CycleBloc>().add(
                CycleEvent.monthChanged(DateTime(month.year, month.month - 1)),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  toBeginningOfSentenceCase(
                    DateFormat.yMMMM(l10n.localeName).format(month),
                  ),
                  textAlign: TextAlign.center,
                  style: context.textStyles.titleMedium,
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.trainingCycleNextMonth,
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: isCurrentMonth
                  ? null
                  : () => context.read<CycleBloc>().add(
                      CycleEvent.monthChanged(
                        DateTime(month.year, month.month + 1),
                      ),
                    ),
            ),
          ],
        ),
        Text(
          l10n.trainingCycleMonthHint,
          textAlign: TextAlign.center,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: TokensSpacing.s),
        if (state.daysError case final error?)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInlineMessage(message: errorMessage(context, error)),
              const SizedBox(height: TokensSpacing.s),
              AppSecondaryButton(
                label: l10n.commonRetry,
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => context.read<CycleBloc>().add(
                  CycleEvent.monthChanged(month),
                ),
              ),
            ],
          )
        else if (state.daysLoading)
          AppSkeletonGroup(child: AppSkeleton(height: rowHeight * 6))
        else
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: rowHeight,
            ),
            children: [
              for (final w in weekdays)
                ExcludeSemantics(
                  child: Center(
                    child: Text(w, style: context.textStyles.labelMedium),
                  ),
                ),
              for (var i = 0; i < offset; i++) const SizedBox.shrink(),
              for (var d = 1; d <= daysInMonth; d++)
                Builder(
                  builder: (context) {
                    final date = DateTime(month.year, month.month, d);
                    final logged = state.days[date];
                    final future = date.isAfter(today);
                    final isToday = date == today;
                    final label = isToday
                        ? l10n.trainingCycleTodayDate(dayLabel.format(date))
                        : dayLabel.format(date);
                    return _DayCell(
                      day: d,
                      today: isToday,
                      period: logged?.period ?? false,
                      logged: logged != null,
                      semanticLabel: logged == null
                          ? l10n.trainingCycleDayEmpty(label)
                          : logged.period
                          ? l10n.trainingCycleDayPeriod(label)
                          : l10n.trainingCycleDayLogged(label),
                      onTap: future
                          ? null
                          : () => showCycleDaySheet(
                              context,
                              date: date,
                              current: logged,
                            ),
                    );
                  },
                ),
            ],
          ),
        const SizedBox(height: TokensSpacing.s),
        Wrap(
          spacing: TokensSpacing.m,
          children: [
            // Como el día real: círculo de color con la gota dentro.
            _Legend(
              icon: Icons.water_drop_rounded,
              color: context.palette.onCycleContainer,
              background: context.palette.cycleContainer,
              label: l10n.trainingCycleLegendPeriod,
            ),
            _Legend(
              icon: Icons.check_rounded,
              color: context.colors.primary,
              label: l10n.trainingCycleLegendLogged,
            ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.today,
    required this.period,
    required this.logged,
    required this.semanticLabel,
    required this.onTap,
  });

  final int day;
  final bool today;
  final bool period;
  final bool logged;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = context.palette;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: AppFocusOutline(
        borderRadius: BorderRadius.circular(TokensRadius.pill),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: TokensLayout.minTouchTarget,
              minHeight: TokensLayout.minTouchTarget,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: period ? palette.cycleContainer : null,
                border: today
                    ? Border.all(
                        color: colors.primary,
                        width: TokensSize.focusRing,
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$day',
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: period
                          ? palette.onCycleContainer
                          : onTap == null
                          ? colors.onSurfaceVariant
                          : colors.onSurface,
                    ),
                  ),
                  // Forma distinta (gota o marca), no solo color.
                  if (period)
                    Icon(
                      Icons.water_drop_rounded,
                      size: TokensSize.iconXs,
                      color: palette.onCycleContainer,
                    )
                  else if (logged)
                    Icon(
                      Icons.check_rounded,
                      size: TokensSize.iconXs,
                      color: colors.primary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Una entrada de la leyenda del mes; con [background], el icono va en un
/// círculo de ese color, igual que se pinta el día en la cuadrícula.
class _Legend extends StatelessWidget {
  const _Legend({
    required this.icon,
    required this.color,
    required this.label,
    this.background,
  });

  final IconData icon;
  final Color color;
  final String label;
  final Color? background;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (background case final fill?)
        DecoratedBox(
          decoration: BoxDecoration(shape: BoxShape.circle, color: fill),
          child: Padding(
            padding: const EdgeInsets.all(TokensSpacing.xxs),
            child: Icon(icon, size: TokensSize.iconXs, color: color),
          ),
        )
      else
        Icon(icon, size: TokensSize.iconXs, color: color),
      const SizedBox(width: TokensSpacing.xs),
      Text(label, style: context.textStyles.bodySmall),
    ],
  );
}

/// Hoja para apuntar o corregir un día: regla, energía, molestias y nota.
Future<void> showCycleDaySheet(
  BuildContext context, {
  required DateTime date,
  CycleDay? current,
}) {
  final bloc = context.read<CycleBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _DaySheet(date: date, current: current),
    ),
  );
}

class _DaySheet extends StatefulWidget {
  const _DaySheet({required this.date, this.current});

  final DateTime date;
  final CycleDay? current;

  @override
  State<_DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<_DaySheet> {
  late bool _period = widget.current?.period ?? false;
  late CycleEnergy? _energy = widget.current?.energy;
  late final Set<CycleSymptom> _symptoms = {...?widget.current?.symptoms};
  late final _note = TextEditingController(text: widget.current?.note);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _save() {
    context.read<CycleBloc>().add(
      CycleEvent.dayLogged(
        CycleDay(
          date: widget.date,
          period: _period,
          energy: _energy,
          symptoms: {..._symptoms},
          note: _note.text,
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final symptoms = {
      CycleSymptom.cramps: l10n.trainingCycleSymptomCramps,
      CycleSymptom.abdominalPain: l10n.trainingCycleSymptomAbdominal,
      CycleSymptom.lowerBackPain: l10n.trainingCycleSymptomBack,
      CycleSymptom.bloating: l10n.trainingCycleSymptomBloating,
      CycleSymptom.headache: l10n.trainingCycleSymptomHeadache,
    };
    final energies = {
      CycleEnergy.low: l10n.trainingCycleEnergyLow,
      CycleEnergy.normal: l10n.trainingCycleEnergyNormal,
      CycleEnergy.high: l10n.trainingCycleEnergyHigh,
    };
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: TokensSpacing.m,
          right: TokensSpacing.m,
          bottom: MediaQuery.viewInsetsOf(context).bottom + TokensSpacing.m,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.trainingCycleDaySheetTitle(
                    DateFormat.MMMEd(l10n.localeName).format(widget.date),
                  ),
                  style: context.textStyles.titleLarge,
                ),
              ),
              const SizedBox(height: TokensSpacing.s),
              AppFocusOutline(
                child: SwitchListTile(
                  value: _period,
                  onChanged: (v) => setState(() => _period = v),
                  title: Text(l10n.trainingCyclePeriodToggle),
                  secondary: const Icon(Icons.water_drop_outlined),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              AppSectionHeader(title: l10n.trainingCycleEnergy),
              Wrap(
                spacing: TokensSpacing.s,
                runSpacing: TokensSpacing.s,
                children: [
                  for (final MapEntry(key: energy, value: label)
                      in energies.entries)
                    ChoiceChip(
                      label: Text(label),
                      selected: _energy == energy,
                      onSelected: (on) =>
                          setState(() => _energy = on ? energy : null),
                    ),
                ],
              ),
              const SizedBox(height: TokensSpacing.m),
              AppSectionHeader(title: l10n.trainingCycleSymptoms),
              Wrap(
                spacing: TokensSpacing.s,
                runSpacing: TokensSpacing.s,
                children: [
                  for (final MapEntry(key: symptom, value: label)
                      in symptoms.entries)
                    FilterChip(
                      label: Text(label),
                      selected: _symptoms.contains(symptom),
                      onSelected: (on) => setState(
                        () => on
                            ? _symptoms.add(symptom)
                            : _symptoms.remove(symptom),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: TokensSpacing.m),
              AppTextField(
                controller: _note,
                label: l10n.trainingCycleNote,
                icon: Icons.notes_rounded,
                maxLength: 300,
              ),
              const SizedBox(height: TokensSpacing.m),
              AppPrimaryButton(
                label: l10n.trainingCycleSave,
                icon: Icons.check_rounded,
                onPressed: _save,
              ),
              if (widget.current != null) ...[
                const SizedBox(height: TokensSpacing.s),
                AppSecondaryButton(
                  label: l10n.trainingCycleDeleteDay,
                  icon: const Icon(AppIcons.delete),
                  onPressed: () {
                    context.read<CycleBloc>().add(
                      CycleEvent.dayDeleted(widget.date),
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
