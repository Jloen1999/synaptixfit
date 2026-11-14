import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/models/training/load_suggestion.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/models/training/session.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../l10n/gen_l10n/app_localizations.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../exercise_detail/page/exercise_how_to_sheet.dart';
import '../../widgets/exercise_thumbnail.dart';
import '../../widgets/planned_exercise_card.dart';
import '../../widgets/set_fields.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_labels.dart';
import '../bloc/live_session_bloc.dart';

/// Borradores de la serie que aún no se ha marcado (clave:
/// [LiveSessionState.draftKey]). Es estado de formulario de la pantalla: no
/// existe para el bloc hasta que se marca la serie.
typedef SetDrafts = Map<String, num?>;

/// Con letra grande o pantalla baja se ahorra espacio (sin foto ni tira).
bool liveCompact(BuildContext context) =>
    MediaQuery.sizeOf(context).height < TokensLayout.compactHeight ||
    context.largeText;

/// Una serie en texto corto: «10 reps · 40 kg», «30 s», «25 min». Sin
/// [values], lo previsto en la rutina; con ellos, las cifras de partida de hoy
/// (las mismas que trae la fila, para que no haya dos números que compitan).
/// Con [withWeight] falso solo va la cifra principal (la columna «Objetivo»
/// de la fila, que ya tiene su casilla de kilos al lado).
String targetLabel(
  BuildContext context,
  PlannedExercise e,
  int set, {
  Map<SetField, num?>? values,
  bool withWeight = true,
}) {
  final l10n = context.localizations;
  final p = e.parameters;
  final fields = SetFields.of(e);
  if (fields.isCardio) {
    return plannedSummary(l10n, p.copyWith(sets: 1), fields);
  }
  final num? weight = values != null
      ? values[SetField.weight]
      : p.weightForSet(set);
  final hold = values?[SetField.hold] ?? p.holdForSet(set) ?? 0;
  final reps = values?[SetField.reps] ?? p.repsForSet(set);
  final main = fields.isHold
      ? l10n.trainingSecondsUnit(formatNumber(hold.toDouble()))
      : l10n.trainingSetReps(reps.toInt());
  return withWeight && weight != null && weight > 0
      ? l10n.trainingTargetWithWeight(main, formatNumber(weight.toDouble()))
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
              LiveClockSummary(
                state: s,
                leading: Text(
                  l10n.trainingLiveExercisesProgress(
                    s.finishedExercises,
                    s.exercises.length,
                  ),
                  style: context.textStyles.labelLarge,
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
    required this.onUnmark,
    required this.onCorrect,
    required this.onExtraSet,
    this.onSwap,
    this.onUnswap,
    this.onWarmup,
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

  /// ✓ de una serie ya hecha: la desmarca al momento (con «Deshacer»).
  final void Function(PlannedExercise e, SessionSet set) onUnmark;

  /// Toque en la fila de una serie hecha (fuera del ✓): corregirla.
  final void Function(PlannedExercise e, SessionSet set) onCorrect;
  final void Function(PlannedExercise e, int set) onExtraSet;

  /// «Cambiar solo hoy» y «Volver al de la rutina» (ADR 0031).
  final void Function(PlannedExercise e)? onSwap;
  final void Function(PlannedExercise e)? onUnswap;

  /// Apuntar (o corregir, con [existing]) la serie de calentamiento [set].
  final void Function(PlannedExercise e, int set, SessionSet? existing)?
  onWarmup;

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
    final load = current == null ? null : s.loadSuggestions[e.id];
    final original = s.originals[e.id];
    final warmups = s.session?.warmupSetsFor(e.id) ?? const <SessionSet>[];
    // Calentamiento: en ejercicios de repeticiones, mientras no se empiece el
    // trabajo (o si ya hay alguno apuntado, para poder corregirlo).
    final showWarmup =
        onWarmup != null &&
        fields.has(SetField.reps) &&
        (sets.isEmpty || warmups.isNotEmpty);
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
              // Sin kilos: la cifra de partida va en la fila (y la propuesta,
              // debajo); el peso de la rutina no compite con ella.
              Text(
                plannedSummary(
                  l10n,
                  e.parameters.copyWith(weightKg: null, weightsKg: null),
                  fields,
                ),
                style: context.textStyles.titleMedium,
              ),
              // La propuesta de hoy ya sale de la última vez: si la hay, va
              // ella sola.
              if (load != null)
                LoadSuggestionLine(suggestion: load)
              else if (last != null)
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
              if (original != null) ...[
                const SizedBox(height: TokensSpacing.s),
                _SwappedNote(
                  original: original,
                  onUndo: onUnswap == null ? null : () => onUnswap!(e),
                ),
              ],
              Wrap(
                spacing: TokensSpacing.xs,
                children: [
                  TextButton.icon(
                    onPressed: () => openHowTo(context, e),
                    icon: const Icon(AppIcons.howTo),
                    label: Text(l10n.trainingHowTo),
                  ),
                  if (onSwap != null && original == null)
                    TextButton.icon(
                      onPressed: () => onSwap!(e),
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: Text(l10n.trainingSwapTodayAction),
                    ),
                ],
              ),
              if (showWarmup)
                _WarmupSection(exercise: e, sets: warmups, onWarmup: onWarmup!),
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
                          onUnmark: onUnmark,
                          onCorrect: onCorrect,
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
                  icon: const Icon(AppIcons.add),
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

/// «Solo hoy haces X en lugar de Y»: el ejercicio se cambió solo para esta
/// sesión (la rutina no cambia) y se puede volver al de la rutina.
class _SwappedNote extends StatelessWidget {
  const _SwappedNote({required this.original, required this.onUndo});

  final PlannedExercise original;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AppCard(
      color: context.colors.secondaryContainer,
      padding: const EdgeInsets.all(TokensSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                size: TokensSize.iconS,
                color: context.colors.onSecondaryContainer,
              ),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                child: Text(
                  l10n.trainingSwapTodayNote(original.exerciseName),
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          if (onUndo != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: onUndo,
                child: Text(l10n.trainingSwapTodayUndo),
              ),
            ),
        ],
      ),
    );
  }
}

