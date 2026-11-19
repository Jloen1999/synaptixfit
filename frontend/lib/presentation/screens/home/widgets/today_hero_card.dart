import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/enums/home_day_state.dart';
import '../../../../domain/enums/home_event_kind.dart';
import '../../../../domain/enums/home_event_type.dart';
import '../../../../domain/enums/item_time_status.dart';
import '../../../../domain/enums/planner_enums.dart';
import '../../../../domain/enums/today_intensity.dart';
import '../../../../domain/enums/usage_focus.dart';
import '../../../../domain/models/home/home_dashboard.dart';
import '../../../../domain/models/home/today_next.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import '../../training/widgets/exercise_thumbnail.dart';
import '../../training/widgets/training_labels.dart';
import 'agenda_section.dart';

/// Las clases del horario: se ven en la agenda pero no cuentan como bloques
/// hechos (todavía no se dan por asistidas solas).
bool isClassEvent(HomeTodayEvent e) =>
    e.kind == HomeEventKind.block && e.type == HomeEventType.classSession;

/// «Tu día», lo primero de Inicio (ADR 0059): una barra fina con «N de M
/// hechos» y, debajo, filas que dicen **cuál** es cada cosa y se abren al
/// tocarlas: el entreno de hoy (foto, intensidad, sesión, minutos y
/// ejercicios, con «Empezar» en la fila), la clase o el evento de ahora o
/// siguiente (hora, aula y profesor) y la entrega o el examen más cercano.
/// Qué se nombra y en qué punto está el día lo decide el servidor; aquí solo
/// se pinta. Sin cifras de XP ni de carga (ADR 0038).
class TodayHeroCard extends StatefulWidget {
  const TodayHeroCard({
    super.key,
    required this.dashboard,
    required this.focus,
    required this.onAction,
    this.starting = false,
    this.onMarkDone,
    this.completingIds = const {},
    this.onStartTraining,
    this.onOpenTraining,
    this.onOpenEvent,
    this.onOpenDeadline,
    this.onOpenAgenda,
    this.primaryElsewhere = false,
    this.blockedBy,
    this.now,
  });

  final HomeDashboard dashboard;
  final UsageFocus focus;

  /// «Concentrarme» del evento o «Añadir al calendario» sin nada que hacer.
  final ValueChanged<TodayAction> onAction;

  /// Se está abriendo la sesión de entrenamiento.
  final bool starting;

  /// Marca como hecho el evento de la fila; sin él no se ofrece.
  final ValueChanged<HomeTodayEvent>? onMarkDone;

  /// Eventos que se están marcando (el botón se desactiva mientras).
  final Set<String> completingIds;

  /// «Empezar» del entreno de hoy y abrir su rutina (tocar la fila).
  final VoidCallback? onStartTraining;
  final VoidCallback? onOpenTraining;

  /// Abre el evento de la fila en el calendario.
  final ValueChanged<HomeTodayEvent>? onOpenEvent;

  /// Abre la entrega o el examen de la cuenta atrás.
  final VoidCallback? onOpenDeadline;

  /// Lleva a la agenda de hoy («y 2 más»).
  final VoidCallback? onOpenAgenda;

  /// Otra tarjeta de arriba ya lleva el botón destacado (la sesión a
  /// medias): aquí los botones son tonales (un solo destacado por pantalla).
  final bool primaryElsewhere;

  /// Sesión a medias que se ve arriba: mientras esté, «Empezar» se desactiva
  /// y dice qué hacer antes. Nula si no hay o si se está descartando (su
  /// «Deshacer» sigue abierto): entonces «Empezar» la confirma antes.
  final HomeUnfinishedSession? blockedBy;

  final DateTime? now;

  @override
  State<TodayHeroCard> createState() => _TodayHeroCardState();
}

/// Al marcar como hecho lo de la fila, su botón desaparece: el foco pasa al
/// título de «Tu día» (WCAG 2.4.3); el aviso de abajo dice qué se marcó.
class _TodayHeroCardState extends State<TodayHeroCard> {
  final _titleFocus = FocusNode(debugLabel: 'home-today-title');

