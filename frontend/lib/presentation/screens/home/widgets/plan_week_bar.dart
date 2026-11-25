import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/enums/home_day_mark.dart';
import '../../../../domain/enums/home_week_state.dart';
import '../../../../domain/enums/usage_focus.dart';
import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// «Tu semana» (ADR 0059): una frase que dice cómo vas («Vas bien», «Vas por
/// detrás» o «Semana sin plan»), «8 de 12 cosas hechas · 2 se quedaron sin
/// hacer», un círculo por día con una marca que se entiende sin color (✓ todo
/// hecho, medio lleno a medias, «!» algo sin hacer, el número de lo que queda
/// o «–» sin nada) y «Entrenos 2 de 3» / «Estudio 5 h de 8 h» con su barra.
/// El estado de la semana y la marca de cada día los decide el servidor;
/// tocar un día lo abre en el calendario.
class PlanWeekBar extends StatelessWidget {
  const PlanWeekBar({
    super.key,
    required this.days,
    required this.week,
    required this.summary,
    this.focus = UsageFocus.both,
    required this.onOpenDay,
    this.now,
    this.headerFocusNode,
  });

  /// Foco del título (al ocultar la tarjeta de configurar, que va después).
  final FocusNode? headerFocusNode;

  final List<HomePlanDay> days;
  final HomeWeekKpis week;
  final HomeWeekSummary summary;

  /// Enfoque de uso: las cifras solo nombran lo que la persona hace.
  final UsageFocus focus;

  /// Abre ese día en el calendario.
  final ValueChanged<DateTime> onOpenDay;
  final DateTime? now;