/// Series de calentamiento (aproximación) de un ejercicio: aparte de las de
/// trabajo y con su propia numeración. No cuentan como series ni para la
/// propuesta de peso (ADR 0031); se explica en una línea.
class _WarmupSection extends StatelessWidget {
  const _WarmupSection({
    required this.exercise,
    required this.sets,
    required this.onWarmup,
  });

  final PlannedExercise exercise;
  final List<SessionSet> sets;
  final void Function(PlannedExercise e, int set, SessionSet? existing)
  onWarmup;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final next = sets.fold(0, (m, x) => math.max(m, x.setNumber)) + 1;
    return Padding(
      padding: const EdgeInsets.only(top: TokensSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHelpToggle(
            tooltip: l10n.commonHelpAbout(l10n.trainingWarmupSetsTitle),
            help: l10n.trainingWarmupSetsHint,
            child: Semantics(
              header: true,
              child: Text(
                l10n.trainingWarmupSetsTitle,
                style: context.textStyles.titleSmall,
              ),
            ),
          ),
          for (final w in sets)
            AppFocusOutline(
              borderRadius: BorderRadius.circular(TokensRadius.s),
              child: InkWell(
                borderRadius: BorderRadius.circular(TokensRadius.s),
                onTap: () => onWarmup(exercise, w.setNumber, w),
                // Botón con su acción: «Corregir» (el lápiz es decorativo).
                child: Semantics(
                  button: true,
                  hint: l10n.trainingWarmupSetFix,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: TokensLayout.minTouchTarget,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.whatshot_rounded,
                          size: TokensSize.iconS,
                          color: context.colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: TokensSpacing.s),
                        Expanded(
                          child: Text(
                            [
                              l10n.trainingWarmupSetNumber(w.setNumber),
                              if (w.weightKg != null)
                                l10n.trainingChipWeight(
                                  formatNumber(w.weightKg!),
                                ),
                              if (w.repsDone != null)
                                l10n.trainingSetReps(w.repsDone!),
                            ].join(' · '),
                            style: context.textStyles.bodyMedium,
                          ),
                        ),
                        ExcludeSemantics(
                          child: Icon(
                            AppIcons.edit,
                            size: TokensSize.iconXs,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: next > 50
                  ? null
                  : () => onWarmup(exercise, next, null),
              icon: const Icon(AppIcons.add),
              label: Text(l10n.trainingWarmupAdd),
            ),
          ),
        ],
      ),
    );
  }
}

