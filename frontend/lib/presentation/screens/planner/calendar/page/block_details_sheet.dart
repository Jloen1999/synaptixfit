import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../domain/enums/item_time_status.dart';
import '../../../../../domain/enums/planner_enums.dart';
import '../../../../../domain/models/planner/calendar_block.dart';
import '../../../../../domain/models/planner/planner_week.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/planner_visuals.dart';

/// Lo que la ficha de un evento pide al calendario; la página lo resuelve
/// (casos de uso del bloc, navegación u otra hoja).
enum BlockDetailsAction {
  /// Pomodoro ligado al evento (estudio o repaso).
  focus,

  /// Abre la sesión del día de rutina (evento de hoy).
  startTraining,

  /// Lleva a la rutina (día de rutina de otro día o ya hecho).
  openRoutine,

  /// Marcar como hecho o desmarcar.
  toggleDone,

  /// «Sí fui» a una clase marcada «No fui».
  classWent,

  /// «No fui» a una clase.
  classAbsent,

  /// «Pasar a otro día» (misma hora, `showMoveDaySheet`).
  move,

  /// Eliminar, con «Deshacer».
  delete,

  /// Lápiz: el formulario de siempre (`BlockEditorSheet`).
  edit,

  /// «Abrir asignatura».
  openSubject,
}

/// Lo que se enseña de un evento en su ficha: el bloque y los nombres que
/// trae la semana (título del lienzo, asignatura y tarea de reto).
class BlockDetails {
  const BlockDetails({
    required this.block,
    required this.title,
    this.subjectName,
    this.challenge,
    this.busy = false,
  });

  final CalendarBlock block;

  /// El mismo nombre que el evento en la rejilla: se reconoce lo tocado.
  final String title;
  final String? subjectName;

  /// Reto (y tarea, si se conoce) que adelanta el evento.
  final ({String challenge, String? task})? challenge;

  /// Una acción del evento en curso (marcar, mover, abrir la sesión).
  final bool busy;

  bool get _routineDay => block.routineId != null && block.routineDayId != null;

  /// La acción que toca ahora, la única rellena de la ficha (o ninguna):
  /// concentrarse en un estudio que no ha pasado, empezar el entreno de hoy,
  /// abrir la rutina de otro día o marcar como hecho lo que ya empezó.
  BlockDetailsAction? primaryAt(DateTime now) {
    final b = block;
    if (_routineDay) {
      if (b.completed) return null;
      return PlannerWeek.isSameDay(b.start, now) &&
              b.timeStatus != ItemTimeStatus.missed
          ? BlockDetailsAction.startTraining
          : BlockDetailsAction.openRoutine;
    }
    if (b.completed || b.type == BlockType.classSession) return null;
    if (b.type.isStudy && b.timeStatus != ItemTimeStatus.missed) {
      return BlockDetailsAction.focus;
    }
    return b.timeStatus == ItemTimeStatus.upcoming
        ? null
        : BlockDetailsAction.toggleDone;
  }
}

/// Ficha de lectura de un evento del calendario (ADR 0060, maqueta «tocar
/// una tarea»): qué es, cuándo, de qué asignatura, qué reto adelanta, dónde y
/// la nota; la acción que toca, grande; debajo marcar y pasar a otro día;
/// «Eliminar» rojo y aparte, y «Editar» (con texto) que abre el formulario.
/// Se cierra con el asa, el fondo o «atrás». Se pinta con los datos que le
/// da el calendario y devuelve lo pedido.
class BlockDetailsSheet extends StatelessWidget {
  const BlockDetailsSheet({
    super.key,
    required this.details,
    required this.now,
    required this.onAction,
  });

  final BlockDetails details;
  final DateTime now;
  final ValueChanged<BlockDetailsAction> onAction;

