import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/models/training/session.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../exercise_detail/page/exercise_how_to_sheet.dart';
import '../../widgets/exercise_thumbnail.dart';
import '../../widgets/planned_exercise_card.dart';
import '../../widgets/set_fields.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_labels.dart';
import '../bloc/live_session_bloc.dart';
import 'set_record_sheet.dart';

/// Borradores de la serie que aún no se ha marcado (clave:
/// [LiveSessionState.draftKey]). Es estado de formulario de la pantalla: no
/// existe para el bloc hasta que se marca la serie.
typedef SetDrafts = Map<String, num?>;

/// Con letra grande o pantalla baja se ahorra espacio (sin foto ni tira).
bool liveCompact(BuildContext context) =>
    MediaQuery.sizeOf(context).height < TokensLayout.compactHeight ||
    MediaQuery.textScalerOf(context).scale(1) > 1.3;

/// Lo previsto de una serie en texto corto: «10 reps · 40 kg», «30 s», «25 min».
String targetLabel(BuildContext context, PlannedExercise e, int set) {
  final l10n = context.localizations;
  final p = e.parameters;
  final fields = SetFields.of(e);
  if (fields.isCardio) {
    return plannedSummary(l10n, p.copyWith(sets: 1), fields);
  }
  final weight = p.weightForSet(set);
  final main = fields.isHold
      ? l10n.trainingSecondsUnit('${p.holdForSet(set) ?? 0}')
      : l10n.trainingSetReps(p.repsForSet(set));
  return weight != null && weight > 0
      ? l10n.trainingTargetWithWeight(main, formatNumber(weight))
      : main;
}

/// Abre «Cómo se hace» del ejercicio sin salir de la sesión.
void openHowTo(BuildContext context, PlannedExercise exercise) => unawaited(
  showExerciseHowToSheet(
    context,
    exerciseId: exercise.exerciseId,
    name: exercise.exerciseName,
    gifUrl: exercise.gifUrl,
    previewUrl: exercise.previewUrl,
  ),
);

/// Cabecera fija de la sesión: progreso («4 de 6 ejercicios · 32 min»), barra
/// de series y una tira con los ejercicios para saltar entre ellos. Con letra
/// grande la tira se cambia por «Ejercicio 2 de 6» con anterior y siguiente.
class LiveSessionHeader extends StatelessWidget {
  const LiveSessionHeader({super.key, required this.state});

