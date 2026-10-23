import 'package:flutter/material.dart';

import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/models/training/exercise.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/training_labels.dart';

/// Hoja de filtros del catálogo. Devuelve los nuevos criterios (o `null`).
Future<ExerciseSearchCriteria?> showExerciseFiltersSheet(
  BuildContext context, {
  required ExerciseSearchCriteria criteria,
  required ExerciseFilterOptions? options,
}) => showModalBottomSheet<ExerciseSearchCriteria>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => _FiltersSheet(criteria: criteria, options: options),
);

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.criteria, required this.options});

  final ExerciseSearchCriteria criteria;
  final ExerciseFilterOptions? options;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late ExerciseSearchCriteria _c = widget.criteria;

  Widget _catalog(
    String label,
    List<CatalogItem> items,
    int? value,
    ValueChanged<int?> onChanged,
  ) {
    final l10n = context.localizations;
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.m),
      child: DropdownButtonFormField<int?>(
        initialValue: items.any((i) => i.id == value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          DropdownMenuItem(child: Text(l10n.trainingFilterAny)),
          for (final item in items)
            DropdownMenuItem(value: item.id, child: Text(item.name)),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _chips<T>(
    String label,
    List<T> values,
    T? selected,
    String Function(T) text,
    ValueChanged<T?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textStyles.labelLarge),
          const SizedBox(height: TokensSpacing.xs),
          Wrap(
            spacing: TokensSpacing.xs,
            runSpacing: TokensSpacing.xs,
            children: [
              for (final v in values)
                FilterChip(
                  label: Text(text(v)),
                  selected: v == selected,
                  onSelected: (on) => onChanged(on ? v : null),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final o = widget.options ?? const ExerciseFilterOptions();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.l,
        0,
        TokensSpacing.l,
        TokensSpacing.l,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.trainingFilters,
                    style: context.textStyles.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(
                    () => _c = ExerciseSearchCriteria(query: _c.query),
                  ),
                  child: Text(l10n.trainingClearFilters),
                ),
              ],
            ),
            const SizedBox(height: TokensSpacing.m),
            _catalog(
              l10n.trainingFilterBodyPart,
              o.bodyParts,
              _c.bodyPartId,
              (v) => setState(() => _c = _c.copyWith(bodyPartId: v)),
            ),
            _catalog(
              l10n.trainingFilterMuscle,
              o.muscles,
              _c.muscleId,
              (v) => setState(() => _c = _c.copyWith(muscleId: v)),
            ),
            _catalog(
              l10n.trainingFilterEquipment,
              o.equipment,
              _c.equipmentId,
              (v) => setState(() => _c = _c.copyWith(equipmentId: v)),
            ),
            _chips<ExerciseDifficulty>(
              l10n.trainingFilterDifficulty,
              ExerciseDifficulty.values,
              _c.difficulty,
              (v) => v.label(l10n),
              (v) => setState(() => _c = _c.copyWith(difficulty: v)),
            ),
            _chips<Modality>(
              l10n.trainingFilterModality,
              Modality.values,
              _c.modality,
              (v) => v.label(l10n),
              (v) => setState(() => _c = _c.copyWith(modality: v)),
            ),
            _chips<TrainingGoal>(
              l10n.trainingFilterPurpose,
              TrainingGoal.values,
              _c.purpose,
              (v) => v.label(l10n),
              (v) => setState(() => _c = _c.copyWith(purpose: v)),
            ),
            AppPrimaryButton(
              label: l10n.trainingApplyFilters,
              onPressed: () => Navigator.of(context).pop(_c),
            ),
          ],
        ),
      ),
    );
  }
}
