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
  late bool _completed = widget.initial.completed;
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
          completed: _completed,
          failedReps: _failed,
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
                l10n.trainingSetNumber(widget.initial.setNumber),
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
              AppStepperField(
                label: l10n.trainingFailedReps,
                value: _failed,
                min: 0,
                max: 1000,
                onChanged: (v) => setState(() => _failed = v),
              ),
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
              AppFocusOutline(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.trainingSetCompleted),
                  value: _completed,
                  onChanged: (v) => setState(() => _completed = v),
                ),
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
                  icon: const Icon(Icons.delete_outline_rounded),
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
