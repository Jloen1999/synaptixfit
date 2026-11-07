import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../domain/models/training/session.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/training_labels.dart';

/// Resultado de la hoja de serie: guardar o borrar.
sealed class SetSheetResult {
  const SetSheetResult();
}

final class SetSheetSave extends SetSheetResult {
  const SetSheetSave(this.record);

  final SetRecord record;
}

final class SetSheetDelete extends SetSheetResult {
  const SetSheetDelete(this.setId);

  final String setId;
}

/// Hoja para registrar (o corregir) una serie.
Future<SetSheetResult?> showSetRecordSheet(
  BuildContext context, {
  required String title,
  required SetRecord initial,
  String? existingSetId,
}) => showModalBottomSheet<SetSheetResult>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) =>
      _SetSheet(title: title, initial: initial, existingSetId: existingSetId),
);

class _SetSheet extends StatefulWidget {
  const _SetSheet({
    required this.title,
    required this.initial,
    required this.existingSetId,
  });

  final String title;
  final SetRecord initial;
  final String? existingSetId;

  @override
  State<_SetSheet> createState() => _SetSheetState();
}

class _SetSheetState extends State<_SetSheet> {
  late int _reps = widget.initial.repsDone ?? 10;
  late int _failed = widget.initial.failedReps;
  late bool _toFailure = widget.initial.toFailure;

  bool get _warmup => widget.initial.warmup;
  late final _weight = TextEditingController(
    text: widget.initial.weightKg == null
        ? ''
        : formatNumber(widget.initial.weightKg!),
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final weight = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    Navigator.of(context).pop(
      SetSheetSave(
        widget.initial.copyWith(
          repsDone: _reps,
          weightKg: weight,
          // Una sola pregunta: si no faltó ninguna repetición, está completada.
          completed: _warmup || _failed == 0,
          failedReps: _warmup ? 0 : _failed,
          toFailure: !_warmup && _toFailure,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
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
              Text(
                _warmup
                    ? l10n.trainingWarmupSetNumber(widget.initial.setNumber)
                    : l10n.trainingSetNumber(widget.initial.setNumber),
                style: context.textStyles.labelLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              AppStepperField(
                label: l10n.trainingRepsDone,
                value: _reps,
                min: 0,
                max: 1000,
                onChanged: (v) => setState(() => _reps = v),
              ),
              if (_warmup)
                Text(
                  l10n.trainingWarmupSetsHint,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                )
              else ...[
                AppStepperField(
                  label: l10n.trainingMissedReps,
                  value: _failed,
                  min: 0,
                  max: 1000,
                  onChanged: (v) => setState(() => _failed = v),
                ),
                Text(
                  l10n.trainingMissedRepsHint,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                AppFocusOutline(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _toFailure,
                    onChanged: (v) => setState(() => _toFailure = v),
                    title: Text(l10n.trainingToFailure),
                    subtitle: Text(l10n.trainingToFailureHint),
                  ),
                ),
              ],
              const SizedBox(height: TokensSpacing.s),
              TextFormField(
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: l10n.trainingParamWeight,
                  helperText: l10n.trainingParamOptional,
                ),
                validator: (v) {
                  final text = v?.trim().replaceAll(',', '.') ?? '';
                  if (text.isEmpty) return null;
                  final n = double.tryParse(text);
                  return n == null || n < 0 || n > 500
                      ? l10n.trainingParamOutOfRange('0', '500')
                      : null;
                },
              ),
              const SizedBox(height: TokensSpacing.m),
              AppPrimaryButton(label: l10n.commonSave, onPressed: _save),
              if (widget.existingSetId != null) ...[
                const SizedBox(height: TokensSpacing.s),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.error,
                  ),
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(SetSheetDelete(widget.existingSetId!)),
                  icon: const Icon(AppIcons.delete),
                  label: Text(l10n.trainingDeleteSet),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