  /// Abre la ficha. [builder] la construye con los datos del momento (así se
  /// actualiza si cambia la semana mientras está abierta); devuelve la
  /// acción elegida o nulo si se cierra sin más.
  static Future<BlockDetailsAction?> show(
    BuildContext context, {
    required Widget Function(
      BuildContext context,
      ValueChanged<BlockDetailsAction> pick,
    )
    builder,
  }) => showModalBottomSheet<BlockDetailsAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheet) =>
        builder(sheet, (action) => Navigator.of(sheet).pop(action)),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final block = details.block;
    final primary = details.primaryAt(now);
    const gap = SizedBox(height: TokensSpacing.m);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        0,
        TokensSpacing.m,
        TokensSpacing.l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(details: details, onAction: onAction),
          gap,
          // Solo la duración: el calendario no sabe si los avisos están
          // activos en este móvil, así que no promete ninguno.
          _Line(
            icon: AppIcons.duration,
            text: _when(context, block),
            detail: PlannerFormats.duration(l10n, block.duration.inMinutes),
          ),
          // Sin el nombre de la asignatura no hay nada que nombrar ni abrir.
          if (block.subjectId != null && details.subjectName != null)
            _subjectLine(context, details.subjectName!),
          if (block.challengeId != null)
            _Line(icon: AppIcons.challenge, text: _challengeText(context)),
          if (block.location?.trim().isNotEmpty ?? false)
            _Line(
              icon: AppIcons.location,
              text: block.location!.trim(),
              semanticPrefix: l10n.plannerFieldLocation,
            ),
          if (!block.type.requiresName &&
              (block.topics?.trim().isNotEmpty ?? false))
            _Line(
              icon: AppIcons.note,
              text: block.topics!.trim(),
              semanticPrefix: l10n.plannerDetailsNote,
            ),
          gap,
          if (primary != null) ...[
            AppPrimaryButton(
              label: _label(context, primary),
              icon: _icon(primary),
              loading: details.busy,
              onPressed: () => onAction(primary),
            ),
            const SizedBox(height: TokensSpacing.s),
          ],
          ..._secondary(context, primary),
        ],
      ),
    );
  }

  /// «Hoy, 19:00 – 20:00», «Mañana, …» o «Jueves, 20 de noviembre, …».
  String _when(BuildContext context, CalendarBlock block) {
    final l10n = context.localizations;
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(block.start.year, block.start.month, block.start.day);
    final days = day.difference(today).inDays;
    final dayText = switch (days) {
      0 => l10n.plannerToday,
      1 => l10n.plannerTomorrow,
      _ => toBeginningOfSentenceCase(PlannerFormats.longDate(block.start)),
    };
    return l10n.plannerDetailsWhen(
      dayText,
      l10n.plannerTimeRange(
        PlannerFormats.time(block.start),
        PlannerFormats.time(block.end),
      ),
    );
  }

  String _challengeText(BuildContext context) {
    final l10n = context.localizations;
    final c = details.challenge;
    if (c == null) return l10n.plannerDetailsChallengeUnknown;
    final task = c.task;
    return task == null
        ? l10n.plannerDetailsChallenge(c.challenge)
        : l10n.plannerDetailsChallengeTask(task, c.challenge);
  }

  /// Asignatura con «Abrir asignatura» (botón con su nombre para el lector).
  Widget _subjectLine(BuildContext context, String name) {
    final l10n = context.localizations;
    return _Line(
      icon: AppIcons.subject,
      text: name,
      trailing: Semantics(
        button: true,
        label: l10n.plannerDetailsOpenSubjectFor(name),
        excludeSemantics: true,
        onTap: () => onAction(BlockDetailsAction.openSubject),
        child: TextButton(
          onPressed: () => onAction(BlockDetailsAction.openSubject),
          child: Text(l10n.plannerDetailsOpenSubject),
        ),
      ),
    );
  }

  /// Debajo de la acción principal: lo que explica una clase, un evento que
  /// aún no empezó o por qué no se pasa a otro día; marcar o desmarcar, pasar
  /// a otro día y, aparte, eliminar.
  List<Widget> _secondary(BuildContext context, BlockDetailsAction? primary) {
    final l10n = context.localizations;
    final block = details.block;
    final busy = details.busy;
    VoidCallback? run(BlockDetailsAction a) => busy ? null : () => onAction(a);
    final upcoming =
        block.timeStatus == ItemTimeStatus.upcoming && !block.completed;
    final notes = <String>[];
    final buttons = <(String, BlockDetailsAction)>[];
    final classSession = block.type == BlockType.classSession;

    if (details._routineDay) {
      // Su estado lo marca la sesión: no se marca a mano.
      if (primary != BlockDetailsAction.openRoutine) {
        buttons.add((l10n.plannerOpenRoutine, BlockDetailsAction.openRoutine));
      }
    } else if (classSession) {
      // Las clases se dan por asistidas solas al terminar (ADR 0029).
      notes.add(
        upcoming
            ? l10n.plannerClassAttendsLater
            : block.absent
            ? l10n.plannerClassMarkedAbsent
            : block.completed
            ? l10n.plannerClassAttended
            : l10n.plannerClassAttendsByItself,
      );
      if (!upcoming && !block.completed) {
        buttons.add((l10n.plannerClassWent, BlockDetailsAction.classWent));
      }
      if (!upcoming && !block.absent) {
        buttons.add((
          l10n.plannerClassDidNotGo,
          BlockDetailsAction.classAbsent,
        ));
      }
    } else if (upcoming) {
      notes.add(l10n.plannerCompleteWhenStarted);
    } else if (primary != BlockDetailsAction.toggleDone) {
      buttons.add((
        block.completed ? l10n.plannerMarkPending : l10n.plannerMarkCompleted,
        BlockDetailsAction.toggleDone,
      ));
    }
    if (!block.isLocked && !block.completed) {
      buttons.add((l10n.plannerDetailsMove, BlockDetailsAction.move));
    } else if (block.isLocked) {
      // Dice por qué no sale «Pasar a otro día» en vez de esconderlo sin más.
      notes.add(l10n.plannerBlockLocked);
    } else if (!details._routineDay && !classSession) {
      // Lo hecho se desmarca antes de moverlo; en una clase o un día de
      // rutina no hay «Desmarcar», así que no se dice.
      notes.add(l10n.plannerCompletedLocked);
    }
    return [
      for (final note in notes) ...[
        _Note(note),
        const SizedBox(height: TokensSpacing.s),
      ],
      _ActionsRow(actions: [for (final (label, a) in buttons) (label, run(a))]),
      // Borrar va siempre en su propia línea, al final y separado de lo
      // habitual: no se pulsa por error al ir a mover o marcar.
      const SizedBox(height: TokensSpacing.l),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: _DeleteButton(onPressed: run(BlockDetailsAction.delete)),
      ),
    ];
  }

  String _label(BuildContext context, BlockDetailsAction action) {
    final l10n = context.localizations;
    return switch (action) {
      BlockDetailsAction.focus => l10n.plannerFocusOnBlock,
      BlockDetailsAction.startTraining => l10n.plannerDetailsStartTraining,
      BlockDetailsAction.openRoutine => l10n.plannerOpenRoutine,
      _ => l10n.plannerMarkCompleted,
    };
  }

  IconData _icon(BlockDetailsAction action) => switch (action) {
    BlockDetailsAction.focus => AppIcons.focusTimer,
    BlockDetailsAction.startTraining => AppIcons.start,
    BlockDetailsAction.openRoutine => AppIcons.routine,
    _ => AppIcons.markDone,
  };
}

