import 'package:flutter/material.dart';

import '../../../../domain/enums/planner_enums.dart';
import '../../../../domain/models/planner/deadline.dart';
import '../../../../domain/models/planner/planner_options.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'planner_form_fields.dart';
import 'planner_visuals.dart';

/// Formulario corto de entrega o examen: el único sitio donde se apuntan
/// (ADR 0039), se abra desde Académico, la asignatura, el calendario o la
/// lista. Al crear, el título lleva el foco y la fecha tiene atajos, así se
/// guarda en dos o tres toques. Devuelve el [DeadlineDraft] al guardar.
class DeadlineFormSheet extends StatefulWidget {
  const DeadlineFormSheet({
    super.key,
    this.deadline,
    required this.subjects,
    this.initialType,
    this.initialSubjectId,
    this.initialDue,
    this.onDelete,
  });

  final Deadline? deadline;
  final List<SubjectOption> subjects;

  /// Al crear: tipo, asignatura y fecha que ya se saben por dónde se abrió
  /// (el «Examen» del calendario, la asignatura abierta, el hueco tocado).
  final DeadlineType? initialType;
  final String? initialSubjectId;
  final DateTime? initialDue;

  /// Al editar: «Eliminar» (con «Deshacer» en la lista).
  final VoidCallback? onDelete;

  static Future<DeadlineDraft?> show(
    BuildContext context, {
    Deadline? deadline,
    required List<SubjectOption> subjects,
    DeadlineType? initialType,
    String? initialSubjectId,
    DateTime? initialDue,
    VoidCallback? onDelete,
  }) => showModalBottomSheet<DeadlineDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => DeadlineFormSheet(
      deadline: deadline,
      subjects: subjects,
      initialType: initialType,
      initialSubjectId: initialSubjectId,
      initialDue: initialDue,
      onDelete: onDelete,
    ),
  );

  @override
  State<DeadlineFormSheet> createState() => _DeadlineFormSheetState();
}

class _DeadlineFormSheetState extends State<DeadlineFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _titleFocus = FocusNode();
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
        widget.initialDue ??
        DateTime.now()
            .add(const Duration(days: _defaultDays))
            .copyWith(hour: 23, minute: 59);
    _title.text = d?.title ?? '';
    _description.text = d?.description ?? '';
    _type = d?.type ?? widget.initialType ?? DeadlineType.assignment;
    _difficulty = d?.difficulty ?? PlannerPriority.medium;
    _day = DateTime(due.year, due.month, due.day);
    _time = due.hour * 60 + due.minute;
    _subjectId = d?.subjectId ?? widget.initialSubjectId;
    // Al crear se escribe directamente el título: un toque menos.
    if (d == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _titleFocus.requestFocus();
      });
    }
  }

  /// Días hasta la fecha propuesta al crear (la entrega típica: una semana).
  static const _defaultDays = 7;

  /// Atajos de fecha: mañana y dentro de una semana (el resto, con el
  /// calendario del campo).
  static const _quickDays = [1, _defaultDays];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _titleFocus.dispose();
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
              focusNode: _titleFocus,
              textCapitalization: TextCapitalization.sentences,
              // «Hecho» del teclado guarda: «Guardar» puede quedar debajo.
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
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
            const SizedBox(height: TokensSpacing.xs),
            _QuickDates(
              days: _quickDays,
              selected: _day,
              onSelected: (day) => setState(() => _day = day),
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
            if (widget.deadline != null && widget.onDelete != null) ...[
              const SizedBox(height: TokensSpacing.s),
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.error,
                  ),
                  icon: const Icon(AppIcons.delete),
                  label: Text(l10n.plannerDeleteDeadline),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onDelete!();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Atajos de fecha («Mañana», «En una semana»): elegir uno es un toque, sin
/// abrir el calendario. Marca el que coincide con la fecha elegida.
class _QuickDates extends StatelessWidget {
  const _QuickDates({
    required this.days,
    required this.selected,
    required this.onSelected,
  });

  final List<int> days;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return Wrap(
      spacing: TokensSpacing.s,
      runSpacing: TokensSpacing.xs,
      children: [
        for (final n in days)
          Builder(
            builder: (context) {
              final day = today.add(Duration(days: n));
              return ChoiceChip(
                label: Text(
                  n == 1 ? l10n.plannerDueTomorrow : l10n.plannerDueInAWeek,
                ),
                selected: DateUtils.isSameDay(day, selected),
                onSelected: (_) => onSelected(day),
              );
            },
          ),
      ],
    );
  }
}
