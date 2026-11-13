import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/enums/usage_focus.dart';
import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// «Tu semana»: lo planificado de cada día con los tres estados del
/// vocabulario (Hecho, Por hacer, Sin hacer), un título que se entiende solo
/// («12 de 18 hechos esta semana») y, en una línea, lo hecho en la semana
/// (entrenos y estudio; las kcal viven en Progreso). Los siete días van
/// siempre en una fila compacta. Tocar un día lo abre en el calendario.
///
/// Por hacer = planificado − hecho − sin hacer (el servidor manda los otros
/// tres números; descanso, comida y sueño no cuentan).
class PlanWeekBar extends StatelessWidget {
  const PlanWeekBar({
    super.key,
    required this.days,
    required this.week,
    this.focus = UsageFocus.both,
    required this.onOpenDay,
    this.now,
    this.headerFocusNode,
  });

  /// Foco del título (al ocultar la tarjeta de configurar, que va después).
  final FocusNode? headerFocusNode;

  final List<HomePlanDay> days;
  final HomeWeekKpis week;

  /// Enfoque de uso: el resumen solo nombra lo que la persona hace.
  final UsageFocus focus;

  /// Abre ese día en el planificador.
  final ValueChanged<DateTime> onOpenDay;
  final DateTime? now;

  static int pendingOf(HomePlanDay d) =>
      math.max(0, d.planned - d.completed - d.missed);

  /// Lo que dice el lector de un día: lo mismo que se ve («2/3») y sin ceros.
  static String daySemantics(
    AppLocalizations l10n,
    HomePlanDay day,
    String dayName, {
    required bool isToday,
  }) {
    final name = isToday ? l10n.homePlanDayToday(dayName) : dayName;
    if (day.planned == 0) return l10n.homePlanDayEmpty(name);
    final pending = pendingOf(day);
    return [
      l10n.homePlanDaySemantics(name, day.completed, day.planned),
      if (pending > 0) l10n.homePlanWeekPending(pending),
      if (day.missed > 0) l10n.homePlanWeekMissed(day.missed),
    ].join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final planned = days.fold<int>(0, (sum, d) => sum + d.planned);
    final completed = days.fold<int>(0, (sum, d) => sum + d.completed);
    final missed = days.fold<int>(0, (sum, d) => sum + d.missed);
    final pending = days.fold<int>(0, (sum, d) => sum + pendingOf(d));
    final maxValue = days.fold<int>(1, (m, d) => math.max(m, d.planned));
    final current = now ?? DateTime.now();
    const weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final longDay = DateFormat.EEEE();
    final weekParts = [
      if (focus.includesFitness)
        week.plannedSessions != null && week.plannedSessions! > 0
            ? l10n.homeWeekSessionsOfPlanned(
                week.sessions,
                week.plannedSessions!,
              )
            : l10n.homeWeekSessions(week.sessions),
      if (focus.includesAcademic)
        l10n.homeWeekStudyMinutes(week.studyMinutesCompleted),
    ];
    final breakdown = [
      if (pending > 0) l10n.homePlanWeekPending(pending),
      if (missed > 0) l10n.homePlanWeekMissed(missed),
    ];
    final secondary = context.textStyles.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: l10n.homePlanWeekTitle,
          focusNode: headerFocusNode,
        ),
        // Sin relleno lateral en la tarjeta: la fila de días usa todo el ancho
        // y cada día llega a 48 px en un móvil de 390 (los textos llevan el
        // suyo).
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: TokensSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TokensSpacing.m,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      planned == 0
                          ? l10n.homePlanWeekEmpty
                          : l10n.homePlanWeekSummary(completed, planned),
                      style: context.textStyles.titleMedium,
                    ),
                    if (breakdown.isNotEmpty)
                      Text(breakdown.join(' · '), style: secondary),
                    Text(weekParts.join(' · '), style: secondary),
                  ],
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              // Siempre en una fila: en dos (4 + 3) dejaba un hueco grande.
              // Cada día mide al menos 24 px de ancho (WCAG 2.5.8) incluso en
              // el móvil más estrecho. Sin nada planificado, barras bajas.
              LayoutBuilder(
                builder: (context, constraints) {
                  Widget dayButton(HomePlanDay day) => _DayButton(
                    day: day,
                    maxValue: maxValue,
                    height: planned == 0
                        ? TokensSize.iconS
                        : TokensSize.weekBarHeight,
                    label: l10n.commonWeekdayInitial(
                      weekdays[day.date.weekday - 1],
                    ),
                    semantics: daySemantics(
                      l10n,
                      day,
                      longDay.format(day.date),
                      isToday: DateUtils.isSameDay(day.date, current),
                    ),
                    isToday: DateUtils.isSameDay(day.date, current),
                    onTap: () => onOpenDay(day.date),
                  );
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final day in days) Expanded(child: dayButton(day)),
                    ],
                  );
                },
              ),
              const SizedBox(height: TokensSpacing.s),
              // Leyenda con las mismas formas que las barras: se distinguen
              // por la forma y no solo por el color (WCAG 1.4.1 y 1.4.11).
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TokensSpacing.m,
                ),
                child: ExcludeSemantics(
                  child: Wrap(
                    spacing: TokensSpacing.m,
                    runSpacing: TokensSpacing.xs,
                    children: [
                      _Legend(
                        kind: _Segment.done,
                        label: l10n.homePlanWeekLegendDone,
                      ),
                      _Legend(
                        kind: _Segment.missed,
                        label: l10n.homePlanWeekLegendMissed,
                      ),
                      _Legend(
                        kind: _Segment.pending,
                        label: l10n.homePlanWeekLegendPending,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Los tres estados de lo planificado y cómo se dibuja cada uno: hecho,
/// relleno; sin hacer, rayado; por hacer, hueco con borde.
enum _Segment { done, missed, pending }

class _SegmentBox extends StatelessWidget {
  const _SegmentBox({required this.kind, this.height, this.width});

  final _Segment kind;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(TokensRadius.s);
    return switch (kind) {
      _Segment.done => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: context.palette.success,
          borderRadius: radius,
        ),
      ),
      _Segment.missed => ClipRRect(
        borderRadius: radius,
        child: CustomPaint(
          painter: _StripesPainter(context.palette.warning),
          child: SizedBox(height: height, width: width),
        ),
      ),
      _Segment.pending => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.outline),
          borderRadius: radius,
        ),
      ),
    };
  }
}

