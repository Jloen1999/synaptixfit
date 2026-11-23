import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/models/training/exercise_calibration.dart';
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

/// Cifras de una serie en corto para el panel: «8 × 60 kg» con repeticiones y
/// peso; si no, lo de [targetLabel]. Devuelve también cómo se lee (el lector
/// leería «×» como «multiplicado por»).
(String, String) compactTarget(
  BuildContext context,
  PlannedExercise e,
  int set,
  Map<SetField, num?> values,
) {
  final l10n = context.localizations;
  final fields = SetFields.of(e);
  final reps = values[SetField.reps];
  final weight = values[SetField.weight];
  if (!fields.isCardio &&
      !fields.isHold &&
      reps != null &&
      weight != null &&
      weight > 0) {
    final kg = formatNumber(weight.toDouble());
    return (
      l10n.trainingRepsTimesWeight(reps.toInt(), kg),
      l10n.trainingRepsWithWeightSpoken(reps.toInt(), kg),
    );
  }
  final text = targetLabel(context, e, set, values: values);
  return (text, text);
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

/// Partes de la sesión en vivo que señala su guía la primera vez (ADR 0049):
/// «Empezar serie», la foto («Cómo se hace»), el reloj ⏱ y las cifras de la
/// serie que toca. Las crea la página y las reparte a cada parte.
class LiveGuideKeys {
  final start = GlobalKey(debugLabel: 'guide-live-start');
  final photo = GlobalKey(debugLabel: 'guide-live-photo');
  final clock = GlobalKey(debugLabel: 'guide-live-clock');
  final figures = GlobalKey(debugLabel: 'guide-live-figures');
}

/// Cabecera fija de la sesión (ADR 0053): «N de M series» con el reloj ⏱ de
/// las series, la barra de avance, «Entreno: N min · te quedan ≈ M min» y la
/// tira con los ejercicios para saltar entre ellos. Con letra grande la tira
/// se cambia por «Ejercicio 2 de 6» con anterior y siguiente.
class LiveSessionHeader extends StatelessWidget {
  const LiveSessionHeader({
    super.key,
    required this.state,
    this.guideKeys,
    this.viewedKey,
  });

  final LiveSessionState state;
  final LiveGuideKeys? guideKeys;

  /// Clave del ejercicio que se mira en la tira: al pasar al siguiente, la
  /// página lo desplaza a la vista (ADR 0062).
  final GlobalKey? viewedKey;

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
              LiveClockSummary(
                state: s,
                clockKey: guideKeys?.clock,
                leading: Text(
                  l10n.trainingLiveSetsCount(s.loggedSets, s.plannedSets),
                  style: context.textStyles.labelLarge,
                ),
                // El lector ya oye «N de M series» a la izquierda.
                bar: ExcludeSemantics(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(TokensRadius.pill),
                    child: LinearProgressIndicator(
                      value: progress,
                      color: context.colors.primary,
                      backgroundColor: context.colors.surfaceContainerHigh,
                    ),
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
                // Todos montados (no perezosa): una rutina tiene pocos
                // ejercicios y así el que toca se puede desplazar a la vista
                // aunque esté fuera de la pantalla.
                SizedBox(
                  height: TokensSize.listTileMin,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: TokensSpacing.xs,
                      children: [
                        for (final (i, e) in s.exercises.indexed)
                          KeyedSubtree(
                            key: e.id == viewed.id ? viewedKey : null,
                            child: _StripItem(
                              exercise: e,
                              index: i,
                              total: s.exercises.length,
                              done: s.loggedSetsOf(e),
                              selected: e.id == viewed.id,
                              now: e.id == viewed.id && s.nextSetOf(e) != null,
                            ),
                          ),
                      ],
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
    this.now = false,
  });

  final PlannedExercise exercise;
  final int index;
  final int total;
  final int done;
  final bool selected;

  /// Es el que toca hacer ahora: además del borde, fondo del color de acento
  /// y un ▶ pequeño (no solo color); el lector oye «Ahora toca».
  final bool now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final sets = exercise.parameters.sets;
    final finished = done >= sets;
    final item = l10n.trainingLiveStripItem(
      index + 1,
      total,
      exercise.exerciseName,
      done,
      sets,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: now ? l10n.trainingLiveStripItemNow(item) : item,
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
              color: now ? _nowTint(context) : null,
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
                  icon: exercise.modality.icon,
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
                // ▶ del que toca, sobre un círculo de la superficie para que
                // se vea encima de cualquier foto.
                if (now)
                  PositionedDirectional(
                    start: 0,
                    top: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: context.colors.primary,
                        size: TokensSize.iconXs,
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
    this.guideKeys,
    this.titleKey,
  });

  final LiveSessionState state;
  final SetDrafts drafts;

  /// Clave del título del ejercicio: al pasar al siguiente, la página lo
  /// desplaza a la vista (ADR 0062).
  final GlobalKey? titleKey;

  /// La fila de la serie que toca lleva la clave de las cifras de la guía.
  final LiveGuideKeys? guideKeys;

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
              _ExerciseTitle(
                key: titleKey,
                position: l10n.trainingLiveExerciseOf(
                  index + 1,
                  s.exercises.length,
                ),
                name: e.exerciseName,
                now: current != null,
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
              // «Te deben sobrar 2»: el esfuerzo que pide la plantilla, en
              // palabras (ADR 0054).
              if (e.parameters.repsInReserve != null &&
                  fields.has(SetField.reps))
                Text(
                  l10n.trainingRepsInReserve(e.parameters.repsInReserve!),
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
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
                        _guideRow(
                          n == (current ?? 1) ? guideKeys?.figures : null,
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

/// La fila con [key] (la que señala la guía) o tal cual.
Widget _guideRow(GlobalKey? key, Widget row) =>
    key == null ? row : KeyedSubtree(key: key, child: row);

/// Fondo del ejercicio que toca (título y tira): el mismo que la fila de la
/// serie que toca y que la maqueta de la sesión en vivo, `primaryContainer`
/// (primary y onSurface encima, validados en `contrast_test`).
Color _nowTint(BuildContext context) => context.colors.primaryContainer;

/// «Ejercicio 2 de 6» y el nombre. Si es el que toca hacer ahora ([now]),
/// va resaltado con borde y fondo de acento y la etiqueta «Ahora toca» con
/// icono: el color no es la única señal (ADR 0062). Mirando uno ya hecho, sin
/// resaltar.
class _ExerciseTitle extends StatelessWidget {
  const _ExerciseTitle({
    super.key,
    required this.position,
    required this.name,
    required this.now,
  });

  final String position;
  final String name;
  final bool now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final primary = context.colors.primary;
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: TokensSpacing.s,
          runSpacing: TokensSpacing.xxs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (now)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    size: TokensSize.iconXs,
                    color: primary,
                  ),
                  const SizedBox(width: TokensSpacing.xxs),
                  Text(
                    l10n.trainingLiveNowExercise,
                    style: context.textStyles.labelLarge?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            Text(
              position,
              style: context.textStyles.labelLarge?.copyWith(color: primary),
            ),
          ],
        ),
        Semantics(
          header: true,
          child: Text(name, style: context.textStyles.headlineSmall),
        ),
      ],
    );
    if (!now) return column;
    return Container(
      padding: const EdgeInsets.all(TokensSpacing.sm),
      decoration: BoxDecoration(
        color: _nowTint(context),
        borderRadius: BorderRadius.circular(TokensRadius.m),
        border: Border.all(color: primary, width: TokensSize.focusRing),
      ),
      child: column,
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
            l.increases ? AppIcons.trendUp : Icons.trending_down_rounded,
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

    // Un solo sitio para marcar: el panel de abajo (ADR 0053). En la tabla,
    // el ✓ solo está en las series hechas y quitarlo las desmarca al momento
    // (con «Deshacer», como Hevy o Strong); las pendientes dejan el hueco para
    // que las columnas sigan alineadas.
    final Widget check = done == null
        ? SizedBox.square(dimension: number)
        : IconButton(
            tooltip: l10n.trainingUnmarkSetNumber(n),
            style: IconButton.styleFrom(
              backgroundColor: done.completed
                  ? context.palette.success
                  : context.palette.warning,
              // Su «on» propio: con onPrimary el ✓ no llegaba a AA en oscuro.
              foregroundColor: done.completed
                  ? context.palette.onSuccess
                  : context.palette.onWarning,
            ),
            onPressed: () => onUnmark(e, done),
            icon: Icon(
              done.completed ? Icons.check_rounded : Icons.cancel_rounded,
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
    // «Ahora» sobre lo previsto de la serie que toca (también en texto, no
    // solo con el color del borde).
    final nowMark = Text(
      l10n.trainingSetNow,
      style: context.textStyles.labelMedium?.copyWith(
        color: context.colors.primary,
        fontWeight: FontWeight.w700,
      ),
    );
    // Con la serie en marcha, la fila ya dice «En curso»: sin «Ahora».
    final showNow = current && done == null && !state.timerOn(e, n);
    final Widget body;
    if (stacked) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showNow) nowMark,
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
          Expanded(
            flex: 2,
            child: showNow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [nowMark, targetText],
                  )
                : targetText,
          ),
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
                      // Sin la cifra: el tiempo se ve en un solo sitio, el
                      // reloj de la serie del panel de abajo (ADR 0053).
                      timerPaused
                          ? l10n.trainingSetRowPaused
                          : l10n.trainingSetRowInProgress,
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
          : done != null
          ? null
          : current
          ? l10n.trainingSetNowSpoken(n)
          : l10n.trainingSetPendingSpoken(n),
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

/// Reloj de la cabecera, igual en la sesión de rutina ([LiveSessionHeader]) y
/// en la libre (ADR 0053): a la derecha la píldora ⏱ con el tiempo haciendo
/// series ([LiveSessionState.seriesSeconds]); debajo, en pequeño y en minutos,
/// lo que se lleva de entreno y lo que queda según la duración prevista del
/// servidor (no se mueve cada segundo, así no parece que corra la serie).
class LiveClockSummary extends StatelessWidget {
  const LiveClockSummary({
    super.key,
    required this.state,
    this.leading,
    this.bar,
    this.clockKey,
  });

  final LiveSessionState state;

  /// Clave de la píldora ⏱, para señalarla en la guía (ADR 0049).
  final GlobalKey? clockKey;

  /// Lo que va a la izquierda de la píldora (en la rutina, las series).
  final Widget? leading;

  /// Barra de avance entre la fila de arriba y la línea del entreno.
  final Widget? bar;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final minutes = state.workoutMinutes;
    final left = state.remainingEstimatedMinutes;
    final hasLeft = left != null && left > 0;
    final pill = KeyedSubtree(
      key: clockKey,
      child: LiveClockPill(
        seconds: state.seriesSeconds,
        mode: state.seriesClock,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Con letra grande, en vertical: las series arriba y el reloj debajo,
        // alineados a la izquierda (al 200 % no caben en una fila).
        if (context.largeText)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(height: TokensSpacing.xs),
              ],
              pill,
            ],
          )
        else
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [?leading, pill],
          ),
        if (bar != null) ...[const SizedBox(height: TokensSpacing.xs), bar!],
        const SizedBox(height: TokensSpacing.xxs),
        Text(
          hasLeft
              ? l10n.trainingWorkoutMinutesLeft(minutes, left)
              : l10n.trainingWorkoutMinutes(minutes),
          semanticsLabel: hasLeft
              ? l10n.trainingWorkoutMinutesLeftSpoken(minutes, left)
              : l10n.trainingWorkoutMinutesSpoken(minutes),
          style: context.textStyles.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Píldora ⏱ con el tiempo haciendo series (ADR 0053). Mientras corre una
/// serie, en el color de acento con un punto que late dos veces y se queda
/// fijo (WCAG 2.2.2); con la serie en pausa, ámbar con ⏸; sin serie en
/// marcha, gris y quieta. El estado se dice con icono y texto para el lector,
/// no solo con el color.
class LiveClockPill extends StatefulWidget {
  const LiveClockPill({super.key, required this.seconds, required this.mode});

  final int seconds;
  final SeriesClockMode mode;

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

  /// Si corría la última vez (nulo: aún no se ha pintado).
  bool? _wasRunning;

  void _sync() {
    final running = widget.mode == SeriesClockMode.running;
    final starting = running && _wasRunning != true;
    _wasRunning = running;
    if (!running || context.reduceMotion) {
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
    final mode = widget.mode;
    // Tinte opaco sobre la superficie, como [AppPill]: el contraste es el
    // mismo esté sobre la cabecera o sobre el fondo (contrast_test).
    final (Color background, Color foreground) = switch (mode) {
      SeriesClockMode.running => (
        context.palette.accentContainer,
        context.palette.onAccentContainer,
      ),
      SeriesClockMode.paused => (
        Color.alphaBlend(
          context.palette.warning.withValues(alpha: AppPill.tintAlpha),
          context.colors.surface,
        ),
        context.palette.warning,
      ),
      SeriesClockMode.idle => (
        context.colors.surfaceContainerHigh,
        context.colors.onSurfaceVariant,
      ),
    };
    final spoken = spokenClock(l10n, widget.seconds);
    return Semantics(
      label: switch (mode) {
        SeriesClockMode.paused => l10n.trainingSeriesClockPausedSpoken(spoken),
        SeriesClockMode.running => l10n.trainingSeriesClockRunningSpoken(
          spoken,
        ),
        SeriesClockMode.idle => l10n.trainingSeriesClockSpoken(spoken),
      },
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
              if (mode == SeriesClockMode.running) ...[
                FadeTransition(
                  opacity: Tween<double>(
                    begin: 1,
                    end: TokensOpacity.blinkMin,
                  ).animate(_blink),
                  child: Icon(
                    Icons.circle,
                    size: TokensSize.liveDot,
                    color: context.palette.accent,
                  ),
                ),
                const SizedBox(width: TokensSpacing.xs),
              ],
              if (mode == SeriesClockMode.paused) ...[
                Icon(
                  Icons.pause_rounded,
                  size: TokensSize.iconXs,
                  color: foreground,
                ),
                const SizedBox(width: TokensSpacing.xxs),
              ],
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

/// Barra inferior de la sesión (ADR 0053), con poco texto y la foto del
/// ejercicio a mano (abre «Cómo se hace»). Según el momento:
/// - antes de la serie: «Serie 2 de 4», «8 × 60 kg», «Empezar serie» (arranca
///   su cronómetro) y «Ya la hice» (la marca sin cronómetro);
/// - haciéndola: el reloj grande de la serie, ⏸ y «Serie hecha» (en pausa,
///   ámbar con «Seguir»);
/// - descansando: «Serie 2 hecha · descansa», la cuenta atrás, qué viene
///   después, −15 s, +15 s y «Saltar descanso»;
/// - ejercicio terminado: el siguiente con su foto e «Ir al siguiente»; con
///   todo hecho, «Terminar».
/// Al cambiar de momento, si el foco estaba en la barra pasa a la acción nueva.
class LiveSessionBottomBar extends StatefulWidget {
  const LiveSessionBottomBar({
    super.key,
    required this.state,
    required this.drafts,
    required this.invalid,
    required this.onLog,
    required this.onFinish,
    this.guideKeys,
  });

  final LiveSessionState state;
  final SetDrafts drafts;
  final Set<String> invalid;
  final void Function(PlannedExercise e, int set, Map<SetField, num?> values)
  onLog;
  final VoidCallback? onFinish;

  /// «Empezar serie» y la foto llevan las claves de la guía.
  final LiveGuideKeys? guideKeys;

  @override
  State<LiveSessionBottomBar> createState() => _LiveSessionBottomBarState();
}

/// Momento del panel: decide qué acción recibe el foco al cambiar.
enum _PanelMoment { before, beforePaused, doing, doingPaused, rest, next, done }

/// La serie cronometrada que se acaba de marcar se está guardando: el panel
/// sigue en «haciendo» (con «Serie hecha» cargando) en vez de volver un
/// instante a «Empezar serie» de esa misma serie.
bool _savingTimedSet(LiveSessionState s) => s.saving && s.recordingSeconds > 0;

_PanelMoment _momentOf(LiveSessionState s) {
  if (s.restRemaining != null) return _PanelMoment.rest;
  final viewed = s.viewed;
  final set = s.nextSetOf(viewed);
  if (set != null) {
    if (s.timerOn(viewed, set) || _savingTimedSet(s)) {
      return s.timerSince == null && !_savingTimedSet(s)
          ? _PanelMoment.doingPaused
          : _PanelMoment.doing;
    }
    return s.paused ? _PanelMoment.beforePaused : _PanelMoment.before;
  }
  return s.upNext == null ? _PanelMoment.done : _PanelMoment.next;
}

class _LiveSessionBottomBarState extends State<LiveSessionBottomBar> {
  final _actionFocus = FocusNode();
  final _toggleFocus = FocusNode();
  final _restFocus = FocusNode();

  /// Agrupa todo lo de la barra: si el foco estaba en cualquiera de sus
  /// botones (también −15 s o la foto), pasa a la acción del panel nuevo.
  final _barFocus = FocusNode(skipTraversal: true, canRequestFocus: false);

  /// El foco estaba en la barra. Sigue valiendo si se soltó porque un botón
  /// se desactivó o desapareció (al guardar o al pausar); deja de valer si la
  /// persona lo llevó a otro sitio (WCAG 2.4.3).
  bool _focusWasHere = false;

  @override
  void initState() {
    super.initState();
    _barFocus.addListener(_onBarFocus);
  }

  void _onBarFocus() {
    if (_barFocus.hasFocus) {
      _focusWasHere = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = FocusManager.instance.primaryFocus;
      if (now != null && now is! FocusScopeNode) _focusWasHere = false;
    });
  }

  @override
  void didUpdateWidget(LiveSessionBottomBar old) {
    super.didUpdateWidget(old);
    final before = _momentOf(old.state);
    final now = _momentOf(widget.state);
    // Al responder la calibración la pregunta desaparece pero el momento no
    // cambia: el foco vuelve a «+15 s» en vez de perderse (WCAG 2.4.3).
    if (before == now &&
        now == _PanelMoment.rest &&
        old.state.asksCalibrationNow &&
        !widget.state.asksCalibrationNow &&
        (_barFocus.hasFocus || _focusWasHere)) {
      _focusVisible(_restFocus);
      return;
    }
    if (before == now || !(_barFocus.hasFocus || _focusWasHere)) return;
    // En el descanso, a «+15 s»: un Intro de más no se salta el descanso.
    // Al pausar o seguir la serie, al botón que cambia; si no, a la acción.
    final target = switch (now) {
      _PanelMoment.rest => _restFocus,
      _PanelMoment.doing when before == _PanelMoment.doingPaused =>
        _toggleFocus,
      _PanelMoment.doingPaused => _toggleFocus,
      _ => _actionFocus,
    };
    _focusVisible(target);
  }

  /// Da el foco a [target] y lo desplaza a la vista: en pantallas bajas el
  /// panel se desplaza y el anillo de foco quedaría oculto (WCAG 2.4.11).
  void _focusVisible(FocusNode target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !target.canRequestFocus) return;
      target.requestFocus();
      final focused = target.context;
      if (focused != null) unawaited(Scrollable.ensureVisible(focused));
    });
  }

  @override
  void dispose() {
    _barFocus.removeListener(_onBarFocus);
    _actionFocus.dispose();
    _toggleFocus.dispose();
    _restFocus.dispose();
    _barFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final resting = s.restRemaining != null;
    return LiveBottomPanel(
      resting: resting,
      child: Focus(
        focusNode: _barFocus,
        child: resting
            ? LiveRestPanel(
                state: s,
                drafts: widget.drafts,
                restFocus: _restFocus,
              )
            : _NextPanel(
                state: s,
                drafts: widget.drafts,
                invalid: widget.invalid,
                onLog: widget.onLog,
                onFinish: widget.onFinish,
                focus: _actionFocus,
                toggleFocus: _toggleFocus,
                guideKeys: widget.guideKeys,
              ),
      ),
    );
  }
}

/// Fondo y medidas de la barra inferior de la sesión, igual en la de rutina
/// ([LiveSessionBottomBar]) y en la libre: en el descanso, el color del
/// descanso. Con letra muy grande no tapa la tabla: tiene un alto máximo y su
/// contenido se desplaza.
class LiveBottomPanel extends StatelessWidget {
  const LiveBottomPanel({
    super.key,
    required this.resting,
    required this.child,
  });

  final bool resting;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: resting
            ? context.colors.secondaryContainer
            : context.colors.surfaceContainerLow,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(context).height *
                TokensLayout.bottomBarMaxShare,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TokensSpacing.m),
            child: TrainingContent(child: child),
          ),
        ),
      ),
    );
  }
}

