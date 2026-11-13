import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../domain/models/training/routine.dart';
import '../../../extensions/context_extensions.dart';
import '../../../l10n/gen_l10n/app_localizations.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'exercise_thumbnail.dart';
import 'set_fields.dart';
import 'training_labels.dart';

/// Ejercicio de un día de rutina: foto, nombre y resumen grande («4 series ·
/// 12–8 reps · 40 kg») arriba; debajo su tabla de series con los campos que
/// aplican a cómo se mide ([SetFields]) y, en una fila propia, sus acciones con
/// texto (cambiar, quitar, subir, bajar). Todo lo de la tarjeta es de ESE
/// ejercicio: no hay menús que obliguen a adivinar a cuál se refieren.
///
/// Con [bare] (dentro de la tarjeta del día) no lleva tarjeta propia: nada de
/// tarjeta dentro de tarjeta, y la tabla gana ancho.
class PlannedExerciseCard extends StatefulWidget {
  const PlannedExerciseCard({
    super.key,
    required this.exercise,
    required this.position,
    required this.count,
    required this.editable,
    required this.onChanged,
    this.enabled = true,
    this.bare = false,
    this.onOpen,
    this.onReplace,
    this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
  });

  final PlannedExercise exercise;

  /// Posición (desde 1) y total del día: se anuncian al moverlo.
  final int position;
  final int count;

  /// Rutina propia: las cifras se pueden tocar.
  final bool editable;

  /// Falso mientras otra operación completa está en curso: los campos siguen
  /// en su sitio (sin perder el foco), solo desactivados.
  final bool enabled;
  final bool bare;
  final ValueChanged<ExerciseParameters> onChanged;
  final VoidCallback? onOpen;
  final VoidCallback? onReplace;
  final VoidCallback? onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  State<PlannedExerciseCard> createState() => _PlannedExerciseCardState();
}

class _PlannedExerciseCardState extends State<PlannedExerciseCard> {
  final _upFocus = FocusNode();
  final _downFocus = FocusNode();

