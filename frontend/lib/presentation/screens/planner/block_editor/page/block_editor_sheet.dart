import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/planner_enums.dart';
import '../../../../../domain/models/planner/block_draft.dart';
import '../../../../../domain/models/planner/calendar_block.dart';
import '../../../../../domain/models/planner/deadline.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/planner_focus.dart';
import '../../widgets/planner_form_fields.dart';
import '../../widgets/planner_visuals.dart';
import '../bloc/block_editor_bloc.dart';

/// Hoja de creación/edición de un bloque. Al crear incluye la pestaña para
/// distribuir una rutina completa. Devuelve un [BlockEditorOutcome] al cerrarse.
class BlockEditorSheet extends StatelessWidget {
  const BlockEditorSheet({super.key, this.block, this.start});

  final CalendarBlock? block;
  final DateTime? start;

  static Future<BlockEditorOutcome?> show(
    BuildContext context, {
    CalendarBlock? block,
    DateTime? start,
  }) => showModalBottomSheet<BlockEditorOutcome>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlockEditorSheet(block: block, start: start),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<BlockEditorBloc>(param1: block)
            ..add(const BlockEditorEvent.started()),
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: _EditorView(block: block, start: start ?? DateTime.now()),
      ),
    );
  }
}

class _EditorView extends StatefulWidget {
  const _EditorView({required this.block, required this.start});