  /// Evento marcado desde aquí, hasta que llega hecho o falla.
  String? _marking;

  HomeDashboard get dashboard => widget.dashboard;

  void _markDone(HomeTodayEvent event) {
    _marking = event.id;
    widget.onMarkDone!(event);
  }

  @override
  void didUpdateWidget(TodayHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final marking = _marking;
    if (marking == null) return;
    final done = widget.dashboard.todayEvents.any(
      (e) => e.id == marking && e.completed,
    );
    if (done) {
      _marking = null;
      AppFocusAnchor.focusSoon(_titleFocus);
    } else if (!widget.completingIds.contains(marking) &&
        oldWidget.completingIds.contains(marking)) {
      // Falló: el botón sigue ahí y el aviso de error lo explica.
      _marking = null;
    }
  }

  @override
  void dispose() {
    _titleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final colors = context.colors;
    final summary = dashboard.todaySummary;
    final now = widget.now ?? DateTime.now();
    final training = widget.focus.includesFitness
        ? dashboard.trainingToday
        : null;
    final spotlight = dashboard.spotlight;
    final deadline = widget.focus.includesAcademic
        ? dashboard.nextDeadline
        : null;
    final unfinished = widget.blockedBy;
    final trainingEnabled = unfinished == null && !widget.starting;
    // Un solo botón destacado: el de «Empezar» si se puede; si no, el de la
    // fila del evento; ninguno si otra tarjeta lleva el suyo.
    final trainingPrimary = !widget.primaryElsewhere && unfinished == null;
    final eventPrimary =
        !widget.primaryElsewhere && (training == null || unfinished != null);

    // Lo demás de hoy que queda por hacer: «y 2 más» lleva a la agenda.
    final others = dashboard.othersPending(
      shownIds: {?spotlight?.id, ?deadline?.id},
      trainingShown: training != null,
    );

    final rows = <Widget>[
      if (training != null)
        _TrainingRow(
          day: training,
          intensity: dashboard.todayIntensity,
          primary: trainingPrimary,
          enabled: trainingEnabled,
          loading: widget.starting,
          onStart: widget.onStartTraining,
          onOpen: widget.onOpenTraining,
          blockedBy: unfinished,
          now: now,
        ),
      if (spotlight != null)
        _EventRow(
          event: spotlight,
          primary: eventPrimary,
          busy: widget.completingIds.contains(spotlight.id),
          onOpen: widget.onOpenEvent == null
              ? null
              : () => widget.onOpenEvent!(spotlight),
          onAction: (action) {
            if (action == TodayAction.markDone && widget.onMarkDone != null) {
              _markDone(spotlight);
            } else {
              widget.onAction(action);
            }
          },
        ),
      if (deadline != null)
        _DeadlineRow(
          deadline: deadline,
          now: now,
          onOpen: widget.onOpenDeadline,
        ),
    ];

    // Tarjeta lisa con borde, como en la maqueta: el tinte queda para los
    // avisos de arriba («Sin terminar»). Sobre surface, el texto secundario
    // llega a 4,5:1 también en oscuro.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TokensRadius.l),
        border: Border.all(color: colors.outlineVariant),
        color: colors.surface,
      ),
      padding: const EdgeInsets.all(TokensSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(titleFocus: _titleFocus, summary: summary),
          if (rows.isEmpty)
            _EmptyDay(
              summary: summary,
              primary: !widget.primaryElsewhere,
              onAdd: () => widget.onAction(TodayAction.addEvent),
            )
          else
            for (final row in rows) ...[
              const SizedBox(height: TokensSpacing.s),
              row,
            ],
          if (others > 0 && widget.onOpenAgenda != null) ...[
            const SizedBox(height: TokensSpacing.s),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                hint: l10n.homeTodayMoreHint,
                // Con forma de botón (ADR 0059), no texto de color suelto.
                child: OutlinedButton(
                  onPressed: widget.onOpenAgenda,
                  child: Text(l10n.homeTodayMore(others)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// «Tu día» con «2 de 5 hechos» y una barra fina (el lector oye la frase).
class _Header extends StatelessWidget {
  const _Header({required this.titleFocus, required this.summary});

  final FocusNode titleFocus;
  final HomeTodaySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final total = summary.total;
    final complete = total > 0 && summary.done >= total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppFocusAnchor(
                  focusNode: titleFocus,
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.homeTodayTitle,
                      style: context.textStyles.titleMedium,
                    ),
                  ),
                ),
              ),
            ),
            if (total > 0)
              Semantics(
                label: l10n.homeTodayProgressSemantics(summary.done, total),
                excludeSemantics: true,
                child: Text(
                  l10n.homeTodayDoneCount(summary.done, total),
                  style: context.textStyles.labelLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        if (total > 0) ...[
          const SizedBox(height: TokensSpacing.xs),
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TokensRadius.pill),
              child: LinearProgressIndicator(
                value: summary.done / total,
                minHeight: TokensSize.progressBar,
                color: complete
                    ? context.palette.success
                    : context.colors.primary,
                backgroundColor: context.colors.outlineVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Sin nada que nombrar hoy: lo dice y ofrece añadir algo al calendario.
class _EmptyDay extends StatelessWidget {
  const _EmptyDay({
    required this.summary,
    required this.primary,
    required this.onAdd,
  });

  final HomeTodaySummary summary;
  final bool primary;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final text = summary.state == HomeDayState.allDone
        ? l10n.homeTodayAllDone
        : l10n.homeTodayEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: TokensSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: context.textStyles.bodyLarge),
          const SizedBox(height: TokensSpacing.s),
          primary
              ? AppPrimaryButton(
                  label: l10n.plannerAddBlock,
                  icon: AppIcons.add,
                  onPressed: onAdd,
                )
              : AppSecondaryButton(
                  label: l10n.plannerAddBlock,
                  icon: const Icon(AppIcons.add),
                  onPressed: onAdd,
                ),
        ],
      ),
    );
  }
}