/// Icono y pastilla del tipo, título (encabezado de la hoja), estado con
/// texto, icono y color (los mismos que en la rejilla) y «Editar» con texto,
/// desactivado mientras se hace algo. Sin «Cerrar»: la hoja se cierra con el
/// asa (también para el lector), el fondo, Esc o «atrás».
class _Header extends StatelessWidget {
  const _Header({required this.details, required this.onAction});

  final BlockDetails details;
  final ValueChanged<BlockDetailsAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final block = details.block;
    final color = block.type.color(context);
    final status = block.completed
        ? (l10n.plannerCompletedLabel, AppIcons.done, context.palette.success)
        : block.timeStatus == ItemTimeStatus.missed
        ? (l10n.plannerMissedLabel, AppIcons.overdue, context.palette.warning)
        : null;
    final icon = ExcludeSemantics(
      child: Container(
        width: TokensLayout.minTouchTarget,
        height: TokensLayout.minTouchTarget,
        decoration: BoxDecoration(
          color: color.withValues(alpha: AppPill.tintAlpha),
          shape: BoxShape.circle,
        ),
        child: Icon(block.type.icon, color: color),
      ),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: TokensSpacing.xs,
          runSpacing: TokensSpacing.xs,
          children: [
            AppPill(label: block.type.label(context)),
            if (status != null)
              AppPill(label: status.$1, icon: status.$2, color: status.$3),
            if (block.isLocked)
              AppPill(label: l10n.plannerFixedLabel, icon: AppIcons.readOnly),
          ],
        ),
        const SizedBox(height: TokensSpacing.xs),
        Semantics(
          header: true,
          child: Text(details.title, style: context.textStyles.titleLarge),
        ),
      ],
    );
    final edit = TextButton.icon(
      onPressed: details.busy ? null : () => onAction(BlockDetailsAction.edit),
      icon: const Icon(AppIcons.edit),
      label: Text(l10n.plannerDetailsEdit),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final editWidth = context.buttonWidth(
          l10n.plannerDetailsEdit,
          TextButtonTheme.of(context).style,
          icon: true,
        );
        final room =
            constraints.maxWidth -
            TokensLayout.minTouchTarget -
            TokensSpacing.m -
            editWidth;
        final head = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const SizedBox(width: TokensSpacing.m),
            Expanded(child: content),
            // Al lado solo si al título le queda al menos lo que ocupa el
            // botón; si no (móvil estrecho, texto grande), debajo.
            if (room >= editWidth) edit,
          ],
        );
        if (room >= editWidth) return head;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            head,
            Align(alignment: AlignmentDirectional.centerEnd, child: edit),
          ],
        );
      },
    );
  }
}

