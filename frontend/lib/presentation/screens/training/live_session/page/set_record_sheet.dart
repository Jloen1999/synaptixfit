import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../domain/models/training/session.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/set_fields.dart';
import '../../widgets/training_labels.dart';

/// Resultado de la hoja de serie: guardar o desmarcar.
sealed class SetSheetResult {
  const SetSheetResult();
}

final class SetSheetSave extends SetSheetResult {
  const SetSheetSave(this.record);

  final SetRecord record;
}

/// «Desmarcar serie»: la quita de la sesión (con «Deshacer» en el aviso).
final class SetSheetUnmark extends SetSheetResult {
  const SetSheetUnmark(this.setId);

  final String setId;
}

/// Hoja para apuntar (o corregir) una serie: solo lo que se hizo, con los
/// campos de cómo se mide el ejercicio ([fields]; por defecto repeticiones y
/// kilos). Las repeticiones que faltaron no se preguntan: las calcula el
/// servidor (objetivo − hechas).
Future<SetSheetResult?> showSetRecordSheet(
  BuildContext context, {
  required String title,
  required SetRecord initial,
  String? existingSetId,
  List<SetField> fields = const [SetField.reps, SetField.weight],
}) => showModalBottomSheet<SetSheetResult>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => _SetSheet(
    title: title,
    initial: initial,
    existingSetId: existingSetId,
    fields: fields,
  ),
);

class _SetSheet extends StatefulWidget {
  const _SetSheet({
    required this.title,
    required this.initial,
    required this.existingSetId,
    required this.fields,
  });

  final String title;
  final SetRecord initial;
  final String? existingSetId;
  final List<SetField> fields;

  @override
  State<_SetSheet> createState() => _SetSheetState();
}

class _SetSheetState extends State<_SetSheet> {
  late int _reps = widget.initial.repsDone ?? 10;
  late bool _toFailure = widget.initial.toFailure;

  /// Campos de texto (todos menos las repeticiones, que van con − / +).
  late final Map<SetField, TextEditingController> _text = {
    for (final f in widget.fields)
      if (f != SetField.reps) f: TextEditingController(text: _initialText(f)),
  };
  final _formKey = GlobalKey<FormState>();

  bool get _warmup => widget.initial.warmup;

  String _initialText(SetField f) {
    final r = widget.initial;
    final num? value = switch (f) {
      SetField.weight => r.weightKg,
      SetField.hold => r.durationSeconds,
      SetField.duration =>
        r.durationSeconds == null ? null : (r.durationSeconds! / 60).round(),
      SetField.distance => r.distanceMeters,
      SetField.reps => r.repsDone,
    };
    return value == null ? '' : formatNumber(value.toDouble());
  }

  num? _value(SetField f) {
    final text = _text[f]?.text.trim().replaceAll(',', '.') ?? '';
    if (text.isEmpty) return null;
    return f.decimal ? double.tryParse(text) : int.tryParse(text);
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final has = widget.fields.contains;
    final minutes = _value(SetField.duration);
    final seconds = has(SetField.hold) ? _value(SetField.hold)?.toInt() : null;
    Navigator.of(context).pop(
      SetSheetSave(
        widget.initial.copyWith(
          repsDone: has(SetField.reps) ? _reps : widget.initial.repsDone,
          weightKg: has(SetField.weight)
              ? _value(SetField.weight)?.toDouble()
              : widget.initial.weightKg,
          durationSeconds: has(SetField.duration)
              ? (minutes == null ? null : (minutes * 60).round())
              : seconds ?? widget.initial.durationSeconds,
          distanceMeters: has(SetField.distance)
              ? _value(SetField.distance)?.toInt()
              : widget.initial.distanceMeters,
          // Si faltaron repeticiones lo deduce el servidor con lo apuntado.
          completed: true,
          failedReps: null,
          toFailure: !_warmup && _toFailure,
        ),
      ),
    );
  }

  String _label(SetField f) {
    final l10n = context.localizations;
    return switch (f) {
      SetField.reps => l10n.trainingRepsDone,
      SetField.weight => l10n.trainingParamWeight,
      SetField.hold => l10n.trainingSheetSeconds,
      SetField.duration => l10n.trainingSheetMinutes,
      SetField.distance => l10n.trainingParamDistance,
    };
  }

  Widget _field(SetField f) {
    final l10n = context.localizations;
    if (f == SetField.reps) {
      return AppStepperField(
        label: l10n.trainingRepsDone,
        value: _reps,
        min: 0,
        max: 1000,
        onChanged: (v) => setState(() => _reps = v),
      );
    }
    final (min, max) = f.range;
    // El peso puede quedar vacío (peso corporal); lo demás se pide.
    final optional = f == SetField.weight;
    return Padding(
      padding: const EdgeInsets.only(top: TokensSpacing.s),
      child: TextFormField(
        controller: _text[f],
        keyboardType: TextInputType.numberWithOptions(decimal: f.decimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            f.decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
          ),
        ],
        decoration: InputDecoration(
          labelText: _label(f),
          helperText: optional ? l10n.trainingParamOptional : null,
        ),
        validator: (v) {
          final text = v?.trim().replaceAll(',', '.') ?? '';
          if (text.isEmpty) {
            return optional
                ? null
                : l10n.trainingParamOutOfRange(
                    formatNumber(min.toDouble()),
                    formatNumber(max.toDouble()),
                  );
          }
          final n = double.tryParse(text);
          return n == null || n < min || n > max
              ? l10n.trainingParamOutOfRange(
                  formatNumber(min.toDouble()),
                  formatNumber(max.toDouble()),
                )
              : null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    // «Hasta no poder más» tiene sentido en series de fuerza, no en cardio.
    final askFailure =
        !_warmup &&
        !widget.fields.contains(SetField.duration) &&
        !widget.fields.contains(SetField.distance);
    return Padding(
      padding: EdgeInsets.only(
        left: TokensSpacing.l,
        right: TokensSpacing.l,
        bottom: MediaQuery.viewInsetsOf(context).bottom + TokensSpacing.l,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(widget.title, style: context.textStyles.titleLarge),
              ),
              Text(
                _warmup
                    ? l10n.trainingWarmupSetNumber(widget.initial.setNumber)
                    : l10n.trainingSetNumber(widget.initial.setNumber),
                style: context.textStyles.labelLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              for (final f in widget.fields) _field(f),
              if (askFailure)
                AppHelpToggle(
                  tooltip: l10n.commonHelpAbout(l10n.trainingToFailure),
                  help: l10n.trainingToFailureHint,
                  child: AppFocusOutline(
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _toFailure,
                      onChanged: (v) => setState(() => _toFailure = v ?? false),
                      title: Text(l10n.trainingToFailure),
                    ),
                  ),
                ),
              const SizedBox(height: TokensSpacing.m),
              AppPrimaryButton(label: l10n.commonSave, onPressed: _save),
              if (widget.existingSetId != null) ...[
                const SizedBox(height: TokensSpacing.s),
                // Desmarcar se puede deshacer: gris, sin rojo ni papelera.
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.onSurfaceVariant,
                  ),
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(SetSheetUnmark(widget.existingSetId!)),
                  child: Text(l10n.trainingUnmarkSet),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