/// Una fila de «Tu día»: la zona que se toca (abre lo concreto) y, al lado,
/// su botón. Son hermanos, no anidados: el lector oye dos controles.
class _TodayRow extends StatelessWidget {
  const _TodayRow({
    required this.leading,
    required this.overline,
    required this.title,
    this.meta,
    this.trailing,
    this.onOpen,
    this.openHint,
    this.overlineColor,
  });

  final Widget leading;
  final String overline;
  final String title;
  final String? meta;
  final Widget? trailing;
  final VoidCallback? onOpen;
  final String? openHint;
  final Color? overlineColor;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.onSurfaceVariant;
    final large = context.largeText;
    final content = Row(
      children: [
        leading,
        const SizedBox(width: TokensSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                overline,
                maxLines: large ? 3 : 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.labelMedium?.copyWith(
                  color: overlineColor ?? muted,
                ),
              ),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.titleSmall,
              ),
              if (meta case final meta? when meta.isNotEmpty)
                Text(
                  meta,
                  maxLines: large ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall?.copyWith(color: muted),
                ),
            ],
          ),
        ),
        if (onOpen != null && (trailing == null || large))
          Icon(AppIcons.next, size: TokensSize.iconS, color: muted),
      ],
    );
    final area = AppCardTapArea(
      onTap: onOpen,
      semanticHint: openHint,
      padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xxs),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: TokensLayout.minTouchTarget,
        ),
        child: content,
      ),
    );
    final button = trailing;
    if (button == null) return area;
    // Con texto grande el botón baja a su propia línea (WCAG 1.4.4).
    if (large) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          area,
          const SizedBox(height: TokensSpacing.xs),
          button,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: area),
        const SizedBox(width: TokensSpacing.s),
        button,
      ],
    );
  }
}

