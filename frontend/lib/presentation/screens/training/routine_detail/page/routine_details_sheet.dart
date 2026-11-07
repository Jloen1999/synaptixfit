import 'package:flutter/material.dart';

import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/enums/visibility.dart' as vis;
import '../../../../../domain/models/training/routine.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/training_labels.dart';

/// Datos generales editados en la hoja.
typedef RoutineDetailsChange = ({
  String name,
  String description,
  vis.Visibility visibility,
  TrainingGoal? goal,
});

/// Hoja para editar nombre, descripción, objetivo y visibilidad.
Future<RoutineDetailsChange?> showRoutineDetailsSheet(
  BuildContext context,
  Routine routine,
) => showModalBottomSheet<RoutineDetailsChange>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => _DetailsSheet(routine: routine),
);

class _DetailsSheet extends StatefulWidget {
  const _DetailsSheet({required this.routine});

  final Routine routine;

  @override
  State<_DetailsSheet> createState() => _DetailsSheetState();
}

class _DetailsSheetState extends State<_DetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.routine.name);
  late final _description = TextEditingController(
    text: widget.routine.description ?? '',
  );
  late vis.Visibility _visibility = widget.routine.visibility;
  late TrainingGoal? _goal = widget.routine.goal;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      name: _name.text.trim(),
      description: _description.text.trim(),
      visibility: _visibility,
      goal: _goal,
    ));
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
              Text(
                l10n.trainingEditDetails,
                style: context.textStyles.titleLarge,
              ),
              const SizedBox(height: TokensSpacing.m),
              TextFormField(
                controller: _name,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: l10n.trainingRoutineName,
                ),
                validator: (v) => (v?.trim().length ?? 0) < 3
                    ? l10n.trainingRoutineNameTooShort
                    : null,
              ),
              TextFormField(
                controller: _description,
                maxLength: 2000,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.trainingRoutineDescription,
                ),
              ),
              DropdownButtonFormField<TrainingGoal?>(
                initialValue: _goal,
                decoration: InputDecoration(
                  labelText: l10n.trainingGoal,
                  // Qué significa el objetivo elegido, sin jerga.
                  helperText: _goal?.description(l10n),
                  helperMaxLines: 3,
                ),
                items: [
                  DropdownMenuItem(child: Text(l10n.trainingGoalNone)),
                  for (final goal in TrainingGoal.values)
                    DropdownMenuItem(
                      value: goal,
                      child: Text(goal.label(l10n)),
                    ),
                ],
                onChanged: (v) => setState(() => _goal = v),
              ),
              const SizedBox(height: TokensSpacing.m),
              // Con el texto grande pasa a lista: ninguna opción se corta.
              AppAdaptiveChoice<vis.Visibility>(
                label: l10n.trainingVisibility,
                values: vis.Visibility.values,
                selected: _visibility,
                labelOf: (v) => v.label(l10n),
                iconOf: (v) => v.icon,
                onChanged: (v) => setState(() => _visibility = v),
              ),
              const SizedBox(height: TokensSpacing.l),
              AppPrimaryButton(label: l10n.commonSave, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