  /// Lo que dice el lector de un día: lo mismo que se ve, con palabras.
  static String daySemantics(
    AppLocalizations l10n,
    HomePlanDay day,
    String dayName, {
    required bool isToday,
  }) {
    final name = isToday ? l10n.homePlanDayToday(dayName) : dayName;
    return switch (day.mark) {
      HomeDayMark.none => l10n.homePlanDayEmpty(name),
      HomeDayMark.done => l10n.homeWeekDayDone(name),
      HomeDayMark.partial => l10n.homePlanDaySemantics(
        name,
        day.completed,
        day.planned,
      ),
      HomeDayMark.missed => l10n.homeWeekDayMissed(day.missed, name),
      HomeDayMark.pending => l10n.homeWeekDayPending(name, day.pending),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final current = now ?? DateTime.now();
    final longDay = DateFormat.EEEE(l10n.localeName);
    const weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final (stateText, stateColor) = switch (summary.state) {
      HomeWeekState.onTrack => (l10n.homeWeekOnTrack, context.palette.success),
      HomeWeekState.behind => (l10n.homeWeekBehind, context.palette.warning),
      HomeWeekState.noPlan => (
        l10n.homeWeekNoPlan,
        context.colors.onSurfaceVariant,
      ),
    };
    final headline = summary.planned == 0
        ? l10n.homePlanWeekEmpty
        : [
            l10n.homeWeekDoneOf(summary.done, summary.planned),
            if (summary.missed > 0) l10n.homeWeekMissedCount(summary.missed),
          ].join(' · ');
    final plannedSessions = week.plannedSessions;
    final figures = <Widget>[
      if (focus.includesFitness)
        _Figure(
          label: l10n.homeWeekTrainings,
          value: plannedSessions != null && plannedSessions > 0
              ? l10n.homeWeekOfTotal('${week.sessions}', '$plannedSessions')
              // La etiqueta ya dice «Entrenos»: sin plan, solo el número
              // (como Estudio, que solo pone las horas).
              : '${week.sessions}',
          progress: plannedSessions != null && plannedSessions > 0
              ? week.sessions / plannedSessions
              : null,
          color: context.colors.primary,
        ),
      if (focus.includesAcademic)
        _Figure(
          label: l10n.homeWeekStudy,
          value: week.studyMinutesPlanned > 0
              ? l10n.homeWeekOfTotal(
                  _hours(l10n, week.studyMinutesCompleted),
                  _hours(l10n, week.studyMinutesPlanned),
                )
              : _hours(l10n, week.studyMinutesCompleted),
          progress: week.studyMinutesPlanned > 0
              ? week.studyMinutesCompleted / week.studyMinutesPlanned
              : null,
          color: context.palette.study,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: l10n.homePlanWeekTitle,
          focusNode: headerFocusNode,
        ),
        // Sin relleno lateral en la fila de días: cada día llega a 48 px en un
        // móvil de 390 (WCAG 2.5.8); el resto lleva el suyo.
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: TokensSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Inset(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppPill(label: stateText, color: stateColor),
                ),
              ),
              const SizedBox(height: TokensSpacing.s),
              _Inset(
                child: Text(headline, style: context.textStyles.titleSmall),
              ),
              const SizedBox(height: TokensSpacing.m),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final day in days)
                    Expanded(
                      child: _DayButton(
                        day: day,
                        isToday: DateUtils.isSameDay(day.date, current),
                        label: DateUtils.isSameDay(day.date, current)
                            ? l10n.homeWeekToday
                            : l10n.commonWeekdayInitial(
                                weekdays[day.date.weekday - 1],
                              ),
                        semantics: daySemantics(
                          l10n,
                          day,
                          longDay.format(day.date),
                          isToday: DateUtils.isSameDay(day.date, current),
                        ),
                        onTap: () => onOpenDay(day.date),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: TokensSpacing.s),
              // Sin plan no hay marcas que explicar: se dice qué hacer.
              if (summary.state == HomeWeekState.noPlan)
                _Inset(
                  child: Text(
                    l10n.homeWeekNoPlanHint,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                )
              else
                // Leyenda con las mismas marcas: se distinguen por la forma y no
                // solo por el color (WCAG 1.4.1 y 1.4.11).
                _Inset(
                  child: ExcludeSemantics(
                    child: Wrap(
                      spacing: TokensSpacing.m,
                      runSpacing: TokensSpacing.xs,
                      children: [
                        _Legend(
                          mark: HomeDayMark.done,
                          label: l10n.homeWeekLegendDone,
                        ),
                        _Legend(
                          mark: HomeDayMark.partial,
                          label: l10n.homeWeekLegendPartial,
                        ),
                        _Legend(
                          mark: HomeDayMark.missed,
                          label: l10n.homeWeekLegendMissed,
                        ),
                        _Legend(
                          mark: HomeDayMark.pending,
                          label: l10n.homeWeekLegendPending,
                        ),
                      ],
                    ),
                  ),
                ),
              if (figures.isNotEmpty) ...[
                const SizedBox(height: TokensSpacing.m),
                _Inset(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, f) in figures.indexed) ...[
                        if (i > 0) const SizedBox(width: TokensSpacing.s),
                        Expanded(child: f),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// «5 h», «1 h 30 min» o «45 min».
  static String _hours(AppLocalizations l10n, int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return l10n.homeWeekMinutesShort(m);
    if (m == 0) return l10n.homeWeekHoursShort(h);
    return l10n.homeWeekHoursMinutesShort(h, m);
  }
}

/// Relleno lateral de lo que no es la fila de días.
class _Inset extends StatelessWidget {
  const _Inset({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.m),
    child: child,
  );
}

/// Una cifra de la semana con su palabra y su barra («Entrenos · 2 de 3»).
class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.color,
    this.progress,
  });

  final String label;
  final String value;
  final Color color;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final value = progress;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(TokensSpacing.s),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(TokensRadius.m),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.textStyles.labelMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            Text(this.value, style: context.textStyles.titleSmall),
            if (value != null) ...[
              const SizedBox(height: TokensSpacing.xs),
              ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(TokensRadius.pill),
                  child: LinearProgressIndicator(
                    value: value.clamp(0, 1).toDouble(),
                    minHeight: TokensSize.progressBar,
                    color: color,
                    backgroundColor: context.colors.outlineVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// La marca de un día: círculo con forma propia para cada estado.
class _Mark extends StatelessWidget {
  const _Mark({required this.mark, this.pending = 0, this.size});

  final HomeDayMark mark;
  final int pending;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? TokensSize.thumbnailXs;
    final colors = context.colors;
    final palette = context.palette;
    final glyph = context.textStyles.labelLarge;
    Widget circle({
      Color? fill,
      Color? border,
      Widget? child,
      Gradient? gradient,
    }) => Container(
      width: dimension,
      height: dimension,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        gradient: gradient,
        border: border == null
            ? null
            : Border.all(color: border, width: TokensSize.focusRing),
      ),
      child: child == null
          ? null
          : FittedBox(fit: BoxFit.scaleDown, child: child),
    );
    return switch (mark) {
      HomeDayMark.done => circle(
        fill: palette.success,
        child: Icon(
          AppIcons.check,
          color: palette.onSuccess,
          size: TokensSize.iconS,
        ),
      ),
      // Medio lleno: la mitad de abajo rellena y el borde entero.
      HomeDayMark.partial => circle(
        border: colors.primary,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.surface,
            colors.surface,
            colors.primary,
            colors.primary,
          ],
          stops: const [0, 0.5, 0.5, 1],
        ),
      ),
      HomeDayMark.missed => circle(
        border: palette.warning,
        fill: palette.warning.withValues(alpha: AppPill.tintAlpha),
        child: Text(
          '!',
          // El texto sobre el tinte, en el color del texto: llega a 4,5:1.
          style: glyph?.copyWith(color: colors.onSurface),
        ),
      ),
      HomeDayMark.pending => circle(
        border: colors.outline,
        child: Text(
          pending > 0 ? '$pending' : '',
          style: glyph?.copyWith(color: colors.onSurface),
        ),
      ),
      HomeDayMark.none => circle(
        border: colors.outlineVariant,
        child: Text(
          '–',
          style: glyph?.copyWith(color: colors.onSurfaceVariant),
        ),
      ),
    };
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.mark, required this.label});

  final HomeDayMark mark;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _Mark(mark: mark, pending: 2, size: TokensSize.iconS),
      const SizedBox(width: TokensSpacing.xs),
      Text(
        label,
        style: context.textStyles.labelMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ],
  );
}

/// Un día: su marca y debajo la inicial (o «Hoy»). Es un botón que abre el
/// día; el lector dice lo mismo que se ve, con palabras.
class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.day,
    required this.isToday,
    required this.label,
    required this.semantics,
    required this.onTap,
  });

  final HomePlanDay day;
  final bool isToday;
  final String label;
  final String semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final style = isToday
        ? context.textStyles.titleSmall?.copyWith(
            color: context.colors.onSurface,
          )
        : context.textStyles.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          );
    return Semantics(
      container: true,
      button: true,
      label: semantics,
      hint: l10n.homePlanDayOpen,
      child: AppFocusOutline(
        borderRadius: BorderRadius.circular(TokensRadius.m),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TokensRadius.m),
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: TokensLayout.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Mark(mark: day.mark, pending: day.pending),
                    const SizedBox(height: TokensSpacing.xxs),
                    // Con texto grande se encoge en vez de cortarse («Hoy»).
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label, maxLines: 1, style: style),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