/// Rayas diagonales del color de aviso: «Sin hacer» se reconoce también sin
/// distinguir colores.
class _StripesPainter extends CustomPainter {
  const _StripesPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = color.withValues(alpha: AppPill.tintAlpha),
    );
    final stripe = Paint()
      ..color = color
      ..strokeWidth = TokensSize.focusRing;
    const gap = TokensSpacing.xs;
    for (var x = -size.height; x < size.width; x += gap * 2) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripe,
      );
    }
  }

  @override
  bool shouldRepaint(_StripesPainter oldDelegate) => oldDelegate.color != color;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.kind, required this.label});

  final _Segment kind;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _SegmentBox(
        kind: kind,
        height: TokensSize.iconXs,
        width: TokensSize.iconXs,
      ),
      const SizedBox(width: TokensSpacing.xs),
      Text(
        label,
        style: context.textStyles.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ],
  );
}

/// Un día: barra apilada (hecho abajo, luego sin hacer y por hacer), «hechos
/// de planificados» y la inicial. Es un botón que abre el día; el lector de
/// pantalla dice lo mismo que se ve.
class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.day,
    required this.maxValue,
    required this.height,
    required this.label,
    required this.semantics,
    required this.isToday,
    required this.onTap,
  });

  final HomePlanDay day;
  final int maxValue;
  final double height;
  final String label;
  final String semantics;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final pending = PlanWeekBar.pendingOf(day);
    // Cada tramo mide al menos lo justo para reconocer su forma.
    double share(int n) =>
        math.max(height * n / maxValue, TokensSize.weekSegmentMin);
    final segments = [
      // De arriba abajo: lo que falta, lo que se quedó sin hacer y lo hecho.
      if (pending > 0) (_Segment.pending, share(pending)),
      if (day.missed > 0) (_Segment.missed, share(day.missed)),
      if (day.completed > 0) (_Segment.done, share(day.completed)),
    ];
    // Los mínimos pueden sumar más que la barra: se reparte lo que cabe.
    final total = segments.fold<double>(0, (sum, s) => sum + s.$2);
    final fit = total > height ? height / total : 1.0;
    final dayStyle = isToday
        ? context.textStyles.labelLarge?.copyWith(
            color: context.colors.primary,
            decoration: TextDecoration.underline,
          )
        : context.textStyles.labelMedium;
    return Semantics(
      button: true,
      label: semantics,
      hint: l10n.homePlanDayOpen,
      child: AppFocusOutline(
        borderRadius: BorderRadius.circular(TokensRadius.m),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TokensRadius.m),
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
              child: Column(
                children: [
                  SizedBox(
                    height: height,
                    width: TokensSize.iconS,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Sin nada planificado: una línea base neutra, no un
                        // «Por hacer».
                        if (segments.isEmpty)
                          Divider(
                            height: TokensSize.focusRing,
                            thickness: TokensSize.focusRing,
                            color: context.colors.outlineVariant,
                          ),
                        for (final (i, (kind, h)) in segments.indexed) ...[
                          if (i > 0) const SizedBox(height: TokensSpacing.xxs),
                          _SegmentBox(
                            kind: kind,
                            height: h * fit - TokensSpacing.xxs,
                            width: TokensSize.iconS,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.xs),
                  // Con texto grande se encoge en vez de cortarse («10/12»).
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.homePlanDayCount(day.completed, day.planned),
                      maxLines: 1,
                      style: context.textStyles.labelSmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(label.toUpperCase(), style: dayStyle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