  final LiveSessionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final s = state;
    final viewed = s.viewed;
    final index = s.exercises.indexOf(viewed);
    final bloc = context.read<LiveSessionBloc>();
    final progress = s.plannedSets == 0 ? 0.0 : s.loggedSets / s.plannedSets;
    void go(int i) =>
        bloc.add(LiveSessionEvent.exerciseSelected(s.exercises[i].id));
    return Material(
      color: context.colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TokensSpacing.m,
          vertical: TokensSpacing.s,
        ),
        child: TrainingContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (s.routineName != null)
                Text(
                  s.routineName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              Text(
                l10n.trainingLiveProgress(
                  s.finishedExercises,
                  s.exercises.length,
                  s.elapsedSeconds ~/ 60,
                ),
                style: context.textStyles.labelLarge,
              ),
              // Lo que queda, con la duración prevista del servidor.
              // Con el texto grande se omite: la cabecera fija ya ocupa mucho.
              if (s.remainingEstimatedMinutes case final left?
                  when left > 0 && !context.largeText)
                Text(
                  l10n.trainingRemainingMinutes(left),
                  semanticsLabel: l10n.trainingRemainingMinutesSpoken(left),
                  style: context.textStyles.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: TokensSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(TokensRadius.pill),
                child: LinearProgressIndicator(
                  value: progress,
                  color: context.colors.primary,
                  backgroundColor: context.colors.surfaceContainerHigh,
                  semanticsLabel: l10n.trainingSetsProgress(
                    s.loggedSets,
                    s.plannedSets,
                  ),
                ),
              ),
              const SizedBox(height: TokensSpacing.xs),
              if (liveCompact(context))
                Row(
                  children: [
                    IconButton(
                      tooltip: l10n.trainingLivePrevious,
                      onPressed: index <= 0 ? null : () => go(index - 1),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        l10n.trainingLiveExerciseOf(
                          index + 1,
                          s.exercises.length,
                        ),
                        textAlign: TextAlign.center,
                        style: context.textStyles.labelLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.trainingLiveNext,
                      onPressed: index >= s.exercises.length - 1
                          ? null
                          : () => go(index + 1),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                )
              else
                SizedBox(
                  height: TokensSize.listTileMin,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: s.exercises.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: TokensSpacing.xs),
                    itemBuilder: (context, i) => _StripItem(
                      exercise: s.exercises[i],
                      index: i,
                      total: s.exercises.length,
                      done: s.loggedSetsOf(s.exercises[i]),
                      selected: s.exercises[i].id == viewed.id,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StripItem extends StatelessWidget {
  const _StripItem({
    required this.exercise,
    required this.index,
    required this.total,
    required this.done,
    required this.selected,
  });

  final PlannedExercise exercise;
  final int index;
  final int total;
  final int done;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final sets = exercise.parameters.sets;
    final finished = done >= sets;
    return Semantics(
      button: true,
      selected: selected,
      label: l10n.trainingLiveStripItem(
        index + 1,
        total,
        exercise.exerciseName,
        done,
        sets,
      ),
      excludeSemantics: true,
      child: AppFocusOutline(
        borderRadius: BorderRadius.circular(TokensRadius.m),
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensRadius.m),
          onTap: () => context.read<LiveSessionBloc>().add(
            LiveSessionEvent.exerciseSelected(exercise.id),
          ),
          child: Container(
            constraints: const BoxConstraints(
              minWidth: TokensLayout.minTouchTarget,
            ),
            padding: const EdgeInsets.all(TokensSpacing.xxs),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TokensRadius.m),
              border: Border.all(
                color: selected
                    ? context.colors.primary
                    : context.colors.outlineVariant,
                width: selected
                    ? TokensSize.focusRing
                    : TokensSize.focusRing / 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ExerciseThumbnail(
                  url: exercise.thumbnailUrl,
                  size: TokensSize.thumbnailS,
                ),
                if (finished)
                  PositionedDirectional(
                    end: 0,
                    bottom: 0,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: context.palette.success,
                      size: TokensSize.iconS,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ejercicio actual en grande: foto, nombre, «La última vez» y su tabla de
/// series con lo previsto de hoy y los campos que aplican a cómo se mide.
/// Cada serie se marca con un toque; antes se pueden ajustar sus cifras.
class LiveExerciseView extends StatelessWidget {
  const LiveExerciseView({
    super.key,
    required this.state,
    required this.drafts,
    required this.invalid,
    required this.onDraft,
    required this.onValidity,
    required this.onLog,
    required this.onLoggedTap,
    required this.onExtraSet,
    this.header = const [],
  });

  final LiveSessionState state;
  final SetDrafts drafts;

  /// Celdas con un valor fuera de rango (claves de [LiveSessionState.draftKey]).
  final Set<String> invalid;

  /// Cambia lo escrito en una serie aún sin marcar.
  final void Function(PlannedExercise e, int set, SetField f, num? v) onDraft;
  final void Function(PlannedExercise e, int set, SetField f, bool valid)
  onValidity;

  /// Marca (o vuelve a guardar) una serie con estos valores.
  final void Function(PlannedExercise e, int set, Map<SetField, num?> values)
  onLog;

  /// Toque en el check de una serie ya hecha (corregir o borrar).
  final void Function(PlannedExercise e, SessionSet set) onLoggedTap;
  final void Function(PlannedExercise e, int set) onExtraSet;

  /// Avisos que van encima (sin conexión, sesión adaptada…).
  final List<Widget> header;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final s = state;
    final e = s.viewed;
    final index = s.exercises.indexOf(e);
    final fields = SetFields.of(e);
    final sets = s.session?.setsFor(e.id) ?? const <SessionSet>[];
    final maxRecorded = sets.fold(0, (m, x) => math.max(m, x.setNumber));
    final rows = math.max(e.parameters.sets, maxRecorded);
    final current = s.nextSetOf(e);
    final last = s.lastPerformance[e.exerciseId];
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        TrainingContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...header,
              if (!liveCompact(context) && e.thumbnailUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(TokensRadius.l),
                  child: Container(
                    height: TokensSize.exerciseHero,
                    color: context.colors.surfaceContainerLow,
                    child: ExcludeSemantics(
                      child: CachedNetworkImage(
                        imageUrl: e.thumbnailUrl!,
                        fit: BoxFit.contain,
                        errorWidget: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: TokensSpacing.m),
              ],
              Text(
                l10n.trainingLiveExerciseOf(index + 1, s.exercises.length),
                style: context.textStyles.labelLarge?.copyWith(
                  color: context.colors.primary,
                ),
              ),
              Semantics(
                header: true,
                child: Text(
                  e.exerciseName,
                  style: context.textStyles.headlineSmall,
                ),
              ),
              const SizedBox(height: TokensSpacing.xxs),
              Text(
                plannedSummary(l10n, e.parameters, fields),
                style: context.textStyles.titleMedium,
              ),
              if (last != null)
                // El lector leería «×» como «multiplicado por».
                Semantics(
                  label: last.weightKg == null
                      ? null
                      : l10n.trainingLastTimeWeightSpoken(
                          formatNumber(last.weightKg!),
                          last.reps,
                        ),
                  excludeSemantics: last.weightKg != null,
                  child: Text(
                    last.weightKg == null
                        ? l10n.trainingLastTimeReps(last.reps)
                        : l10n.trainingLastTimeWeight(
                            formatNumber(last.weightKg!),
                            last.reps,
                          ),
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => openHowTo(context, e),
                  icon: const Icon(Icons.ondemand_video_rounded),
                  label: Text(l10n.trainingHowTo),
                ),
              ),
              const SizedBox(height: TokensSpacing.xs),
              LayoutBuilder(
                builder: (context, constraints) {
                  final number = math.max(
                    TokensLayout.minTouchTarget,
                    context.scaled(TokensSize.iconM),
                  );
                  // Ancho que le toca a cada columna flexible en una fila:
                  // si no cabe una cifra cómoda, la serie va en dos líneas.
                  final flexUnits = 2 + 2 * fields.fields.length;
                  final perCell =
                      (constraints.maxWidth -
                          2 * number -
                          TokensSpacing.xs * (fields.fields.length + 1)) /
                      flexUnits *
                      2;
                  final stacked =
                      perCell < context.scaled(TokensSize.stepperValue);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!stacked)
                        _TableHeader(fields: fields, number: number),
                      for (var n = 1; n <= rows; n++)
                        _LiveSetRow(
                          key: ValueKey('${e.id}-$n'),
                          state: s,
                          exercise: e,
                          setNumber: n,
                          fields: fields,
                          logged: sets
                              .where((x) => x.setNumber == n)
                              .firstOrNull,
                          current: n == current,
                          stacked: stacked,
                          number: number,
                          drafts: drafts,
                          invalid: invalid,
                          onDraft: onDraft,
                          onValidity: onValidity,
                          onLog: onLog,
                          onLoggedTap: onLoggedTap,
                        ),
                    ],
                  );
                },
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  // Hasta 50 series por ejercicio (límite de la API).
                  onPressed: rows >= 50 ? null : () => onExtraSet(e, rows + 1),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.trainingExtraSet),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.fields, required this.number});

  final SetFields fields;
  final double number;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final style = context.textStyles.labelMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return ExcludeSemantics(
      child: Row(
        children: [
          SizedBox(
            width: number,
            child: Text(l10n.trainingSetColSet, style: style),
          ),
          Expanded(
            flex: 2,
            child: Text(l10n.trainingSetColTarget, style: style),
          ),
          for (final f in fields.fields) ...[
            const SizedBox(width: TokensSpacing.xs),
            Expanded(
              flex: 2,
              child: Text(
                f.header(context),
                textAlign: TextAlign.center,
                style: style,
              ),
            ),
          ],
          SizedBox(width: number),
        ],
      ),
    );
  }
}

class _LiveSetRow extends StatelessWidget {
  const _LiveSetRow({
    super.key,
    required this.state,
    required this.exercise,
    required this.setNumber,
    required this.fields,
    required this.logged,
    required this.current,
    required this.stacked,
    required this.number,
    required this.drafts,
    required this.invalid,
    required this.onDraft,
    required this.onValidity,
    required this.onLog,
    required this.onLoggedTap,
  });

  final LiveSessionState state;
  final PlannedExercise exercise;
  final int setNumber;
  final SetFields fields;
  final SessionSet? logged;

  /// Es la serie que toca: se destaca.
  final bool current;

  /// En dos líneas (letra grande o pantalla estrecha): cada cifra lleva su
  /// etiqueta encima.
  final bool stacked;
  final double number;
  final SetDrafts drafts;
  final Set<String> invalid;
  final void Function(PlannedExercise e, int set, SetField f, num? v) onDraft;
  final void Function(PlannedExercise e, int set, SetField f, bool valid)
  onValidity;
  final void Function(PlannedExercise e, int set, Map<SetField, num?> values)
  onLog;
  final void Function(PlannedExercise e, SessionSet set) onLoggedTap;

  (num, num) _range(SetField f) => f == SetField.reps ? (0, 1000) : f.range;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final e = exercise;
    final n = setNumber;
    final done = logged;
    final values = done == null
        ? state.valuesFor(e, n, drafts)
        : {for (final f in fields.fields) f: done.valueOf(f)};
    final planned = n <= e.parameters.sets;
    final badInRow = [
      for (final f in fields.fields)
        if (invalid.contains(LiveSessionState.draftKey(e.id, n, f))) f,
    ];
    final target = planned ? targetLabel(context, e, n) : l10n.trainingExtraSet;

    Widget cell(SetField f) {
      final (min, max) = _range(f);
      return AppNumberCell(
        key: ValueKey('${e.id}-$n-${f.name}'),
        value: values[f],
        emphasized: current && !stacked,
        semanticLabel: l10n.trainingSetCellSemantics(n, f.spoken(context)),
        min: min,
        max: max,
        decimal: f.decimal,
        allowEmpty: f != SetField.reps,
        hint: '–',
        invalidMessage: l10n.trainingSetFieldInvalid(
          f.spoken(context),
          formatNumber(min.toDouble()),
          formatNumber(max.toDouble()),
        ),
        onValidityChanged: (valid) => onValidity(e, n, f, valid),
        // En una serie hecha, cambiar una cifra la vuelve a guardar; en una
        // pendiente, solo cambia lo que se marcará.
        onCommitted: (v) =>
            done == null ? onDraft(e, n, f, v) : onLog(e, n, {...values, f: v}),
      );
    }

    // Un solo botón que cambia de aspecto (no de widget) para no perder el
    // foco al marcar la serie (WCAG 2.4.3).
    final check = IconButton(
      tooltip: done == null
          ? l10n.trainingMarkSetDone(n)
          : l10n.trainingSetDoneEdit(n),
      style: done == null
          ? IconButton.styleFrom(
              side: BorderSide(color: context.colors.outline),
            )
          : IconButton.styleFrom(
              backgroundColor: done.completed
                  ? context.palette.success
                  : context.palette.warning,
              foregroundColor: context.colors.onPrimary,
            ),
      onPressed: done != null
          ? () => onLoggedTap(e, done)
          : state.saving || badInRow.isNotEmpty
          ? null
          : () {
              SemanticsService.sendAnnouncement(
                View.of(context),
                l10n.trainingSetLogged(n),
                Directionality.of(context),
              );
              onLog(e, n, values);
            },
      icon: Icon(
        done == null || done.completed
            ? Icons.check_rounded
            : Icons.cancel_rounded,
      ),
    );

    final numberText = Text(
      '$n',
      style:
          (current
                  ? context.textStyles.titleLarge
                  : context.textStyles.titleMedium)
              ?.copyWith(color: current ? context.colors.primary : null),
    );
    final targetText = Text(
      target,
      style: context.textStyles.bodySmall?.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    );
    final Widget body;
    if (stacked) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.trainingSetWithTarget(n, target),
            style: context.textStyles.titleSmall?.copyWith(
              color: current ? context.colors.primary : null,
            ),
          ),
          const SizedBox(height: TokensSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final f in fields.fields) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          f.header(context),
                          style: context.textStyles.labelMedium,
                        ),
                      ),
                      cell(f),
                    ],
                  ),
                ),
                const SizedBox(width: TokensSpacing.xs),
              ],
              check,
            ],
          ),
        ],
      );
    } else {
      body = Row(
        children: [
          SizedBox(width: number, child: numberText),
          Expanded(flex: 2, child: targetText),
          for (final f in fields.fields) ...[
            const SizedBox(width: TokensSpacing.xs),
            Expanded(flex: 2, child: cell(f)),
          ],
          SizedBox(
            width: number,
            child: Center(child: check),
          ),
        ],
      );
    }
    return Semantics(
      container: true,
      label: current ? l10n.trainingCurrentSet : null,
      child: Container(
        margin: const EdgeInsets.only(top: TokensSpacing.xs),
        padding: const EdgeInsets.all(TokensSpacing.xs),
        // La serie que toca: fondo y borde de color (el fondo solo apenas se
        // distingue del lienzo en claro).
        decoration: current
            ? BoxDecoration(
                color: context.colors.primaryContainer,
                border: Border.all(
                  color: context.colors.primary,
                  width: TokensSize.focusRing,
                ),
                borderRadius: BorderRadius.circular(TokensRadius.m),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            body,
            for (final f in badInRow)
              Padding(
                padding: const EdgeInsets.only(top: TokensSpacing.xxs),
                child: Text(
                  l10n.trainingSetFieldInvalidInSet(
                    n,
                    f.spoken(context),
                    formatNumber(_range(f).$1.toDouble()),
                    formatNumber(_range(f).$2.toDouble()),
                  ),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Barra inferior de la sesión. Descansando: cuenta atrás grande con −15 s,
/// +15 s y «Saltar». Si no: qué toca ahora y el siguiente ejercicio, con la
/// acción principal al alcance del pulgar (marcar la serie, ir al siguiente o
/// terminar). Al cambiar de una a otra el foco pasa a la acción nueva.
class LiveSessionBottomBar extends StatefulWidget {
  const LiveSessionBottomBar({
    super.key,
    required this.state,
    required this.drafts,
    required this.invalid,
    required this.onLog,
    required this.onFinish,
  });

  final LiveSessionState state;
  final SetDrafts drafts;
  final Set<String> invalid;
  final void Function(PlannedExercise e, int set, Map<SetField, num?> values)
  onLog;
  final VoidCallback? onFinish;

  @override
  State<LiveSessionBottomBar> createState() => _LiveSessionBottomBarState();
}

class _LiveSessionBottomBarState extends State<LiveSessionBottomBar> {
  final _actionFocus = FocusNode();
  final _skipFocus = FocusNode();

  @override
  void didUpdateWidget(LiveSessionBottomBar old) {
    super.didUpdateWidget(old);
    final wasResting = old.state.restRemaining != null;
    final resting = widget.state.restRemaining != null;
    if (wasResting == resting) return;
    final hadFocus = wasResting ? _skipFocus.hasFocus : _actionFocus.hasFocus;
    if (!hadFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) (resting ? _skipFocus : _actionFocus).requestFocus();
    });
  }

  @override
  void dispose() {
    _actionFocus.dispose();
    _skipFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final resting = s.restRemaining != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: resting
            ? context.colors.secondaryContainer
            : context.colors.surfaceContainerLow,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        // Con letra muy grande la barra no tapa la tabla: ocupa como mucho
        // el 40 % de la altura y su contenido se desplaza.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.4,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TokensSpacing.m),
            child: TrainingContent(
              child: resting
                  ? _RestPanel(state: s, skipFocus: _skipFocus)
                  : _NextPanel(
                      state: s,
                      drafts: widget.drafts,
                      invalid: widget.invalid,
                      onLog: widget.onLog,
                      onFinish: widget.onFinish,
                      focus: _actionFocus,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NextPanel extends StatelessWidget {
  const _NextPanel({
    required this.state,
    required this.drafts,
    required this.invalid,
    required this.onLog,
    required this.onFinish,
    required this.focus,
  });

  final LiveSessionState state;
  final SetDrafts drafts;
  final Set<String> invalid;
  final void Function(PlannedExercise e, int set, Map<SetField, num?> values)
  onLog;
  final VoidCallback? onFinish;
  final FocusNode focus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final s = state;
    final viewed = s.viewed;
    final set = s.nextSetOf(viewed);
    final up = s.upNext;
    final index = s.exercises.indexOf(viewed);
    // Siguiente ejercicio (siempre a la vista): el que toca si no es este, o
    // el siguiente con series por hacer.
    final following = up != null && up.id != viewed.id
        ? up
        : s.exercises
              .skip(index + 1)
              .where((e) => s.nextSetOf(e) != null)
              .firstOrNull;
    final bloc = context.read<LiveSessionBloc>();
    final Widget action;
    if (set != null) {
      final rowInvalid = SetFields.of(viewed).fields.any(
        (f) => invalid.contains(LiveSessionState.draftKey(viewed.id, set, f)),
      );
      action = AppPrimaryButton(
        label: l10n.trainingLiveSetDone(set),
        icon: Icons.check_rounded,
        focusNode: focus,
        onPressed: s.saving || rowInvalid
            ? null
            : () {
                SemanticsService.sendAnnouncement(
                  View.of(context),
                  l10n.trainingSetLogged(set),
                  Directionality.of(context),
                );
                onLog(viewed, set, s.valuesFor(viewed, set, drafts));
              },
      );
    } else if (following != null) {
      action = AppPrimaryButton(
        label: l10n.trainingLiveGoTo(following.exerciseName),
        icon: Icons.arrow_forward_rounded,
        focusNode: focus,
        onPressed: () =>
            bloc.add(LiveSessionEvent.exerciseSelected(following.id)),
      );
    } else {
      action = AppPrimaryButton(
        label: l10n.trainingFinishAction,
        icon: Icons.flag_rounded,
        loading: s.finishing,
        focusNode: focus,
        onPressed: onFinish,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (set != null)
          Text(
            l10n.trainingLiveNow(
              l10n.trainingUpNextSet(set, viewed.parameters.sets),
              targetLabel(context, viewed, set),
            ),
            style: context.textStyles.titleSmall,
          )
        else if (following == null)
          Text(
            l10n.trainingAllSetsDone,
            style: context.textStyles.titleSmall?.copyWith(
              color: context.palette.success,
            ),
          ),
        if (following != null)
          Text(
            l10n.trainingLiveNextExercise(following.exerciseName),
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: TokensSpacing.s),
        action,
      ],
    );
  }
}

class _RestPanel extends StatelessWidget {
  const _RestPanel({required this.state, required this.skipFocus});

  final LiveSessionState state;
  final FocusNode skipFocus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<LiveSessionBloc>();
    final s = state;
    final remaining = s.restRemaining ?? 0;
    final progress = s.restTotal == 0 ? 0.0 : remaining / s.restTotal;
    final onColor = context.colors.onSecondaryContainer;
    final up = s.upNext ?? s.viewed;
    final next = s.nextSetOf(up);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ExcludeSemantics(
              child: SizedBox.square(
                dimension: TokensSize.heroRing,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: TokensSize.progressBar,
                  color: context.colors.primary,
                  backgroundColor: context.colors.surface,
                ),
              ),
            ),
            const SizedBox(width: TokensSpacing.m),
            // Sin región viva: cambiaría cada segundo y el lector no pararía
            // de hablar. Se anuncia al empezar, a los 10 s y al terminar.
            Expanded(
              child: Semantics(
                label: l10n.trainingRestSemantics(remaining),
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.trainingRest,
                      style: context.textStyles.labelLarge?.copyWith(
                        color: onColor,
                      ),
                    ),
                    Text(
                      formatClock(remaining),
                      style: context.textStyles.displaySmall?.copyWith(
                        color: onColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (next != null) ...[
          const SizedBox(height: TokensSpacing.xs),
          Text(
            l10n.trainingLiveAfterRest(
              up.exerciseName,
              next,
              targetLabel(context, up, next),
            ),
            style: context.textStyles.bodyMedium?.copyWith(color: onColor),
          ),
        ],
        const SizedBox(height: TokensSpacing.s),
        Wrap(
          spacing: TokensSpacing.s,
          runSpacing: TokensSpacing.s,
          alignment: WrapAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () =>
                  bloc.add(const LiveSessionEvent.restAdjusted(-15)),
              child: Semantics(
                label: l10n.trainingRestLess,
                excludeSemantics: true,
                child: Text(l10n.trainingRestMinus15),
              ),
            ),
            OutlinedButton(
              onPressed: () =>
                  bloc.add(const LiveSessionEvent.restAdjusted(15)),
              child: Semantics(
                label: l10n.trainingRestMore,
                excludeSemantics: true,
                child: Text(l10n.trainingRestPlus15),
              ),
            ),
            FilledButton(
              focusNode: skipFocus,
              onPressed: () => bloc.add(const LiveSessionEvent.restSkipped()),
              child: Text(l10n.trainingSkip),
            ),
          ],
        ),
      ],
    );
  }
}

/// Toque en una serie ya hecha. En ejercicios de repeticiones abre la hoja
/// (corregir, repeticiones fallidas o borrar); en los de tiempo o distancia,
/// las cifras ya se corrigen en la fila y solo queda desmarcarla.
Future<void> onLoggedSetTap(
  BuildContext context,
  PlannedExercise e,
  SessionSet set,
) async {
  final bloc = context.read<LiveSessionBloc>();
  final l10n = context.localizations;
  final fields = SetFields.of(e);
  if (fields.has(SetField.reps)) {
    final result = await showSetRecordSheet(
      context,
      title: e.exerciseName,
      existingSetId: set.id,
      initial: SetRecord(
        plannedExerciseId: e.id,
        setNumber: set.setNumber,
        repsDone: set.repsDone,
        weightKg: set.weightKg,
        completed: set.completed,
        failedReps: set.failedReps,
      ),
    );
    if (result == null || bloc.isClosed) return;
    switch (result) {
      case SetSheetSave(:final record):
        bloc.add(LiveSessionEvent.setRecorded(record));
      case SetSheetDelete(:final setId):
        bloc.add(LiveSessionEvent.setDeleted(setId));
    }
    return;
  }
  final ok = await showConfirmDialog(
    context,
    title: l10n.trainingUnmarkSetTitle(set.setNumber),
    message: l10n.trainingUnmarkSetMessage,
    confirmLabel: l10n.trainingDeleteSet,
  );
  if (ok && !bloc.isClosed) bloc.add(LiveSessionEvent.setDeleted(set.id));
}
