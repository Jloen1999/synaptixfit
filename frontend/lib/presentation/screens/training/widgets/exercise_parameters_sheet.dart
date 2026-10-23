import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/models/training/routine.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'training_labels.dart';

/// Abre la hoja de edición de parámetros y devuelve los nuevos (o `null`).
Future<ExerciseParameters?> showExerciseParametersSheet(
  BuildContext context, {
  required String title,
  required ExerciseParameters initial,
}) => showModalBottomSheet<ExerciseParameters>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => _ParametersSheet(title: title, initial: initial),
);

class _ParametersSheet extends StatefulWidget {
  const _ParametersSheet({required this.title, required this.initial});

  final String title;
  final ExerciseParameters initial;

  @override
  State<_ParametersSheet> createState() => _ParametersSheetState();
}

class _ParametersSheetState extends State<_ParametersSheet> {
  final _formKey = GlobalKey<FormState>();
  late int _sets = widget.initial.sets;
  late int _reps = widget.initial.reps;
  late int _rest = widget.initial.restSeconds;
  late final _weight = TextEditingController(
    text: widget.initial.weightKg == null
        ? ''
        : formatNumber(widget.initial.weightKg!),
  );
  late final _duration = TextEditingController(
    text: widget.initial.targetDurationSeconds == null
        ? ''
        : (widget.initial.targetDurationSeconds! / 60).ceil().toString(),
  );
  late final _distance = TextEditingController(
    text: widget.initial.distanceMeters?.toString() ?? '',
  );
  late final _isometric = TextEditingController(
    text: widget.initial.isometricSeconds?.toString() ?? '',
  );

  @override
  void dispose() {
    _weight.dispose();
    _duration.dispose();
    _distance.dispose();
    _isometric.dispose();
    super.dispose();
  }

  String? _range(String? value, num min, num max) {
    final text = value?.trim().replaceAll(',', '.') ?? '';
    if (text.isEmpty) return null;
    final parsed = num.tryParse(text);
    if (parsed == null || parsed < min || parsed > max) {
      return context.localizations.trainingParamOutOfRange(
        formatNumber(min.toDouble()),
        formatNumber(max.toDouble()),
      );
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    double? number(TextEditingController c) =>
        double.tryParse(c.text.trim().replaceAll(',', '.'));
    final weight = number(_weight);
    final minutes = number(_duration);
    final distance = number(_distance);
    final isometric = number(_isometric);
    final weightChanged = weight != widget.initial.weightKg;
    Navigator.of(context).pop(
      ExerciseParameters(
        sets: _sets,
        reps: _reps,
        restSeconds: _rest,
        weightKg: weight,
        weightsKg: weightChanged ? null : widget.initial.weightsKg,
        targetDurationSeconds: minutes == null ? null : (minutes * 60).round(),
        distanceMeters: distance?.round(),
        isometricSeconds: isometric?.round(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final decimal = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    final digits = [FilteringTextInputFormatter.digitsOnly];
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
              Text(widget.title, style: context.textStyles.titleLarge),
              const SizedBox(height: TokensSpacing.m),
              AppStepperField(
                label: l10n.trainingParamSets,
                value: _sets,
                min: ExerciseParameters.minSets,
                max: ExerciseParameters.maxSets,
                onChanged: (v) => setState(() => _sets = v),
              ),
              AppStepperField(
                label: l10n.trainingParamReps,
                value: _reps,
                min: ExerciseParameters.minReps,
                max: ExerciseParameters.maxReps,
                onChanged: (v) => setState(() => _reps = v),
              ),
              AppStepperField(
                label: l10n.trainingParamRest,
                value: _rest,
                min: ExerciseParameters.minRest,
                max: ExerciseParameters.maxRest,
                step: 15,
                display: (v) => l10n.trainingChipRest(v),
                onChanged: (v) => setState(() => _rest = v),
              ),
              const SizedBox(height: TokensSpacing.m),
              _NumberField(
                controller: _weight,
                label: l10n.trainingParamWeight,
                formatters: decimal,
                validator: (v) => _range(v, 0, ExerciseParameters.maxWeight),
              ),
              _NumberField(
                controller: _duration,
                label: l10n.trainingParamDuration,
                formatters: digits,
                validator: (v) =>
                    _range(v, 1, ExerciseParameters.maxDuration ~/ 60),
              ),
              _NumberField(
                controller: _distance,
                label: l10n.trainingParamDistance,
                formatters: digits,
                validator: (v) => _range(v, 1, ExerciseParameters.maxDistance),
              ),
              _NumberField(
                controller: _isometric,
                label: l10n.trainingParamIsometric,
                formatters: digits,
                validator: (v) => _range(v, 1, ExerciseParameters.maxIsometric),
              ),
              const SizedBox(height: TokensSpacing.m),
              AppPrimaryButton(label: l10n.commonSave, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.formatters,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final List<TextInputFormatter> formatters;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.s),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: formatters,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          helperText: context.localizations.trainingParamOptional,
        ),
      ),
    );
  }
}