/// «Hoy prueba 42,5 kg (+5 %)»: una línea con la propuesta de carga del
/// servidor, que ya va en las cifras de partida de las series que faltan (no
/// hay que aceptarla). El porqué, en un «?» opcional. No toca la rutina.
class LoadSuggestionLine extends StatelessWidget {
  const LoadSuggestionLine({super.key, required this.suggestion});

  final LoadSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final l = suggestion;
    final value = loadValueLabel(l10n, l.metric, l.suggested);
    final previous = loadValueLabel(l10n, l.metric, l.previous);
    // El porcentaje aclara en cargas; en repeticiones basta la cifra.
    final percent = l.metric == LoadMetric.reps ? null : l.changePercent?.abs();
    final title = switch ((l.increases, percent)) {
      (true, null) => l10n.trainingLoadUp(value),
      (false, null) => l10n.trainingLoadDown(value),
      (true, final int p) => l10n.trainingLoadUpPercent(value, p),
      (false, final int p) => l10n.trainingLoadDownPercent(value, p),
    };
    final spoken = percent == null
        ? title
        : l.increases
        ? l10n.trainingLoadUpSpoken(value, percent)
        : l10n.trainingLoadDownSpoken(value, percent);
    final why = switch (l.reason) {
      AdjustmentReason.failedReps => l10n.trainingLoadWhyFailed(previous),
      AdjustmentReason.veryHighRpe => l10n.trainingLoadWhyVeryHighRpe(
        previous,
        l.lastRpe,
      ),
      AdjustmentReason.veryLowRpe => l10n.trainingLoadWhyVeryLowRpe(
        previous,
        l.lastRpe,
      ),
      AdjustmentReason.lowRpeMoreReps ||
      AdjustmentReason.lowRpeMoreWeight ||
      AdjustmentReason.lowRpeMoreTime ||
      AdjustmentReason.lowRpeMoreDistance => l10n.trainingLoadWhyLowRpe(
        previous,
        l.lastRpe,
      ),
      _ => l10n.trainingLoadWhyOther(previous, l.lastRpe),
    };
    final color = context.colors.onSurfaceVariant;
    return AppHelpToggle(
      tooltip: l10n.trainingLoadWhyTooltip,
      help: '$why ${l10n.trainingLoadScope}',
      child: Row(
        children: [
          Icon(
            l.increases
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            size: TokensSize.iconXs,
            color: color,
          ),
          const SizedBox(width: TokensSpacing.xs),
          Flexible(
            child: Text(
              title,
              semanticsLabel: spoken,
              style: context.textStyles.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cifra de una propuesta de carga con su unidad («42,5 kg», «11 repeticiones»).
String loadValueLabel(AppLocalizations l10n, LoadMetric metric, double v) =>
    switch (metric) {
      LoadMetric.weight => l10n.trainingLoadKg(v),
      LoadMetric.reps => l10n.trainingLoadReps(v.round()),
      LoadMetric.holdSeconds => l10n.trainingLoadHold(v.round()),
      // Por debajo de 2 min, en segundos: «1 min» para 80 s engañaría.
      LoadMetric.durationSeconds =>
        v < 120
            ? l10n.trainingLoadSeconds(v.round())
            : l10n.trainingLoadMinutes((v / 60).round()),
      LoadMetric.distanceMeters => l10n.trainingLoadMeters(v.round()),
    };

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
    required this.onUnmark,
    required this.onCorrect,
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
  final void Function(PlannedExercise e, SessionSet set) onUnmark;
  final void Function(PlannedExercise e, SessionSet set) onCorrect;

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
    // La columna «Objetivo» lleva solo la cifra principal: los kilos de partida
    // ya están en su casilla (un solo número, sin competir).
    final target = planned
        ? targetLabel(context, e, n, withWeight: !fields.has(SetField.weight))
        : l10n.trainingExtraSet;

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
    // foco al marcar la serie (WCAG 2.4.3). En una serie hecha, volver a
    // tocarlo la desmarca al momento (con «Deshacer», como Hevy o Strong).
    final check = IconButton(
      tooltip: done == null
          ? l10n.trainingMarkSetDone(n)
          : l10n.trainingUnmarkSetNumber(n),
      style: done == null
          ? IconButton.styleFrom(
              side: BorderSide(color: context.colors.outline),
            ).copyWith(
              side: WidgetStateProperty.resolveWith(
                (states) => BorderSide(
                  color: states.contains(WidgetState.focused)
                      ? context.colors.onSurface
                      : context.colors.outline,
                  width: states.contains(WidgetState.focused)
                      ? TokensSize.focusRing
                      : TokensSize.focusRing / 2,
                ),
              ),
            )
          : IconButton.styleFrom(
              backgroundColor: done.completed
                  ? context.palette.success
                  : context.palette.warning,
              // Su «on» propio: con onPrimary el ✓ no llegaba a AA en oscuro.
              foregroundColor: done.completed
                  ? context.palette.onSuccess
                  : context.palette.onWarning,
            ),
      onPressed: done != null
          ? () => onUnmark(e, done)
          : state.saving || badInRow.isNotEmpty
          ? null
          : () => onLog(e, n, values),
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
    final timed = state.timerOn(e, n) && done == null;
    final timerPaused = timed && state.timerSince == null;
    // Estado de la serie cronometrada en icono y texto, no solo en color.
    final statusColor = timerPaused
        ? context.palette.warning
        : context.colors.primary;
    final status = timed
        ? Padding(
            padding: const EdgeInsets.only(bottom: TokensSpacing.xxs),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Icon(
                    timerPaused
                        ? Icons.pause_circle_rounded
                        : Icons.timer_outlined,
                    size: TokensSize.iconXs,
                    color: statusColor,
                  ),
                  const SizedBox(width: TokensSpacing.xs),
                  Expanded(
                    child: Text(
                      timerPaused
                          ? l10n.trainingSetRowPaused
                          : l10n.trainingSetRowRunning(
                              formatClock(state.timerSeconds),
                            ),
                      style: context.textStyles.labelMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : null;
    return Semantics(
      container: true,
      label: timed
          ? (timerPaused
                ? l10n.trainingSetTimerPaused(n)
                : l10n.trainingSetTimerRunning(n))
          : current
          ? l10n.trainingCurrentSet
          : null,
      // El margen va fuera del brillo: así el halo rodea la fila y no se
      // desplaza hacia arriba.
      child: Padding(
        padding: const EdgeInsets.only(top: TokensSpacing.xs),
        child: _SetFocusPulse(
          // Late solo mientras corre el cronómetro de esta serie: así se ve de
          // un vistazo por dónde vas.
          active: timed && !timerPaused,
          child: Container(
            padding: const EdgeInsets.all(TokensSpacing.xs),
            // La serie que toca: fondo y borde de color (el fondo solo apenas se
            // distingue del lienzo en claro). En pausa, borde de aviso.
            decoration: current || timed
                ? BoxDecoration(
                    // Tinte opaco: el texto de la fila mantiene su contraste.
                    color: timerPaused
                        ? Color.alphaBlend(
                            context.palette.warning.withValues(
                              alpha: AppPill.tintAlpha,
                            ),
                            context.colors.surface,
                          )
                        : context.colors.primaryContainer,
                    border: Border.all(
                      color: timerPaused
                          ? context.palette.warning
                          : context.colors.primary,
                      width: TokensSize.focusRing,
                    ),
                    borderRadius: BorderRadius.circular(TokensRadius.m),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?status,
                // Serie hecha: tocar la fila (fuera del ✓ y de las cifras)
                // abre la hoja para corregirla.
                if (done == null)
                  body
                else
                  Semantics(
                    button: true,
                    hint: l10n.trainingSetFix(n),
                    child: AppFocusOutline(
                      borderRadius: BorderRadius.circular(TokensRadius.s),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(TokensRadius.s),
                        onTap: () => onCorrect(e, done),
                        child: body,
                      ),
                    ),
                  ),
                if (done?.toFailure ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: TokensSpacing.xxs),
                    child: Row(
                      children: [
                        Icon(
                          Icons.trending_flat_rounded,
                          size: TokensSize.iconXs,
                          color: context.colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: TokensSpacing.xxs),
                        Flexible(
                          child: Text(
                            l10n.trainingToFailureMark,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (done?.activeSeconds case final secs?)
                  Padding(
                    padding: const EdgeInsets.only(top: TokensSpacing.xxs),
                    child: Text(
                      l10n.trainingSetActiveTime(formatClock(secs)),
                      semanticsLabel: l10n.trainingSetActiveTime(
                        spokenClock(l10n, secs),
                      ),
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
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
        ),
      ),
    );
  }
}

/// Brillo que late alrededor de la serie que se está haciendo. Con «reducir
/// movimiento» del sistema queda quieto (el borde de color ya la señala).
class _SetFocusPulse extends StatefulWidget {
  const _SetFocusPulse({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_SetFocusPulse> createState() => _SetFocusPulseState();
}

class _SetFocusPulseState extends State<_SetFocusPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: TokensDuration.pulse,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_SetFocusPulse old) {
    super.didUpdateWidget(old);
    _sync();
  }

  /// Ya latió para esta serie en marcha: no vuelve a empezar hasta pausar.
  bool _pulsed = false;

  void _sync() {
    final animate = widget.active && !context.reduceMotion;
    if (animate && !_pulsed) {
      // Late unas veces y se queda quieto: un brillo que no para distrae y
      // va contra WCAG 2.2.2; el borde ya marca la serie en marcha.
      _pulsed = true;
      unawaited(
        _controller.repeat(count: 4).whenComplete(() {
          if (mounted) _controller.value = 0;
        }),
      );
    } else if (!animate) {
      _pulsed = false;
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    final color = context.colors.primary;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TokensRadius.m),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: (1 - t) * TokensOpacity.glow),
                spreadRadius: t * TokensSpacing.s,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

/// Cronómetro de la sesión, igual en la de rutina ([LiveSessionHeader]) y en
/// la libre: la píldora, qué mide (también tras «No volver a explicarlo») y lo
/// que queda según la duración prevista del servidor (gris: es una estimación).
class LiveClockSummary extends StatelessWidget {
  const LiveClockSummary({super.key, required this.state, this.leading});

  final LiveSessionState state;

  /// Lo que va a la izquierda de la píldora (en la rutina, el avance).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final hintStyle = context.textStyles.labelMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: TokensSpacing.s,
          runSpacing: TokensSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            ?leading,
            LiveClockPill(seconds: state.elapsedSeconds, paused: state.paused),
          ],
        ),
        Wrap(
          spacing: TokensSpacing.s,
          children: [
            // El lector ya lo oye en la píldora.
            ExcludeSemantics(
              child: Text(l10n.trainingClockRealHint, style: hintStyle),
            ),
            if (state.remainingEstimatedMinutes case final left? when left > 0)
              Text(
                l10n.trainingRemainingMinutes(left),
                semanticsLabel: l10n.trainingRemainingMinutesSpoken(left),
                style: hintStyle,
              ),
          ],
        ),
      ],
    );
  }
}

/// Tiempo real de la sesión (sin pausas): píldora naranja con icono de
/// cronómetro y un punto que late dos veces al empezar o reanudar y se queda
/// fijo (WCAG 2.2.2); en pausa, ámbar y quieta. Se distingue de «Quedan ≈ N
/// min», que es una estimación en gris.
class LiveClockPill extends StatefulWidget {
  const LiveClockPill({super.key, required this.seconds, required this.paused});

  final int seconds;
  final bool paused;

  @override
  State<LiveClockPill> createState() => _LiveClockPillState();
}

class _LiveClockPillState extends State<LiveClockPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: TokensDuration.pulse,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LiveClockPill old) {
    super.didUpdateWidget(old);
    _sync();
  }

  /// Si estaba en pausa la última vez (nulo: aún no se ha pintado).
  bool? _wasPaused;

  void _sync() {
    final paused = widget.paused;
    final starting = !paused && _wasPaused != false;
    _wasPaused = paused;
    if (paused || context.reduceMotion) {
      _blink
        ..stop()
        ..value = 0;
    } else if (starting) {
      // Dos latidos (ida y vuelta cada uno) y se queda fijo.
      unawaited(_blink.repeat(reverse: true, count: 4));
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final clock = formatClock(widget.seconds);
    final paused = widget.paused;
    final foreground = paused
        ? context.palette.warning
        : context.palette.onAccentContainer;
    // Tinte opaco sobre la superficie, como [AppPill]: el contraste es el
    // mismo esté sobre la cabecera o sobre el fondo (contrast_test).
    final background = paused
        ? Color.alphaBlend(
            context.palette.warning.withValues(alpha: AppPill.tintAlpha),
            context.colors.surface,
          )
        : context.palette.accentContainer;
    final spoken = spokenClock(l10n, widget.seconds);
    return Semantics(
      label: paused
          ? l10n.trainingClockPausedSpoken(spoken)
          : l10n.trainingClockSpoken(spoken),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(TokensRadius.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TokensSpacing.s,
            vertical: TokensSpacing.xxs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: Tween<double>(
                  begin: 1,
                  end: TokensOpacity.blinkMin,
                ).animate(_blink),
                child: Icon(
                  paused ? Icons.pause_rounded : Icons.circle,
                  size: paused ? TokensSize.iconXs : TokensSize.liveDot,
                  color: paused ? foreground : context.palette.accent,
                ),
              ),
              const SizedBox(width: TokensSpacing.xs),
              Icon(
                Icons.timer_outlined,
                size: TokensSize.iconXs,
                color: foreground,
              ),
              const SizedBox(width: TokensSpacing.xxs),
              Text(
                clock,
                style: context.textStyles.titleSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
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

  /// Agrupa todo lo de la barra: si el foco estaba en cualquiera de sus
  /// botones (también «Deshacer» o −15 s), pasa a la acción del panel nuevo.
  final _barFocus = FocusNode(skipTraversal: true, canRequestFocus: false);

  @override
  void didUpdateWidget(LiveSessionBottomBar old) {
    super.didUpdateWidget(old);
    final wasResting = old.state.restRemaining != null;
    final resting = widget.state.restRemaining != null;
    if (wasResting == resting) return;
    final hadFocus = _barFocus.hasFocus;
    if (!hadFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) (resting ? _skipFocus : _actionFocus).requestFocus();
    });
  }

  @override
  void dispose() {
    _actionFocus.dispose();
    _skipFocus.dispose();
    _barFocus.dispose();
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
        // Con letra muy grande la barra no tapa la tabla: tiene un alto
        // máximo y su contenido se desplaza.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(context).height *
                TokensLayout.bottomBarMaxShare,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TokensSpacing.m),
            child: TrainingContent(
              child: Focus(
                focusNode: _barFocus,
                child: resting
                    ? _RestPanel(
                        state: s,
                        drafts: widget.drafts,
                        skipFocus: _skipFocus,
                      )
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
    Widget? timer;
    if (set != null) {
      final rowInvalid = SetFields.of(viewed).fields.any(
        (f) => invalid.contains(LiveSessionState.draftKey(viewed.id, set, f)),
      );
      // «Serie N registrada · Deshacer» lo anuncia la página.
      void log() => onLog(viewed, set, s.valuesFor(viewed, set, drafts));

      final canLog = !s.saving && !rowInvalid;
      final timed = s.timerOn(viewed, set);
      final running = timed && s.timerSince != null;
      final doneLabel = timed
          ? l10n.trainingSetDoneShort
          : l10n.trainingLiveSetDone(set);
      void resume() => bloc.add(const LiveSessionEvent.resumeRequested());
      // Marcar la serie que toca es la acción principal (el ✓ de la fila hace
      // lo mismo, a mano de quien mira la tabla). En pausa manda reanudar;
      // marcarla también reanuda (el cronómetro ayuda, nunca obliga).
      final Widget done = AppPrimaryButton(
        label: doneLabel,
        icon: Icons.check_rounded,
        focusNode: focus,
        onPressed: canLog ? log : null,
      );
      // El cronómetro de la serie es opcional: un botón cuadrado con icono y
      // su nombre en la descripción (el texto «Cronometrar» no cabía).
      Widget iconAction(String tooltip, IconData icon, VoidCallback? onTap) =>
          IconButton.outlined(
            tooltip: tooltip,
            style: IconButton.styleFrom(
              minimumSize: const Size.square(TokensSize.controlHeight),
            ),
            onPressed: onTap,
            icon: Icon(icon),
          );
      final Widget secondary = s.paused
          ? AppPrimaryButton(
              label: l10n.trainingResume,
              icon: Icons.play_arrow_rounded,
              focusNode: focus,
              onPressed: resume,
            )
          : !timed
          ? iconAction(
              l10n.trainingSetTimerStart,
              Icons.timer_outlined,
              () => bloc.add(LiveSessionEvent.setTimerStarted(viewed.id, set)),
            )
          : running
          ? iconAction(
              l10n.trainingPause,
              Icons.pause_rounded,
              () => bloc.add(const LiveSessionEvent.pauseRequested()),
            )
          : iconAction(l10n.trainingResume, Icons.play_arrow_rounded, resume);
      // Un solo botón destacado, ancho y al lado del pulgar; el otro, un
      // icono. En pausa manda «Reanudar» y marcar queda como icono.
      final (primary, other) = s.paused
          ? (
              secondary,
              iconAction(doneLabel, Icons.check_rounded, canLog ? log : null),
            )
          : (done, secondary);
      action = Row(
        children: [
          other,
          const SizedBox(width: TokensSpacing.s),
          Expanded(child: primary),
        ],
      );
      if (timed) {
        final color = running
            ? context.colors.primary
            : context.palette.warning;
        timer = Semantics(
          container: true,
          label: running
              ? l10n.trainingSetTimerRunning(set)
              : l10n.trainingSetTimerPaused(set),
          value: spokenClock(l10n, s.timerSeconds),
          excludeSemantics: true,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  running
                      ? l10n.trainingSetTimerRunning(set)
                      : l10n.trainingSetTimerPaused(set),
                  style: context.textStyles.titleSmall?.copyWith(color: color),
                ),
              ),
              Text(
                formatClock(s.timerSeconds),
                style: context.textStyles.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
      }
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
        // En pausa (sin cronómetro de serie): se dice y se reanuda a un toque.
        if (s.paused && (set == null || !s.timerOn(viewed, set))) ...[
          Row(
            children: [
              Icon(
                Icons.pause_circle_rounded,
                color: context.palette.warning,
                size: TokensSize.iconS,
              ),
              const SizedBox(width: TokensSpacing.xs),
              Expanded(
                child: Text(
                  l10n.trainingPausedBanner,
                  style: context.textStyles.titleSmall,
                ),
              ),
              // Con una serie por hacer, «Reanudar» ya es el botón principal.
              if (set == null)
                TextButton(
                  onPressed: () =>
                      bloc.add(const LiveSessionEvent.resumeRequested()),
                  child: Text(l10n.trainingResume),
                ),
            ],
          ),
          const SizedBox(height: TokensSpacing.xs),
        ],
        if (timer != null) ...[timer, const SizedBox(height: TokensSpacing.xs)],
        // Las cifras con las que se marcará (las de la fila): la serie ya la
        // dice el botón.
        if (set != null)
          Text(
            l10n.trainingLiveNowValues(
              targetLabel(
                context,
                viewed,
                set,
                values: s.valuesFor(viewed, set, drafts),
              ),
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

/// Descanso en grande. Arriba, «Serie N registrada · Deshacer» de la serie
/// que lo abrió: dentro del panel siempre se ve (un aviso flotante quedaba
/// tapado). Deshacer la desmarca y para el descanso.
class _RestPanel extends StatelessWidget {
  const _RestPanel({
    required this.state,
    required this.drafts,
    required this.skipFocus,
  });

  final LiveSessionState state;
  final SetDrafts drafts;
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
    final owner = [...?s.session?.sets]
        .where(
          (x) =>
              LiveSessionBloc.restKey(x.plannedExerciseId, x.setNumber) ==
              s.restForSet,
        )
        .firstOrNull;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (owner != null)
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: onColor,
                size: TokensSize.iconS,
              ),
              const SizedBox(width: TokensSpacing.xs),
              Expanded(
                child: Text(
                  l10n.trainingSetLogged(owner.setNumber),
                  style: context.textStyles.titleSmall?.copyWith(
                    color: onColor,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: onColor),
                onPressed: () {
                  bloc.add(LiveSessionEvent.setDeleted(owner.id));
                  SemanticsService.sendAnnouncement(
                    View.of(context),
                    l10n.trainingSetUnmarked(owner.setNumber),
                    Directionality.of(context),
                  );
                },
                child: Text(
                  l10n.commonUndo,
                  semanticsLabel: l10n.trainingUndoSet(owner.setNumber),
                ),
              ),
            ],
          ),
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
              targetLabel(
                context,
                up,
                next,
                values: s.valuesFor(up, next, drafts),
              ),
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
              child: Text(l10n.trainingSkipRest),
            ),
          ],
        ),
      ],
    );
  }
}