/// Botón de una fila: relleno si es el destacado de la pantalla; tonal si no.
class _RowButton extends StatelessWidget {
  const _RowButton({
    required this.label,
    required this.primary,
    required this.onPressed,
    this.loading = false,
    this.semanticLabel,
  });

  final String label;
  final bool primary;
  final VoidCallback? onPressed;
  final bool loading;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final button = primary
        ? AppPrimaryButton(label: label, loading: loading, onPressed: onPressed)
        : FilledButton.tonal(onPressed: onPressed, child: Text(label));
    final semantic = semanticLabel;
    if (semantic == null || loading) return button;
    // El lector oye qué se empieza, no solo «Empezar».
    return Semantics(
      label: semantic,
      excludeSemantics: true,
      button: true,
      enabled: onPressed != null,
      onTap: onPressed,
      child: button,
    );
  }
}

/// El entreno de hoy: foto, «Entreno de hoy · suave», la sesión, «≈ 45 min ·
/// 6 ejercicios · rutina» y «Empezar». Con una sesión a medias, «Empezar» se
/// desactiva y una línea dice qué hacer antes.
class _TrainingRow extends StatelessWidget {
  const _TrainingRow({
    required this.day,
    required this.intensity,
    required this.primary,
    required this.enabled,
    required this.loading,
    required this.now,
    this.onStart,
    this.onOpen,
    this.blockedBy,
  });

  final HomeNextTrainingDay day;
  final TodayIntensity? intensity;
  final bool primary;
  final bool enabled;
  final bool loading;
  final DateTime now;
  final VoidCallback? onStart;
  final VoidCallback? onOpen;
  final HomeUnfinishedSession? blockedBy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final overline = switch (intensity) {
      null => l10n.homeTodayTrainingLabel,
      TodayIntensity.easy => l10n.homeTodayTrainingWith(
        l10n.homeTodayIntensityEasyWord,
      ),
      TodayIntensity.normal => l10n.homeTodayTrainingWith(
        l10n.homeTodayIntensityNormalWord,
      ),
      TodayIntensity.hard => l10n.homeTodayTrainingWith(
        l10n.homeTodayIntensityHardWord,
      ),
    };
    final title = day.dayName ?? weekdayName(l10n, day.dayNumber);
    final meta = [
      if (day.estimatedMinutes > 0)
        l10n.homeTodayTrainingMinutes(day.estimatedMinutes),
      if (day.exerciseCount > 0)
        l10n.homeTodayTrainingExercises(day.exerciseCount),
      day.routineName,
    ].join(' · ');
    final label = day.inProgress
        ? l10n.homeTrainingContinue
        : l10n.homeTrainingStart;
    final blocked = blockedBy;
    final row = _TodayRow(
      leading: ExerciseThumbnail(
        url: day.coverImageUrl,
        size: TokensSize.thumbnailS,
        icon: day.coverModality?.icon ?? Icons.fitness_center_rounded,
      ),
      overline: overline,
      title: title,
      meta: meta,
      onOpen: onOpen,
      openHint: l10n.homeTodayOpenRoutineHint,
      trailing: onStart == null
          ? null
          : _RowButton(
              label: label,
              primary: primary,
              loading: loading,
              onPressed: enabled ? onStart : null,
              semanticLabel: '$label: $title',
            ),
    );
    if (blocked == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        Text(
          _blockedText(context, blocked.startedAt, now),
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// «Primero guarda o descarta la del martes» (o «la de hoy»).
String _blockedText(BuildContext context, DateTime startedAt, DateTime now) {
  final l10n = context.localizations;
  return DateUtils.isSameDay(startedAt, now)
      ? l10n.homeTodayTrainingBlockedToday
      : l10n.homeTodayTrainingBlocked(
          DateFormat.EEEE(l10n.localeName).format(startedAt),
        );
}

/// La clase o el evento de ahora o siguiente: cuándo, cuál (con su
/// asignatura) y dónde (aula y profesor, si se saben).
class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.primary,
    required this.busy,
    required this.onAction,
    this.onOpen,
  });