/// Foto del ejercicio (o el icono de su tipo si no la hay) que abre «Cómo se
/// hace» sin salir de la serie. El icono de vídeo dice que se puede tocar.
class _ExerciseThumbButton extends StatelessWidget {
  const _ExerciseThumbButton({required this.exercise});

  final PlannedExercise exercise;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    // La miniatura ya es decorativa: el nodo lleva el nombre y la acción.
    return Semantics(
      container: true,
      button: true,
      label: l10n.trainingHowToOf(exercise.exerciseName),
      child: AppFocusOutline(
        borderRadius: BorderRadius.circular(TokensRadius.m),
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensRadius.m),
          onTap: () => openHowTo(context, exercise),
          child: Stack(
            children: [
              ExerciseThumbnail(
                url: exercise.thumbnailUrl,
                icon: exercise.modality.icon,
              ),
              PositionedDirectional(
                end: TokensSpacing.xxs,
                bottom: TokensSpacing.xxs,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.howTo,
                    size: TokensSize.iconXs,
                    color: context.colors.onSurface,
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

/// Puntos de avance de las series del ejercicio: hechas, la que toca y las
/// que faltan. Decorativos: «Serie 2 de 4» ya lo dice.
class _SetDots extends StatelessWidget {
  const _SetDots({required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Wrap(
      spacing: TokensSpacing.xxs,
      runSpacing: TokensSpacing.xxs,
      children: [
        for (var n = 1; n <= total; n++)
          Container(
            width: TokensSize.liveDot,
            height: TokensSize.liveDot,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: n <= done
                  ? context.palette.success
                  : n == done + 1
                  ? context.colors.primary
                  : context.colors.surfaceContainerHigh,
              border: Border.all(color: context.colors.outlineVariant),
            ),
          ),
      ],
    ),
  );
}

class _NextPanel extends StatelessWidget {
  const _NextPanel({
    required this.state,
    required this.drafts,
    required this.invalid,
    required this.onLog,
    required this.onFinish,
    required this.focus,
    required this.toggleFocus,
    this.guideKeys,
  });

  final LiveSessionState state;
  final SetDrafts drafts;
  final Set<String> invalid;
  final void Function(PlannedExercise e, int set, Map<SetField, num?> values)
  onLog;
  final VoidCallback? onFinish;
  final FocusNode focus;
  final FocusNode toggleFocus;
  final LiveGuideKeys? guideKeys;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final s = state;
    final viewed = s.viewed;
    final set = s.nextSetOf(viewed);
    final up = s.upNext;
    final index = s.exercises.indexOf(viewed);
    final bloc = context.read<LiveSessionBloc>();
    // Siguiente ejercicio: el que toca si no es este, o el siguiente con
    // series por hacer.
    final following = up != null && up.id != viewed.id
        ? up
        : s.exercises
              .skip(index + 1)
              .where((e) => s.nextSetOf(e) != null)
              .firstOrNull;
    final timed = set != null && (s.timerOn(viewed, set) || _savingTimedSet(s));
    final children = <Widget>[
      // En pausa sin cronómetro de serie (p. ej. la pausa del grupo): se dice
      // y se reanuda a un toque, como siempre.
      if (s.paused && !timed) ...[
        _PausedBanner(state: s, focus: set == null ? focus : null),
        const SizedBox(height: TokensSpacing.s),
      ],
    ];
    if (set != null) {
      final rowInvalid = SetFields.of(viewed).fields.any(
        (f) => invalid.contains(LiveSessionState.draftKey(viewed.id, set, f)),
      );
      final canLog = !s.saving && !rowInvalid;
      // Marca con las cifras de la fila (lo escrito o lo propuesto); si se
      // cronometraba, el bloc le pone su tiempo.
      void log() => onLog(viewed, set, s.valuesFor(viewed, set, drafts));
      final (target, targetSpoken) = compactTarget(
        context,
        viewed,
        set,
        s.valuesFor(viewed, set, drafts),
      );
      final total = viewed.parameters.sets;
      children.add(
        timed
            ? _DoingSet(
                state: s,
                exercise: viewed,
                set: set,
                total: total,
                target: target,
                targetSpoken: targetSpoken,
                focus: focus,
                toggleFocus: toggleFocus,
                onDone: canLog ? log : null,
              )
            : _BeforeSet(
                state: s,
                exercise: viewed,
                set: set,
                total: total,
                target: target,
                targetSpoken: targetSpoken,
                focus: focus,
                onStart: () =>
                    bloc.add(LiveSessionEvent.setTimerStarted(viewed.id, set)),
                onAlreadyDone: canLog ? log : null,
                guideKeys: guideKeys,
              ),
      );
    } else if (following != null) {
      children.addAll([
        Row(
          children: [
            _ExerciseThumbButton(exercise: following),
            const SizedBox(width: TokensSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.trainingNextExerciseSummary(
                      plannedSummary(
                        l10n,
                        following.parameters,
                        SetFields.of(following),
                      ),
                    ),
                    style: context.textStyles.labelMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    following.exerciseName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: TokensSpacing.s),
        AppPrimaryButton(
          label: l10n.trainingGoToNext,
          icon: Icons.arrow_forward_rounded,
          focusNode: focus,
          onPressed: () =>
              bloc.add(LiveSessionEvent.nextExerciseRequested(following.id)),
        ),
      ]);
    } else {
      children.addAll([
        Text(
          l10n.trainingAllSetsDone,
          style: context.textStyles.titleSmall?.copyWith(
            color: context.palette.success,
          ),
        ),
        const SizedBox(height: TokensSpacing.s),
        AppPrimaryButton(
          label: l10n.trainingFinishAction,
          icon: Icons.flag_rounded,
          loading: s.finishing,
          focusNode: focus,
          onPressed: onFinish,
        ),
      ]);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// «Sesión en pausa» (o «En pausa · la ha puesto Ana», ADR 0047) con
/// «Reanudar» (para todos, si la pausa es del grupo).
class _PausedBanner extends StatelessWidget {
  const _PausedBanner({required this.state, this.focus});

  final LiveSessionState state;

  /// Foco de la acción del panel cuando «Reanudar» es lo único que hacer.
  final FocusNode? focus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<LiveSessionBloc>();
    return Row(
      children: [
        Icon(
          Icons.pause_circle_rounded,
          color: context.palette.warning,
          size: TokensSize.iconS,
        ),
        const SizedBox(width: TokensSpacing.xs),
        Expanded(
          child: Text(switch (state.groupPausedBy) {
            final String name => l10n.togetherPausedBy(name),
            null => l10n.trainingPausedBanner,
          }, style: context.textStyles.titleSmall),
        ),
        // Con la pausa del grupo, reanudar es para todos y se dice.
        TextButton(
          focusNode: focus,
          onPressed: () => bloc.add(const LiveSessionEvent.resumeRequested()),
          child: Text(
            state.groupPausedBy != null
                ? l10n.togetherResumeForAll
                : l10n.trainingResume,
          ),
        ),
      ],
    );
  }
}

/// Antes de la serie: foto, «Serie 2 de 4», «8 × 60 kg», puntos de avance,
/// «Empezar serie» y «Ya la hice» (sin cronómetro: esa serie no suma al ⏱).
class _BeforeSet extends StatelessWidget {
  const _BeforeSet({
    required this.state,
    required this.exercise,
    required this.set,
    required this.total,
    required this.target,
    required this.targetSpoken,
    required this.focus,
    required this.onStart,
    required this.onAlreadyDone,
    this.guideKeys,
  });

  final LiveSessionState state;
  final PlannedExercise exercise;
  final int set;
  final int total;
  final String target;
  final String targetSpoken;
  final FocusNode focus;
  final VoidCallback onStart;
  final VoidCallback? onAlreadyDone;
  final LiveGuideKeys? guideKeys;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    // Mientras se guarda otra serie no se desactiva (no se pierde el foco):
    // el bloc encola lo que se marque.
    final start = AppPrimaryButton(
      label: l10n.trainingStartSet,
      icon: AppIcons.start,
      focusNode: focus,
      onPressed: onStart,
    );
    final done = TextButton(
      onPressed: onAlreadyDone,
      child: Text(
        l10n.trainingAlreadyDone,
        semanticsLabel: l10n.trainingAlreadyDoneSpoken(set),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            KeyedSubtree(
              key: guideKeys?.photo,
              child: _ExerciseThumbButton(exercise: exercise),
            ),
            const SizedBox(width: TokensSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.trainingSetOf(set, total),
                    style: context.textStyles.labelMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    target,
                    semanticsLabel: targetSpoken,
                    style: context.textStyles.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.xxs),
                  _SetDots(total: total, done: state.loggedSetsOf(exercise)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: TokensSpacing.s),
        KeyedSubtree(
          key: guideKeys?.start,
          // Con letra grande, uno debajo del otro: «Empezar serie» no se parte.
          child: context.largeText
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    start,
                    const SizedBox(height: TokensSpacing.xs),
                    done,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: start),
                    const SizedBox(width: TokensSpacing.xs),
                    done,
                  ],
                ),
        ),
      ],
    );
  }
}

/// Haciendo la serie: foto y su reloj grande, ⏸ (pausa la serie y la sesión,
/// ADR 0030) y «Serie hecha». En pausa, el reloj en ámbar, «Seguir» y ✓.
class _DoingSet extends StatelessWidget {
  const _DoingSet({
    required this.state,
    required this.exercise,
    required this.set,
    required this.total,
    required this.target,
    required this.targetSpoken,
    required this.focus,
    required this.toggleFocus,
    required this.onDone,
  });

  final LiveSessionState state;
  final PlannedExercise exercise;
  final int set;
  final int total;
  final String target;
  final String targetSpoken;
  final FocusNode focus;

  /// Foco compartido por ⏸ y «Seguir»: al cambiar uno por otro no se pierde.
  final FocusNode toggleFocus;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<LiveSessionBloc>();
    final saving = _savingTimedSet(state);
    final running = saving || (state.timerSince != null && !state.paused);
    final seconds = saving ? state.recordingSeconds : state.timerSeconds;
    final color = running ? context.colors.primary : context.palette.warning;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _ExerciseThumbButton(exercise: exercise),
            const SizedBox(width: TokensSpacing.s),
            Expanded(
              // Sin región viva: cambiaría cada segundo. El lector oye la
              // serie, si está en pausa y el tiempo al llegar aquí.
              child: Semantics(
                container: true,
                label: running
                    ? l10n.trainingSetTimerRunning(set)
                    : l10n.trainingSetTimerPaused(set),
                value: spokenClock(l10n, seconds),
                hint: targetSpoken,
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.trainingSetOfWithTarget(set, total, target),
                      style: context.textStyles.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    Row(
                      children: [
                        if (!running) ...[
                          Icon(
                            Icons.pause_rounded,
                            color: color,
                            size: TokensSize.iconM,
                          ),
                          const SizedBox(width: TokensSpacing.xxs),
                        ],
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              formatClock(seconds),
                              style: context.textStyles.headlineMedium
                                  ?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: TokensSpacing.s),
        Row(
          children: [
            if (running)
              IconButton.outlined(
                focusNode: toggleFocus,
                tooltip: l10n.trainingPauseSet,
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(TokensSize.controlHeight),
                ),
                onPressed: saving
                    ? null
                    : () => bloc.add(const LiveSessionEvent.pauseRequested()),
                icon: const Icon(Icons.pause_rounded),
              )
            else
              OutlinedButton.icon(
                focusNode: toggleFocus,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, TokensSize.controlHeight),
                ),
                onPressed: () =>
                    bloc.add(const LiveSessionEvent.resumeRequested()),
                icon: const Icon(AppIcons.start),
                label: Text(l10n.trainingContinueSet),
              ),
            const SizedBox(width: TokensSpacing.s),
            Expanded(
              child: AppPrimaryButton(
                label: l10n.trainingSetDoneShort,
                icon: Icons.check_rounded,
                focusNode: focus,
                loading: saving,
                onPressed: onDone,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Descanso en grande: «Serie 2 hecha · descansa», la cuenta atrás y qué viene
/// después («Después: serie 3 · 8 × 60 kg» o el ejercicio siguiente). Sin
/// «Deshacer»: si se marcó sin querer, se quita con el ✓ verde de la fila. Lo
/// usan la sesión de rutina y la libre (ahí no hay «después»).
class LiveRestPanel extends StatelessWidget {
  const LiveRestPanel({
    super.key,
    required this.state,
    required this.drafts,
    required this.restFocus,
  });

  final LiveSessionState state;
  final SetDrafts drafts;

  /// Foco al empezar el descanso: «+15 s» (no «Saltar descanso»).
  final FocusNode restFocus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<LiveSessionBloc>();
    final s = state;
    final remaining = s.restRemaining ?? 0;
    final progress = s.restTotal == 0 ? 0.0 : remaining / s.restTotal;
    final onColor = context.colors.onSecondaryContainer;
    final owner = [...?s.session?.sets]
        .where(
          (x) =>
              LiveSessionBloc.restKey(x.plannedExerciseId, x.setNumber) ==
              s.restForSet,
        )
        .firstOrNull;
    final up = s.upNext;
    final next = up == null ? null : s.nextSetOf(up);
    final ownerExercise = s.restExercise;
    final asking = s.asksCalibrationNow;
    final calibration = s.restCalibration;
    // Mismo ejercicio que la serie del descanso: «serie 3 · 8 × 60 kg»; si no
    // (era la última), el nombre del siguiente ejercicio.
    final String? after;
    String? afterSpoken;
    if (up == null || next == null || asking) {
      // Con la pregunta a la vista, el panel no lleva más texto: cabe en
      // pantallas bajas y la pregunta no compite.
      after = null;
    } else if (owner == null || owner.plannedExerciseId == up.id) {
      final (target, spoken) = compactTarget(
        context,
        up,
        next,
        s.valuesFor(up, next, drafts),
      );
      after = l10n.trainingRestNextSet(next, target);
      afterSpoken = l10n.trainingRestNextSet(next, spoken);
    } else {
      after = l10n.trainingLiveNextExercise(up.exerciseName);
    }
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
                      owner == null
                          ? l10n.trainingRest
                          : l10n.trainingRestAfterSet(owner.setNumber),
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
        if (asking && ownerExercise != null && owner != null) ...[
          const SizedBox(height: TokensSpacing.s),
          LiveCalibrationQuestion(
            onAnswered: (answer) => bloc.add(
              LiveSessionEvent.calibrationAnswered(
                plannedExerciseId: ownerExercise.id,
                setNumber: owner.setNumber,
                answer: answer,
              ),
            ),
          ),
        ] else if (calibration != null) ...[
          const SizedBox(height: TokensSpacing.xs),
          // El resultado lo anuncia la página una sola vez cuando llega.
          Text(
            calibrationResultText(
              l10n,
              calibration,
              failed: s.calibrationFailed.contains(
                calibration.plannedExerciseId,
              ),
            ),
            style: context.textStyles.titleSmall?.copyWith(color: onColor),
          ),
          if (calibration.step != null)
            Text(
              l10n.trainingCalibrationFixHint,
              style: context.textStyles.bodyMedium?.copyWith(color: onColor),
            ),
        ],
        if (after != null) ...[
          const SizedBox(height: TokensSpacing.xs),
          Text(
            after,
            semanticsLabel: afterSpoken,
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
              focusNode: restFocus,
              onPressed: () =>
                  bloc.add(const LiveSessionEvent.restAdjusted(15)),
              child: Semantics(
                label: l10n.trainingRestMore,
                excludeSemantics: true,
                child: Text(l10n.trainingRestPlus15),
              ),
            ),
            FilledButton(
              onPressed: () => bloc.add(const LiveSessionEvent.restSkipped()),
              child: Text(l10n.trainingSkipRest),
            ),
          ],
        ),
      ],
    );
  }
}

/// «¿Cuántas más podrías haber hecho?» tras la primera serie de un ejercicio
/// nuevo (ADR 0054): cuatro opciones de un toque. Responder es opcional; sin
/// respuesta, el peso no cambia.
class LiveCalibrationQuestion extends StatelessWidget {
  const LiveCalibrationQuestion({super.key, required this.onAnswered});

  final ValueChanged<CalibrationAnswer> onAnswered;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final onColor = context.colors.onSecondaryContainer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // En pantallas bajas o con letra grande se ahorra la explicación: los
        // botones del descanso tienen que seguir a la vista.
        if (!liveCompact(context)) ...[
          Text(
            l10n.trainingCalibrationHelp,
            style: context.textStyles.bodyMedium?.copyWith(color: onColor),
          ),
          const SizedBox(height: TokensSpacing.xs),
        ],
        AppSegmentedChoice<CalibrationAnswer>(
          label: l10n.trainingCalibrationQuestion,
          values: CalibrationAnswer.values,
          selected: null,
          labelOf: (a) => switch (a) {
            CalibrationAnswer.none => l10n.trainingCalibrationNone,
            CalibrationAnswer.oneTwo => l10n.trainingCalibrationOneTwo,
            CalibrationAnswer.three => l10n.trainingCalibrationThree,
            CalibrationAnswer.fourPlus => l10n.trainingCalibrationFourPlus,
          },
          spokenLabelOf: (a) => switch (a) {
            CalibrationAnswer.none => l10n.trainingCalibrationNone,
            CalibrationAnswer.oneTwo => l10n.trainingCalibrationOneTwoSpoken,
            CalibrationAnswer.three => l10n.trainingCalibrationThreeSpoken,
            CalibrationAnswer.fourPlus =>
              l10n.trainingCalibrationFourPlusSpoken,
          },
          onChanged: (a) {
            if (a != null) onAnswered(a);
          },
        ),
      ],
    );
  }
}

/// Qué hacer en la serie siguiente según la calibración: el peso nuevo si la
/// serie llevaba kilos; si no, «una placa más / menos» o «el mismo peso».
/// Mientras llega la respuesta, «Calculando…»; si no llega ([failed]), que
/// siga con el mismo peso y por qué.
String calibrationResultText(
  AppLocalizations l10n,
  ExerciseCalibration c, {
  bool failed = false,
}) {
  if (c.step == null) {
    return failed
        ? l10n.trainingCalibrationFailed
        : l10n.trainingCalibrationPending;
  }
  final kg = c.nextWeightKg;
  final weight = kg == null ? null : formatNumber(kg);
  return switch (c.step) {
    CalibrationStep.up when weight != null => l10n.trainingCalibrationUp(
      weight,
    ),
    CalibrationStep.up => l10n.trainingCalibrationUpPlate,
    CalibrationStep.down when weight != null => l10n.trainingCalibrationDown(
      weight,
    ),
    CalibrationStep.down => l10n.trainingCalibrationDownPlate,
    CalibrationStep.keep when weight != null => l10n.trainingCalibrationKeep(
      weight,
    ),
    _ => l10n.trainingCalibrationKeepNoKg,
  };
}