  @override
  void didUpdateWidget(PlannedExerciseCard old) {
    super.didUpdateWidget(old);
    // Al llegar arriba o abajo del todo su botón se desactiva: el foco pasa
    // al contrario en vez de perderse (WCAG 2.4.3).
    if (widget.onMoveUp == null && _upFocus.hasFocus) {
      _downFocus.requestFocus();
    } else if (widget.onMoveDown == null && _downFocus.hasFocus) {
      _upFocus.requestFocus();
    }
    if (widget.position != old.position &&
        (_upFocus.hasFocus || _downFocus.hasFocus)) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        context.localizations.trainingExerciseMovedTo(
          widget.exercise.exerciseName,
          widget.position,
          widget.count,
        ),
        Directionality.of(context),
      );
    }
  }

  @override
  void dispose() {
    _upFocus.dispose();
    _downFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final e = widget.exercise;
    final fields = SetFields.of(e);
    final name = e.exerciseName;
    final hasActions =
        widget.onReplace != null ||
        widget.onRemove != null ||
        widget.onMoveUp != null ||
        widget.onMoveDown != null;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFocusOutline(
          borderRadius: BorderRadius.circular(TokensRadius.m),
          child: InkWell(
            onTap: widget.onOpen,
            borderRadius: BorderRadius.circular(TokensRadius.m),
            child: Row(
              children: [
                ExerciseThumbnail(
                  url: e.thumbnailUrl,
                  size: TokensSize.listTileMin,
                ),
                const SizedBox(width: TokensSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: context.textStyles.titleMedium),
                      const SizedBox(height: TokensSpacing.xxs),
                      // Lo que más importa a primera vista: series ×
                      // repeticiones y peso, en grande.
                      Text(
                        plannedSummary(l10n, e.parameters, fields),
                        style: context.textStyles.titleLarge?.copyWith(
                          color: context.colors.primary,
                        ),
                      ),
                      if (!e.exerciseActive)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: TokensSpacing.xxs,
                          ),
                          child: AppPill(
                            icon: Icons.block_rounded,
                            label: l10n.trainingExerciseInactive,
                            color: context.palette.warning,
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.onOpen != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.colors.onSurfaceVariant,
                    semanticLabel: l10n.trainingHowToNamed(name),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: TokensSpacing.m),
        PlannedSetsTable(
          parameters: e.parameters,
          fields: fields,
          exerciseName: name,
          editable: widget.editable,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
        ),
        if (hasActions) ...[
          const Divider(height: TokensSpacing.l),
          // Con letra grande las acciones bajan a otra fila en vez de
          // desbordar.
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            overflowAlignment: OverflowBarAlignment.start,
            overflowSpacing: TokensSpacing.xs,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    focusNode: _upFocus,
                    tooltip: l10n.trainingMoveUpNamed(name),
                    onPressed: widget.onMoveUp,
                    icon: const Icon(AppIcons.moveUp),
                  ),
                  IconButton(
                    focusNode: _downFocus,
                    tooltip: l10n.trainingMoveDownNamed(name),
                    onPressed: widget.onMoveDown,
                    icon: const Icon(AppIcons.moveDown),
                  ),
                ],
              ),
              Wrap(
                spacing: TokensSpacing.xs,
                children: [
                  if (widget.onReplace != null)
                    Semantics(
                      button: true,
                      label: l10n.trainingReplaceExerciseNamed(name),
                      excludeSemantics: true,
                      onTap: widget.onReplace,
                      child: TextButton.icon(
                        onPressed: widget.onReplace,
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: Text(l10n.trainingReplaceShort),
                      ),
                    ),
                  if (widget.onRemove != null)
                    Semantics(
                      button: true,
                      label: l10n.trainingRemoveExerciseNamed(name),
                      excludeSemantics: true,
                      onTap: widget.onRemove,
                      // «Quitar del plan»: mismo icono que quitar una
                      // serie y sin rojo (no borra nada para siempre).
                      child: TextButton.icon(
                        onPressed: widget.onRemove,
                        icon: const Icon(AppIcons.remove),
                        label: Text(l10n.trainingRemoveShort),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
    return widget.bare ? content : AppCard(child: content);
  }
}

/// Resumen de lo previsto: «4 series · 12–8 reps · 30–40 kg», «3 series ·
/// 30 s», «25 min · 5 km».
String plannedSummary(
  AppLocalizations l10n,
  ExerciseParameters p,
  SetFields fields,
) {
  String range<T extends num>(List<T> values, String Function(String) unit) {
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    return lo == hi
        ? unit(formatNumber(lo.toDouble()))
        : unit(
            l10n.trainingValueRange(
              formatNumber(values.first.toDouble()),
              formatNumber(values.last.toDouble()),
            ),
          );
  }

  final sets = [for (var n = 1; n <= p.sets; n++) n];
  if (fields.isCardio) {
    final distance = p.distanceMeters;
    return [
      if (p.sets > 1) l10n.trainingSummarySets(p.sets),
      if (p.targetDurationSeconds != null)
        l10n.trainingMinutes((p.targetDurationSeconds! / 60).round()),
      if (distance != null)
        distance >= 1000
            ? l10n.trainingChipDistanceKm(formatNumber(distance / 1000))
            : l10n.trainingChipDistanceM(distance),
    ].join(' · ');
  }
  final weights = [
    for (final n in sets)
      if ((p.weightForSet(n) ?? 0) > 0) p.weightForSet(n)!,
  ];
  return [
    l10n.trainingSummarySets(p.sets),
    if (fields.isHold)
      range([
        for (final n in sets) p.holdForSet(n) ?? 0,
      ], l10n.trainingSecondsUnit)
    else
      range([for (final n in sets) p.repsForSet(n)], l10n.trainingRepsUnit),
    if (fields.has(SetField.weight) && weights.isNotEmpty)
      range(weights, l10n.trainingKgUnit),
  ].join(' · ');
}

/// Tabla de series de un ejercicio planificado: «Serie · Reps · Kg» (o lo que
/// aplique), una fila por serie con campos que se tocan para cambiarlos, quitar
/// una serie concreta y añadir otra (copia la última). Debajo, el descanso.
/// En cardio, una sola fila con minutos y metros. Si una cifra no cabe cómoda
/// (pantalla estrecha o letra grande), cada serie va en dos líneas con la
/// etiqueta encima de cada campo.
class PlannedSetsTable extends StatefulWidget {
  const PlannedSetsTable({
    super.key,
    required this.parameters,
    required this.fields,
    required this.exerciseName,
    required this.editable,
    required this.onChanged,
    this.enabled = true,
  });

  final ExerciseParameters parameters;
  final SetFields fields;
  final String exerciseName;
  final bool editable;
  final bool enabled;
  final ValueChanged<ExerciseParameters> onChanged;

  @override
  State<PlannedSetsTable> createState() => _PlannedSetsTableState();
}

class _PlannedSetsTableState extends State<PlannedSetsTable> {
  /// Celdas con un valor fuera de rango (campo → series).
  final _invalid = <SetField, Set<int>>{};

  /// Al quitar una serie su botón desaparece: el foco pasa a «Añadir serie».
  final _addFocus = FocusNode();

  ExerciseParameters get p => widget.parameters;

  @override
  void dispose() {
    _addFocus.dispose();
    super.dispose();
  }

  void _validity(SetField field, int set, bool valid) => setState(() {
    final sets = _invalid.putIfAbsent(field, () => <int>{});
    valid ? sets.remove(set) : sets.add(set);
    if (sets.isEmpty) _invalid.remove(field);
  });

  void _commit(SetField field, int set, num? value) {
    final next = switch (field) {
      SetField.reps => p.withSetValues(set, setReps: value?.toInt()),
      SetField.hold => p.withSetValues(set, hold: value?.toInt()),
      SetField.weight => _withWeight(set, value?.toDouble()),
      SetField.duration => p.copyWith(
        targetDurationSeconds: value == null ? null : (value * 60).round(),
      ),
      SetField.distance => p.copyWith(distanceMeters: value?.toInt()),
    };
    if (next != p) widget.onChanged(next);
  }

  void _removeSet(int set) {
    widget.onChanged(p.withoutSet(set));
    _addFocus.requestFocus();
  }

  /// Vaciar el peso de una serie la deja sin carga; si ninguna lleva, el
  /// ejercicio pasa a ser sin peso.
  ExerciseParameters _withWeight(int set, double? kg) {
    final next = p.withSetValues(set, weight: kg ?? 0);
    final anyLoad = [
      for (var n = 1; n <= next.sets; n++) next.weightForSet(n) ?? 0,
    ].any((w) => w > 0);
    return anyLoad ? next : next.withSetValues(1, clearWeight: true);
  }

  num? _value(SetField field, int set) => switch (field) {
    SetField.reps => p.repsForSet(set),
    SetField.weight => p.weightForSet(set),
    SetField.hold => p.holdForSet(set),
    SetField.duration =>
      p.targetDurationSeconds == null
          ? null
          : (p.targetDurationSeconds! / 60).round(),
    SetField.distance => p.distanceMeters,
  };

  Widget _cell(SetField field, int set, {bool single = false}) {
    final l10n = context.localizations;
    final value = _value(field, set);
    final (min, max) = field.range;
    final spoken = single
        ? field.spoken(context)
        : l10n.trainingSetCellSemantics(set, field.spoken(context));
    final shown = value == null ? '–' : formatNumber(value.toDouble());
    if (!widget.editable) {
      return Semantics(
        label: l10n.trainingFieldValueSpoken(spoken, shown),
        excludeSemantics: true,
        child: Text(
          shown,
          textAlign: TextAlign.center,
          style: context.textStyles.titleMedium,
        ),
      );
    }
    return AppNumberCell(
      // La clave por serie evita que una celda herede el texto de otra al
      // quitar series.
      key: ValueKey('${field.name}-$set'),
      value: value,
      enabled: widget.enabled,
      semanticLabel: spoken,
      min: min,
      max: max,
      decimal: field.decimal,
      allowEmpty:
          field == SetField.weight ||
          field == SetField.distance ||
          field == SetField.duration,
      hint: '–',
      invalidMessage: l10n.trainingSetFieldInvalid(
        field.spoken(context),
        formatNumber(min.toDouble()),
        formatNumber(max.toDouble()),
      ),
      onValidityChanged: (valid) => _validity(field, set, valid),
      onCommitted: (v) => _commit(field, set, v),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final fields = widget.fields;
    final header = context.textStyles.labelMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final badge = math.max(
      TokensLayout.minTouchTarget,
      context.scaled(TokensSize.iconM),
    );
    Widget setBadge(int n) => SizedBox(
      width: badge,
      child: ExcludeSemantics(
        child: Text('$n', style: context.textStyles.titleMedium),
      ),
    );
    // «Quitar del plan» (vocabulario §4): borra la serie de la rutina, no lo
    // apuntado. El lector oye cuál: «Quitar del plan la serie 2 de Press».
    Widget removeButton(int n) {
      final onTap = !widget.enabled || p.sets <= ExerciseParameters.minSets
          ? null
          : () => _removeSet(n);
      return Tooltip(
        message: l10n.trainingRemoveFromPlan,
        excludeFromSemantics: true,
        child: Semantics(
          button: true,
          enabled: onTap != null,
          label: l10n.trainingRemoveSetNamed(n, widget.exerciseName),
          excludeSemantics: true,
          onTap: onTap,
          child: IconButton(
            onPressed: onTap,
            icon: const Icon(AppIcons.remove),
          ),
        ),
      );
    }

    final table = LayoutBuilder(
      builder: (context, constraints) {
        if (fields.isCardio) {
          return Row(
            children: [
              for (final (i, f) in fields.fields.indexed) ...[
                if (i > 0) const SizedBox(width: TokensSpacing.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          f.header(context),
                          textAlign: TextAlign.center,
                          style: header,
                        ),
                      ),
                      const SizedBox(height: TokensSpacing.xs),
                      _cell(f, 1, single: true),
                    ],
                  ),
                ),
              ],
            ],
          );
        }
        final n = fields.fields.length;
        final trailing = widget.editable ? TokensLayout.minTouchTarget : 0.0;
        final perCell =
            (constraints.maxWidth - badge - trailing - TokensSpacing.s * n) / n;
        // Si una cifra no cabe cómoda, cada serie en dos líneas.
        final stacked = perCell < context.scaled(TokensSize.stepperValue);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!stacked)
              ExcludeSemantics(
                child: Row(
                  children: [
                    SizedBox(
                      width: badge,
                      child: Text(l10n.trainingSetColSet, style: header),
                    ),
                    for (final f in fields.fields) ...[
                      const SizedBox(width: TokensSpacing.s),
                      Expanded(
                        child: Text(
                          f.header(context),
                          textAlign: TextAlign.center,
                          style: header,
                        ),
                      ),
                    ],
                    SizedBox(width: trailing),
                  ],
                ),
              ),
            for (var set = 1; set <= p.sets; set++)
              Padding(
                padding: const EdgeInsets.only(top: TokensSpacing.xs),
                child: stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ExcludeSemantics(
                            child: Text(
                              l10n.trainingSetNumber(set),
                              style: context.textStyles.titleSmall,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (final f in fields.fields) ...[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ExcludeSemantics(
                                        child: Text(
                                          f.header(context),
                                          style: header,
                                        ),
                                      ),
                                      _cell(f, set),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: TokensSpacing.s),
                              ],
                              if (widget.editable) removeButton(set),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          setBadge(set),
                          for (final f in fields.fields) ...[
                            const SizedBox(width: TokensSpacing.s),
                            Expanded(child: _cell(f, set)),
                          ],
                          if (widget.editable) ...[
                            const SizedBox(width: TokensSpacing.s),
                            removeButton(set),
                          ],
                        ],
                      ),
              ),
          ],
        );
      },
    );

    final errors = [
      for (final MapEntry(key: f, value: sets) in _invalid.entries)
        for (final set in sets)
          l10n.trainingSetFieldInvalidInSet(
            set,
            f.spoken(context),
            formatNumber(f.range.$1.toDouble()),
            formatNumber(f.range.$2.toDouble()),
          ),
    ];
    final canAdd = widget.enabled && p.sets < ExerciseParameters.maxSets;
    void add() => widget.onChanged(p.withSetCount(p.sets + 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        table,
        if (errors.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: TokensSpacing.xs),
            child: Text(
              errors.join('\n'),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.error,
              ),
            ),
          ),
        if (widget.editable && !fields.isCardio)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Semantics(
              button: true,
              label: l10n.trainingAddSetNamed(widget.exerciseName),
              excludeSemantics: true,
              onTap: canAdd ? add : null,
              child: TextButton.icon(
                focusNode: _addFocus,
                onPressed: canAdd ? add : null,
                icon: const Icon(AppIcons.add),
                label: Text(l10n.trainingAddSet),
              ),
            ),
          ),
        if (widget.editable) ...[
          if (fields.isCardio)
            AppStepperField(
              label: l10n.trainingParamSets,
              value: p.sets,
              min: ExerciseParameters.minSets,
              max: ExerciseParameters.maxSets,
              onChanged: (v) => widget.onChanged(p.withSetCount(v)),
            ),
          // El descanso es secundario: fila compacta debajo de las series.
          AppStepperField(
            label: l10n.trainingParamRest,
            value: p.restSeconds,
            min: ExerciseParameters.minRest,
            max: ExerciseParameters.maxRest,
            step: 15,
            display: (v) => l10n.trainingChipRest(v),
            onChanged: (v) => widget.onChanged(p.copyWith(restSeconds: v)),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: TokensSpacing.s),
            child: Text(
              l10n.trainingRestValue(l10n.trainingChipRest(p.restSeconds)),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