  final HomeTodayEvent event;
  final bool primary;
  final bool busy;
  final ValueChanged<TodayAction> onAction;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final (icon, color) = homeEventVisual(context, event);
    final time = DateFormat.Hm();
    final start = event.start;
    final end = event.end;
    final (overline, overlineColor) = switch (event.status) {
      ItemTimeStatus.inProgress => (
        end == null
            ? l10n.homeTodayNow
            : l10n.homeTodayNowUntil(time.format(end)),
        context.colors.primary,
      ),
      ItemTimeStatus.missed => (
        start == null
            ? l10n.homeAgendaMissed
            : l10n.homeTodayMissedWasAt(time.format(start)),
        context.palette.warning,
      ),
      _ => (
        start == null
            ? l10n.homeTodayNext
            : l10n.homeTodayNextAt(time.format(start)),
        null,
      ),
    };
    final name = event.title.isEmpty
        ? eventTypeLabel(context, event.type)
        : readableEventTitle(event.title);
    final title = isClassEvent(event) ? l10n.homeTodayClassOf(name) : name;
    final where = [?event.place, ?event.teacher];
    final meta = where.isNotEmpty
        ? where.join(' · ')
        : [
            eventTypeLabel(context, event.type),
            if (event.subjectName case final s?
                when s.isNotEmpty && readableEventTitle(s) != name)
              s,
          ].join(' · ');
    final action = TodayAction.forEvent(event);
    return _TodayRow(
      leading: Container(
        width: TokensSize.thumbnailS,
        height: TokensSize.thumbnailS,
        decoration: BoxDecoration(
          color: color.withValues(alpha: AppPill.tintAlpha),
          borderRadius: BorderRadius.circular(TokensRadius.m),
        ),
        child: Icon(icon, color: color),
      ),
      overline: overline,
      overlineColor: overlineColor,
      title: title,
      meta: meta,
      onOpen: onOpen,
      openHint: l10n.homeTodayOpenEventHint,
      trailing: action == null
          ? null
          : _RowButton(
              label: action == TodayAction.focus
                  ? l10n.homeTodayFocus
                  : l10n.homeTodayMarkDone,
              primary: primary,
              loading: busy,
              onPressed: busy ? null : () => onAction(action),
              semanticLabel:
                  '${action == TodayAction.focus ? l10n.homeTodayFocus : l10n.homeTodayMarkDone}: $title',
            ),
    );
  }
}

/// La entrega o el examen más cercano («Examen · Cálculo · Parcial 1 · en 4
/// días»); al tocarla se abre esa entrega.
class _DeadlineRow extends StatelessWidget {
  const _DeadlineRow({required this.deadline, required this.now, this.onOpen});

  final HomeNextDeadline deadline;
  final DateTime now;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final exam = deadline.type == DeadlineType.exam;
    final days = AppDueDates.daysUntil(deadline.dueAt, now);
    final urgent = days <= AppDueDates.urgentDays;
    final color = urgent
        ? context.palette.warning
        : context.colors.onSurfaceVariant;
    final when = AppDueDates.countdown(context, deadline.dueAt, now);
    final kind = exam ? l10n.homeTodayExam : l10n.homeTodayDelivery;
    final subject = deadline.subjectName;
    return _TodayRow(
      leading: Container(
        width: TokensSize.thumbnailS,
        height: TokensSize.thumbnailS,
        decoration: BoxDecoration(
          color: color.withValues(alpha: AppPill.tintAlpha),
          borderRadius: BorderRadius.circular(TokensRadius.m),
        ),
        // Los mismos iconos que la agenda (un concepto, un icono).
        child: Icon(exam ? AppIcons.exam : AppIcons.delivery, color: color),
      ),
      overline: '$kind · $when',
      overlineColor: urgent ? color : null,
      title: deadline.title,
      meta: subject,
      onOpen: onOpen,
      openHint: l10n.homeTodayOpenDeadlineHint,
    );
  }
}
