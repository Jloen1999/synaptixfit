import 'package:flutter/material.dart';

import '../../../../domain/enums/planner_enums.dart';
import '../../../../domain/models/planner/deadline.dart';
import '../../../../domain/models/planner/planner_options.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'planner_form_fields.dart';
import 'planner_visuals.dart';

/// Formulario de entrega/examen. Devuelve el [DeadlineDraft] al guardar.
class DeadlineFormSheet extends StatefulWidget {
  const DeadlineFormSheet({super.key, this.deadline, required this.subjects});

  final Deadline? deadline;
  final List<SubjectOption> subjects;

  static Future<DeadlineDraft?> show(
    BuildContext context, {
    Deadline? deadline,
    required List<SubjectOption> subjects,
  }) => showModalBottomSheet<DeadlineDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => DeadlineFormSheet(deadline: deadline, subjects: subjects),
  );

  @override
  State<DeadlineFormSheet> createState() => _DeadlineFormSheetState();
}

class _DeadlineFormSheetState extends State<DeadlineFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  late DeadlineType _type;
  late PlannerPriority _difficulty;
  late DateTime _day;
  late int _time;
  String? _subjectId;

  @override
  void initState() {
    super.initState();
    final d = widget.deadline;
    final due =
        d?.dueAt ??
        DateTime.now()
            .add(const Duration(days: 7))
            .copyWith(hour: 23, minute: 59);
    _title.text = d?.title ?? '';
    _description.text = d?.description ?? '';
    _type = d?.type ?? DeadlineType.assignment;
    _difficulty = d?.difficulty ?? PlannerPriority.medium;
    _day = DateTime(due.year, due.month, due.day);
    _time = due.hour * 60 + due.minute;
    _subjectId = d?.subjectId;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final description = _description.text.trim();
    Navigator.of(context).pop(
      DeadlineDraft(
        title: _title.text.trim(),
        type: _type,
        dueAt: DateTime(
          _day.year,
          _day.month,
          _day.day,
          _time ~/ 60,
          _time % 60,
        ),
        difficulty: _difficulty,
        description: description.isEmpty ? null : description,
        subjectId: _subjectId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            TokensSpacing.m,
            0,
            TokensSpacing.m,
            TokensSpacing.l,
          ),
          children: [
            Text(
              widget.deadline == null
                  ? l10n.plannerNewDeadline
                  : l10n.plannerEditDeadline,
              style: context.textStyles.titleLarge,
            ),
            const SizedBox(height: TokensSpacing.m),
            AppTextField(
              label: l10n.plannerFieldTitle,
              controller: _title,
              icon: Icons.title_rounded,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.validationRequired
                  : null,
            ),
            const SizedBox(height: TokensSpacing.m),
            Wrap(
              spacing: TokensSpacing.xs,
              runSpacing: TokensSpacing.xs,
              children: [
                for (final t in DeadlineType.values)
                  ChoiceChip(
                    avatar: Icon(t.icon, size: 18),
                    label: Text(t.label(context)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: TokensSpacing.m),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PickerField(
                    label: l10n.plannerFieldDueDate,
                    value: PlannerFormats.dayMonth(_day),
                    icon: Icons.event_rounded,
                    onTap: () async {
                      final picked = await pickPlannerDate(
                        context,
                        initial: _day,
                      );
                      if (picked != null) setState(() => _day = picked);
                    },
                  ),
                ),
                const SizedBox(width: TokensSpacing.s),
                Expanded(
                  flex: 2,
                  child: PickerField(
                    label: l10n.plannerFieldDueTime,
                    value: PlannerFormats.minutes(_time),
                    icon: Icons.schedule_rounded,
                    onTap: () async {
                      final m = await pickPlannerTime(context, _time);
                      if (m != null) setState(() => _time = m);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: TokensSpacing.m),
            DropdownButtonFormField<String?>(
              initialValue: _subjectId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.plannerFieldSubject,
                prefixIcon: const Icon(Icons.class_rounded),
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n.plannerNoSubject),
                ),
                for (final s in widget.subjects)
                  DropdownMenuItem(value: s.id, child: Text(s.name)),
                if (_subjectId != null &&
                    !widget.subjects.any((s) => s.id == _subjectId))
                  DropdownMenuItem(
                    value: _subjectId,
                    child: Text(l10n.plannerFieldSubject),
                  ),
              ],
              onChanged: (v) => setState(() => _subjectId = v),
            ),
            const SizedBox(height: TokensSpacing.m),
            AppSegmentedChoice<PlannerPriority>(
              label: l10n.plannerFieldDifficulty,
              values: PlannerPriority.values,
              selected: _difficulty,
              labelOf: (p) => p.label(context),
              onChanged: (p) {
                if (p != null) setState(() => _difficulty = p);
              },
            ),
            const SizedBox(height: TokensSpacing.m),
            AppTextField(
              label: l10n.plannerFieldDescription,
              controller: _description,
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: TokensSpacing.l),
            AppPrimaryButton(label: l10n.commonSave, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