  final CalendarBlock? block;
  final DateTime start;

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView>
    with SingleTickerProviderStateMixin, ErrorsMessageMixin {
  late final TabController _tabs = TabController(
    length: widget.block == null ? 2 : 1,
    vsync: this,
  );

  // Bloque.
  late BlockType _type;
  late DateTime _day;
  late int _startMin;
  late int _endMin;
  String? _subjectId;
  PlannerPriority? _priority;
  bool _private = false;

  /// «Repetir cada semana» (solo al crear): semanas en total, esta incluida.
  bool _repeat = false;
  int _repeatTotalWeeks = 4;

  /// Esta semana y 15 más: el límite del servidor (`MAX_WEEKLY_REPEATS`).
  static const _maxRepeatTotalWeeks = 16;
  ClassKind? _classKind;
  String? _routineId;
  String? _challengeId;
  String? _deadlineId;
  PlannerPriority _deadlineDifficulty = PlannerPriority.medium;
  final _topics = TextEditingController();
  final _location = TextEditingController();
  final _deadlineTitle = TextEditingController();

  // Distribución de rutina.
  String? _distRoutineId;
  Set<int> _weekdays = {1, 3, 5};
  late DateTime _distStart;
  int _distTime = 18 * 60;
  int _distDuration = 60;

  bool get _editing => widget.block != null;

  @override
  void initState() {
    super.initState();
    final b = widget.block;
    final start = b?.start ?? widget.start;
    final end = b?.end ?? widget.start.add(const Duration(hours: 1));
    _type =
        b?.type ??
        (context.usageFocus.includesAcademic
            ? BlockType.study
            : BlockType.sport);
    _day = DateTime(start.year, start.month, start.day);
    _startMin = start.hour * 60 + start.minute;
    _endMin = end.day != start.day ? 24 * 60 - 1 : end.hour * 60 + end.minute;
    _subjectId = b?.subjectId;
    _priority = b?.priority;
    _private = b?.privateBlock ?? false;
    _classKind = b?.classKind;
    _routineId = b?.routineId;
    _challengeId = b?.challengeId;
    _deadlineId = b?.deadlineId;
    _topics.text = b?.topics ?? '';
    _location.text = b?.location ?? '';
    _distStart = _day;
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _topics.dispose();
    _location.dispose();
    _deadlineTitle.dispose();
    super.dispose();
  }

  DateTime _at(int minutes) =>
      DateTime(_day.year, _day.month, _day.day, minutes ~/ 60, minutes % 60);

  void _save() {
    context.read<BlockEditorBloc>().add(
      BlockEditorEvent.saveRequested(
        BlockDraft(
          type: _type,
          start: _at(_startMin),
          end: _at(_endMin),
          subjectId: _subjectId,
          topics: _topics.text,
          location: _location.text,
          priority: _priority,
          privateBlock: _private,
          classKind: _type == BlockType.classSession ? _classKind : null,
          routineId: _type == BlockType.sport ? _routineId : null,
          challengeId: _challengeId,
          deadlineId: _deadlineId,
          deadlineTitle: _type.createsDeadline && _deadlineId == null
              ? _deadlineTitle.text
              : null,
          deadlineDifficulty: _type.createsDeadline && _deadlineId == null
              ? _deadlineDifficulty
              : null,
          repeatWeeks: !_editing && _repeat && _type.canRepeatWeekly
              ? _repeatTotalWeeks - 1
              : 0,
        ),
      ),
    );
  }

  void _distribute() {
    final routineId = _distRoutineId;
    if (routineId == null) return;
    context.read<BlockEditorBloc>().add(
      BlockEditorEvent.distributionRequested(
        RoutineDistribution(
          routineId: routineId,
          weekdays: _weekdays,
          startDate: _distStart,
          preferredStartMinutes: _distTime,
          durationMinutes: _distDuration,
        ),
      ),
    );
  }

  String? _feedback(BuildContext context, BlockEditorState state) {
    final l10n = context.localizations;
    final issue = state.issue;
    if (issue != null) {
      return switch (issue) {
        BlockEditorIssue.inPast => l10n.plannerInPast,
        BlockEditorIssue.tooShort => l10n.plannerIssueTooShort,
        BlockEditorIssue.noWeekdays => l10n.plannerIssueNoWeekdays,
      };
    }
    final error = state.error;
    return error == null ? null : errorMessage(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<BlockEditorBloc, BlockEditorState>(
      listenWhen: (a, b) => a.outcome != b.outcome && b.outcome != null,
      listener: (context, state) => Navigator.of(context).pop(state.outcome),
      builder: (context, state) {
        final feedback = _feedback(context, state);
        final onRoutineTab = !_editing && _tabs.index == 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.m),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _editing
                          ? l10n.plannerEditBlockTitle
                          : l10n.plannerNewBlockTitle,
                      style: context.textStyles.titleLarge,
                    ),
                  ),
                  if (_editing)
                    IconButton(
                      tooltip: l10n.plannerDeleteBlock,
                      onPressed: state.submitting
                          ? null
                          : () => Navigator.of(context).pop(
                              BlockEditorOutcome.deleteRequested(widget.block!),
                            ),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: context.colors.error,
                      ),
                    ),
                  IconButton(
                    tooltip: l10n.commonClose,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            if (!_editing)
              TabBar(
                controller: _tabs,
                tabs: [
                  Tab(text: l10n.plannerTabBlock),
                  Tab(text: l10n.plannerTabRoutine),
                ],
              ),
            Expanded(
              child: state.status == BlockEditorStatus.loading
                  ? const _FormSkeleton()
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _blockForm(context, state),
                        if (!_editing) _routineForm(context, state),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TokensSpacing.m,
                TokensSpacing.s,
                TokensSpacing.m,
                TokensSpacing.m,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (feedback != null) ...[
                    InlineMessage(message: feedback),
                    const SizedBox(height: TokensSpacing.s),
                  ],
                  // Estudio o repaso sin terminar: empezar a concentrarse ya,
                  // con el Pomodoro vinculado al bloque y su asignatura.
                  if (_editing &&
                      !widget.block!.completed &&
                      widget.block!.type.isStudy) ...[
                    AppSecondaryButton(
                      label: l10n.plannerFocusOnBlock,
                      icon: const Icon(Icons.timer_outlined),
                      onPressed: state.submitting
                          ? null
                          : () => Navigator.of(context).pop(
                              BlockEditorOutcome.focusRequested(widget.block!),
                            ),
                    ),
                    const SizedBox(height: TokensSpacing.s),
                  ],
                  if (_editing) ...[
                    AppSecondaryButton(
                      label: widget.block!.completed
                          ? l10n.plannerMarkPending
                          : l10n.plannerMarkCompleted,
                      icon: Icon(
                        widget.block!.completed
                            ? Icons.undo_rounded
                            : Icons.check_circle_outline_rounded,
                      ),
                      onPressed: state.submitting
                          ? null
                          : () => Navigator.of(context).pop(
                              BlockEditorOutcome.completionRequested(
                                widget.block!.id,
                              ),
                            ),
                    ),
                    const SizedBox(height: TokensSpacing.s),
                  ],
                  AppPrimaryButton(
                    label: onRoutineTab
                        ? l10n.plannerDistributeAction
                        : (_editing
                              ? l10n.plannerSaveChanges
                              : l10n.plannerCreateBlock),
                    loading: state.submitting,
                    onPressed: state.status != BlockEditorStatus.ready
                        ? null
                        : onRoutineTab
                        ? (_distRoutineId == null ? null : _distribute)
                        : _save,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _blockForm(BuildContext context, BlockEditorState state) {
    final l10n = context.localizations;
    final locked = widget.block?.isLocked ?? false;
    final deadlines = state.deadlines
        .where((d) => _subjectId == null || d.subjectId == _subjectId)
        .toList();
    // La entrega ya vinculada se conserva aunque no esté en la lista de pendientes.
    final linkedMissing =
        _deadlineId != null && !deadlines.any((d) => d.id == _deadlineId);
    const gap = SizedBox(height: TokensSpacing.m);
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        if (state.optionsError != null) ...[
          InlineMessage(message: l10n.plannerOptionsError, isError: false),
          gap,
        ],
        Text(l10n.plannerFieldType, style: context.textStyles.titleSmall),
        const SizedBox(height: TokensSpacing.s),
        Wrap(
          spacing: TokensSpacing.xs,
          runSpacing: TokensSpacing.xs,
          children: [
            for (final t in BlockType.values.where(
              (t) => t == _type || context.usageFocus.allowsBlock(t),
            ))
              ChoiceChip(
                avatar: Icon(t.icon, size: 18, color: t.color(context)),
                label: Text(t.label(context)),
                selected: _type == t,
                onSelected: (_) => setState(() => _type = t),
              ),
          ],
        ),
        gap,
        Text(l10n.plannerSchedule, style: context.textStyles.titleSmall),
        const SizedBox(height: TokensSpacing.s),
        if (locked) ...[
          InlineMessage(message: l10n.plannerBlockLockedHint, isError: false),
          const SizedBox(height: TokensSpacing.s),
        ],
        PickerField(
          label: l10n.plannerFieldDate,
          value: PlannerFormats.longDate(_day),
          icon: Icons.calendar_today_rounded,
          onTap: locked
              ? null
              : () async {
                  final picked = await pickPlannerDate(context, initial: _day);
                  if (picked != null) setState(() => _day = picked);
                },
        ),
        const SizedBox(height: TokensSpacing.s),
        Row(
          children: [
            Expanded(
              child: PickerField(
                label: l10n.plannerFieldStart,
                value: PlannerFormats.minutes(_startMin),
                icon: Icons.schedule_rounded,
                onTap: locked
                    ? null
                    : () async {
                        final m = await pickPlannerTime(context, _startMin);
                        if (m == null) return;
                        setState(() {
                          final duration = _endMin - _startMin;
                          _startMin = m;
                          _endMin = (m + (duration > 0 ? duration : 60)).clamp(
                            m,
                            24 * 60 - 1,
                          );
                        });
                      },
              ),
            ),
            const SizedBox(width: TokensSpacing.s),
            Expanded(
              child: PickerField(
                label: l10n.plannerFieldEnd,
                value: PlannerFormats.minutes(_endMin),
                icon: Icons.schedule_rounded,
                onTap: locked
                    ? null
                    : () async {
                        final m = await pickPlannerTime(context, _endMin);
                        if (m != null) setState(() => _endMin = m);
                      },
              ),
            ),
          ],
        ),
        gap,
        Text(l10n.plannerDetails, style: context.textStyles.titleSmall),
        const SizedBox(height: TokensSpacing.s),
        DropdownButtonFormField<String?>(
          initialValue: _subjectId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.plannerFieldSubject,
            prefixIcon: const Icon(Icons.class_rounded),
          ),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.plannerNoSubject)),
            for (final s in state.subjects)
              DropdownMenuItem(value: s.id, child: Text(s.name)),
            if (_subjectId != null &&
                !state.subjects.any((s) => s.id == _subjectId))
              DropdownMenuItem(
                value: _subjectId,
                child: Text(l10n.plannerFieldSubject),
              ),
          ],
          onChanged: (v) => setState(() {
            _subjectId = v;
            if (_deadlineId != null &&
                v != null &&
                !state.deadlines.any(
                  (d) => d.id == _deadlineId && d.subjectId == v,
                )) {
              _deadlineId = null;
            }
          }),
        ),
        const SizedBox(height: TokensSpacing.s),
        AppTextField(
          label: l10n.plannerFieldTopics,
          hint: l10n.plannerFieldTopicsHint,
          controller: _topics,
          icon: Icons.notes_rounded,
          maxLines: 3,
        ),
        const SizedBox(height: TokensSpacing.s),
        AppTextField(
          label: l10n.plannerFieldLocation,
          controller: _location,
          icon: Icons.place_outlined,
        ),
        const SizedBox(height: TokensSpacing.m),
        Text(l10n.plannerFieldPriority, style: context.textStyles.labelLarge),
        const SizedBox(height: TokensSpacing.xs),
        SegmentedButton<PlannerPriority?>(
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          segments: [
            for (final p in PlannerPriority.values)
              ButtonSegment(value: p, label: Text(p.label(context))),
          ],
          selected: {_priority},
          onSelectionChanged: (s) =>
              setState(() => _priority = s.isEmpty ? null : s.first),
        ),
        if (_type == BlockType.classSession) ...[
          const SizedBox(height: TokensSpacing.m),
          Text(
            l10n.plannerFieldClassKind,
            style: context.textStyles.labelLarge,
          ),
          const SizedBox(height: TokensSpacing.xs),
          SegmentedButton<ClassKind?>(
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            segments: [
              for (final k in ClassKind.values)
                ButtonSegment(value: k, label: Text(k.label(context))),
            ],
            selected: {_classKind},
            onSelectionChanged: (s) =>
                setState(() => _classKind = s.isEmpty ? null : s.first),
          ),
        ],
        // Exámenes y entregas no se repiten: cada uno tiene su fecha.
        if (!_editing && _type.canRepeatWeekly) ...[
          const SizedBox(height: TokensSpacing.s),
          AppFocusOutline(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _repeat,
              onChanged: (v) => setState(() => _repeat = v),
              title: Text(l10n.plannerRepeatWeekly),
              subtitle: Text(l10n.plannerRepeatWeeklyHint),
              secondary: const Icon(Icons.event_repeat_rounded),
            ),
          ),
          if (_repeat)
            Padding(
              // Alineado con el texto del interruptor (después de su icono).
              padding: const EdgeInsetsDirectional.only(
                start: TokensSize.iconM + TokensSpacing.m,
              ),
              child: AppStepperField(
                label: l10n.plannerRepeatWeeksLabel,
                value: _repeatTotalWeeks,
                min: 2,
                max: _maxRepeatTotalWeeks,
                display: l10n.plannerRepeatWeeks,
                onChanged: (v) => setState(() => _repeatTotalWeeks = v),
              ),
            ),
        ],
        const SizedBox(height: TokensSpacing.s),
        AppFocusOutline(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _private,
            onChanged: (v) => setState(() => _private = v),
            title: Text(l10n.plannerFieldPrivate),
            subtitle: Text(l10n.plannerFieldPrivateHint),
            secondary: const Icon(Icons.lock_outline_rounded),
          ),
        ),
        gap,
        Text(l10n.plannerLinks, style: context.textStyles.titleSmall),
        const SizedBox(height: TokensSpacing.s),
        if (_type == BlockType.sport) ...[
          DropdownButtonFormField<String?>(
            initialValue: _routineId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.plannerFieldRoutine,
              prefixIcon: const Icon(Icons.fitness_center_rounded),
            ),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.plannerNoRoutine)),
              for (final r in state.routines)
                DropdownMenuItem(value: r.id, child: Text(r.name)),
            ],
            onChanged: (v) => setState(() => _routineId = v),
          ),
          const SizedBox(height: TokensSpacing.s),
        ],
        DropdownButtonFormField<String?>(
          initialValue: _challengeId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.plannerFieldChallenge,
            prefixIcon: const Icon(Icons.emoji_events_outlined),
          ),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.plannerNoChallenge)),
            for (final c in state.challenges)
              DropdownMenuItem(value: c.id, child: Text(c.title)),
            if (_challengeId != null &&
                !state.challenges.any((c) => c.id == _challengeId))
              DropdownMenuItem(
                value: _challengeId,
                child: Text(l10n.plannerFieldChallenge),
              ),
          ],
          onChanged: (v) => setState(() => _challengeId = v),
        ),
        const SizedBox(height: TokensSpacing.s),
        DropdownButtonFormField<String?>(
          key: ValueKey('deadline-$_subjectId-$_type'),
          initialValue: _deadlineId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.plannerFieldDeadline,
            prefixIcon: const Icon(Icons.event_note_rounded),
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                _type.createsDeadline && !_editing
                    ? l10n.plannerNoDeadline
                    : l10n.plannerNoDeadlineLink,
              ),
            ),
            for (final d in deadlines)
              DropdownMenuItem(value: d.id, child: Text(_deadlineLabel(d))),
            if (linkedMissing)
              DropdownMenuItem(
                value: _deadlineId,
                child: Text(l10n.plannerFieldDeadline),
              ),
          ],
          onChanged: (v) => setState(() => _deadlineId = v),
        ),
        if (_type.createsDeadline && _deadlineId == null && !_editing) ...[
          const SizedBox(height: TokensSpacing.s),
          AppTextField(
            label: l10n.plannerFieldDeadlineTitle,
            hint: l10n.plannerFieldDeadlineTitleHint,
            controller: _deadlineTitle,
            icon: Icons.title_rounded,
          ),
          const SizedBox(height: TokensSpacing.s),
          Text(
            l10n.plannerFieldDifficulty,
            style: context.textStyles.labelLarge,
          ),
          const SizedBox(height: TokensSpacing.xs),
          SegmentedButton<PlannerPriority>(
            showSelectedIcon: false,
            segments: [
              for (final p in PlannerPriority.values)
                ButtonSegment(value: p, label: Text(p.label(context))),
            ],
            selected: {_deadlineDifficulty},
            onSelectionChanged: (s) =>
                setState(() => _deadlineDifficulty = s.first),
          ),
        ],
      ],
    );
  }

  String _deadlineLabel(Deadline d) =>
      '${d.title} · ${PlannerFormats.dayMonth(d.dueAt)}';

  Widget _routineForm(BuildContext context, BlockEditorState state) {
    final l10n = context.localizations;
    if (state.routines.isEmpty) {
      return AppEmptyState(
        icon: Icons.fitness_center_rounded,
        title: l10n.plannerNoRoutinesTitle,
        message: l10n.plannerNoRoutinesMessage,
      );
    }
    final durations = [for (var m = 30; m <= 240; m += 15) m];
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        Text(
          l10n.plannerDistributeIntro,
          style: context.textStyles.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: TokensSpacing.m),
        DropdownButtonFormField<String>(
          initialValue: _distRoutineId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.plannerFieldRoutine,
            prefixIcon: const Icon(Icons.fitness_center_rounded),
          ),
          items: [
            for (final r in state.routines)
              DropdownMenuItem(value: r.id, child: Text(r.name)),
          ],
          onChanged: (v) => setState(() => _distRoutineId = v),
        ),
        const SizedBox(height: TokensSpacing.m),
        Text(l10n.plannerFieldWeekdays, style: context.textStyles.labelLarge),
        const SizedBox(height: TokensSpacing.xs),
        WeekdayPicker(
          selected: _weekdays,
          onChanged: (s) => setState(() => _weekdays = s),
        ),
        const SizedBox(height: TokensSpacing.m),
        PickerField(
          label: l10n.plannerFieldStartDate,
          value: PlannerFormats.longDate(_distStart),
          icon: Icons.calendar_today_rounded,
          onTap: () async {
            final today = DateTime.now();
            final picked = await pickPlannerDate(
              context,
              initial: _distStart,
              first: DateTime(today.year, today.month, today.day),
            );
            if (picked != null) setState(() => _distStart = picked);
          },
        ),
        const SizedBox(height: TokensSpacing.s),
        Row(
          children: [
            Expanded(
              child: PickerField(
                label: l10n.plannerFieldPreferredTime,
                value: PlannerFormats.minutes(_distTime),
                icon: Icons.schedule_rounded,
                onTap: () async {
                  final m = await pickPlannerTime(context, _distTime);
                  if (m != null) setState(() => _distTime = m);
                },
              ),
            ),
            const SizedBox(width: TokensSpacing.s),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _distDuration,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.plannerFieldDuration,
                ),
                items: [
                  for (final m in durations)
                    DropdownMenuItem(
                      value: m,
                      child: Text(l10n.plannerDurationMinutes(m)),
                    ),
                ],
                onChanged: (v) => setState(() => _distDuration = v ?? 60),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FormSkeleton extends StatelessWidget {
  const _FormSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppSkeletonGroup(
      child: ListView(
        padding: const EdgeInsets.all(TokensSpacing.m),
        children: const [
          AppSkeleton(height: 96),
          SizedBox(height: TokensSpacing.m),
          AppSkeleton(height: 56),
          SizedBox(height: TokensSpacing.s),
          AppSkeleton(height: 56),
          SizedBox(height: TokensSpacing.m),
          AppSkeleton(height: 56),
        ],
      ),
    );
  }
}