/// Una línea de la ficha: icono, texto y, opcional, detalle gris y un botón.
class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.text,
    this.detail,
    this.trailing,
    this.semanticPrefix,
  });

  final IconData icon;
  final String text;
  final String? detail;
  final Widget? trailing;

  /// Qué es el dato para el lector («Ubicación: Aula 2.4»): a la vista lo
  /// dice el icono.
  final String? semanticPrefix;

  @override
  Widget build(BuildContext context) {
    final prefix = semanticPrefix;
    final detail = this.detail;
    final trailing = this.trailing;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Icon(icon, color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(width: TokensSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  semanticsLabel: prefix == null ? null : '$prefix: $text',
                  style: context.textStyles.bodyLarge?.copyWith(
                    fontWeight: detail == null ? null : FontWeight.w600,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail,
                    style: context.textStyles.bodyLarge?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Explicación breve en gris (no es un aviso: no hay nada mal).
class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.textStyles.bodyLarge?.copyWith(
      color: context.colors.onSurfaceVariant,
    ),
  );
}

/// Botones con borde de la ficha: en una fila, a partes iguales, solo si
/// cada etiqueta cabe entera en su mitad (se mide con el ancho real y el
/// tamaño de texto); si no, uno debajo de otro a todo el ancho. Nunca parte
/// una palabra (WCAG 1.4.10).
class _ActionsRow extends StatelessWidget {
  const _ActionsRow({required this.actions});

  /// Etiqueta y acción (nula: desactivado) de cada botón.
  final List<(String, VoidCallback?)> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    final buttons = [
      for (final (label, onPressed) in actions)
        OutlinedButton(onPressed: onPressed, child: Text(label)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = OutlinedButtonTheme.of(context).style;
        final share =
            (constraints.maxWidth - TokensSpacing.s * (actions.length - 1)) /
            actions.length;
        final fits = actions.every(
          (a) => context.buttonWidth(a.$1, style) <= share,
        );
        if (actions.length > 1 && fits) {
          return Row(
            children: [
              for (final (i, b) in buttons.indexed) ...[
                if (i > 0) const SizedBox(width: TokensSpacing.s),
                Expanded(child: b),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, b) in buttons.indexed) ...[
              if (i > 0) const SizedBox(height: TokensSpacing.s),
              b,
            ],
          ],
        );
      },
    );
  }
}

/// «Eliminar» en rojo, con icono y texto (no solo color).
class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final error = context.colors.error;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: error,
        side: BorderSide(color: error),
      ),
      onPressed: onPressed,
      icon: const Icon(AppIcons.delete),
      label: Text(context.localizations.plannerDetailsDelete),
    );
  }
}
