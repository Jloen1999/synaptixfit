import '../../../../../domain/enums/item_time_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/planner_enums.dart';
import '../../../../../domain/models/planner/block_draft.dart';
import '../../../../../domain/models/planner/calendar_block.dart';
import '../../../../../domain/models/planner/deadline.dart';
import '../../../../../domain/models/planner/planner_options.dart';
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
  String? _milestoneId;
  String? _deadlineId;
  PlannerPriority _deadlineDifficulty = PlannerPriority.medium;
  final _topics = TextEditingController();
  final _location = TextEditingController();
  final _deadlineTitle = TextEditingController();

  // Distribución de rutina.
  String? _distRoutineId;
  Set<int> _weekdays = {1, 3, 5};

  /// Cada día de la rutina en su día de la semana (el número del día): así el
  /// calendario coincide con lo que propone la rutina.
  bool _routineWeekdays = true;
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
    _milestoneId = b?.milestoneId;
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

  /// Inicio real: una entrega ocupa la media hora anterior a su hora límite.
  int get _effectiveStartMin => _type.startMinuteFor(_startMin, _endMin);

  /// Al cambiar de tipo se proponen sus horas: duración típica si la actual
  /// no es una de las suyas; una entrega conserva su hora de fin como límite.
  void _changeType(BlockType t) {
    setState(() {
      _type = t;
      if (t.timeInput == BlockTimeInput.duration &&
          !t.durationOptions.contains(_endMin - _startMin)) {
        _endMin = (_startMin + t.defaultDuration).clamp(_startMin, 24 * 60 - 1);
      }
    });
  }

  void _save() {
    final t = _type;
    context.read<BlockEditorBloc>().add(
      BlockEditorEvent.saveRequested(
        BlockDraft(
          type: t,
          start: _at(_effectiveStartMin),
          end: _at(_endMin),
          // Lo que no se muestra para este tipo no se guarda.
          subjectId: t.usesSubject ? _subjectId : null,
          topics: t.usesTopics ? _topics.text : '',
          location: t.usesLocation ? _location.text : '',
          priority: t.usesPriority ? _priority : null,
          privateBlock: _private,
          classKind: t == BlockType.classSession ? _classKind : null,
          routineId: t == BlockType.sport ? _routineId : null,
          // Si sigue siendo la misma rutina, el bloque conserva su día enlazado
          // (si no, editarlo lo convertiría en deporte libre).
          routineWeekId: _keepsRoutineDay(t)
              ? widget.block?.routineWeekId
              : null,
          routineDayId: _keepsRoutineDay(t) ? widget.block?.routineDayId : null,
          challengeId: t.usesChallenge ? _challengeId : null,
          milestoneId: t.usesChallenge && _challengeId != null
              ? _milestoneId
              : null,
          deadlineId: t.usesDeadlineLink ? _deadlineId : null,
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

  /// «Tarea del reto»: las pendientes del reto elegido que avanzan con
  /// bloques (las vinculadas a una entrega las completa esa entrega). Cada
  /// bloque completado hace avanzar la tarea; el servidor comprueba que sea de
  /// ese reto y que el bloque caiga en su periodo.
  List<Widget> _taskField(BlockEditorState state) {
    final l10n = context.localizations;
    ChallengeOption? challenge;
    for (final c in state.challenges) {
      if (c.id == _challengeId) challenge = c;
    }
    final tasks = [
      for (final t in challenge?.tasks ?? const <ChallengeTaskOption>[])
        if (t.id == _milestoneId || (!t.completed && !t.hasDeadline)) t,
    ];
    if (tasks.isEmpty) return const [];
    return [
      DropdownButtonFormField<String?>(
        key: ValueKey('task-$_challengeId'),
        initialValue: tasks.any((t) => t.id == _milestoneId)
            ? _milestoneId
            : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: l10n.plannerFieldChallengeTask,
          helperText: l10n.plannerFieldChallengeTaskHint,
          helperMaxLines: 3,
          prefixIcon: const Icon(Icons.checklist_rounded),
        ),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text(l10n.plannerNoChallengeTask),
          ),
          for (final t in tasks)
            DropdownMenuItem(
              value: t.id,
              child: Text(t.title, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (v) => setState(() => _milestoneId = v),
      ),
      const SizedBox(height: TokensSpacing.s),
    ];
  }

  bool _keepsRoutineDay(BlockType t) =>
      t == BlockType.sport &&
      _routineId != null &&
      _routineId == widget.block?.routineId;

  void _distribute() {
    final routineId = _distRoutineId;
    if (routineId == null) return;
    context.read<BlockEditorBloc>().add(
      BlockEditorEvent.distributionRequested(
        RoutineDistribution(
          routineId: routineId,
          weekdays: _routineWeekdays ? const {} : _weekdays,
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
                    AppInlineMessage(message: feedback),
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
                        ? (_distRoutineId == null ||
                                  (!_routineWeekdays && _weekdays.isEmpty)
                              ? null
                              : _distribute)
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

  /// Marcar hecho, reprogramar (si se quedó sin hacer) o concentrarse en él
  /// (estudio o repaso que aún no pasó). Cada acción cierra la hoja y la
  /// resuelve el calendario.
  List<Widget> _blockActions(BuildContext context, BlockEditorState state) {
    final l10n = context.localizations;
    final block = widget.block!;
    final missed = block.timeStatus == ItemTimeStatus.missed;
    void close(BlockEditorOutcome outcome) =>
        Navigator.of(context).pop(outcome);
    // El bloque de un día de rutina sigue a su sesión: no se marca a mano, se
    // entrena (o se registra como sesión pasada) desde la rutina.
    final routineDay = block.routineDayId != null && block.routineId != null;
    final actions = <Widget>[
      if (routineDay)
        AppSecondaryButton(
          label: l10n.plannerOpenRoutine,
          icon: const Icon(Icons.fitness_center_rounded),
          onPressed: state.submitting
              ? null
              : () => close(
                  BlockEditorOutcome.trainingRequested(block.routineId!),
                ),
        )
      else if (block.timeStatus == ItemTimeStatus.upcoming && !block.completed)
        // Un bloque que aún no ha empezado no se marca como hecho.
        block.type == BlockType.classSession
            ? _note(context, l10n.plannerClassAttendsLater)
            : AppInlineMessage(
                message: l10n.plannerCompleteWhenStarted,
                tone: AppMessageTone.warning,
              )
      else if (block.type == BlockType.classSession) ...[
        // Las clases se dan por asistidas solas al terminar (ADR 0029): lo
        // que se apunta es «No fui» (o corregirlo con «Sí fui»).
        _note(
          context,
          block.absent
              ? l10n.plannerClassMarkedAbsent
              : block.completed
              ? l10n.plannerClassAttended
              : l10n.plannerClassAttendsByItself,
        ),
        if (!block.completed)
          AppSecondaryButton(
            label: l10n.plannerClassWent,
            icon: const Icon(Icons.check_circle_outline_rounded),
            onPressed: state.submitting
                ? null
                : () => close(BlockEditorOutcome.completionRequested(block.id)),
          ),
        if (!block.absent)
          AppSecondaryButton(
            label: l10n.plannerClassDidNotGo,
            icon: const Icon(Icons.event_busy_rounded),
            onPressed: state.submitting
                ? null
                : () => close(BlockEditorOutcome.absenceRequested(block.id)),
          ),
      ] else
        AppSecondaryButton(
          label: block.completed
              ? l10n.plannerMarkPending
              : l10n.plannerMarkCompleted,
          icon: Icon(
            block.completed
                ? Icons.undo_rounded
                : Icons.check_circle_outline_rounded,
          ),
          onPressed: state.submitting
              ? null
              : () => close(BlockEditorOutcome.completionRequested(block.id)),
        ),
      if (missed && !block.isLocked && block.type != BlockType.classSession)
        AppSecondaryButton(
          label: l10n.plannerRescheduleNext,
          icon: const Icon(Icons.update_rounded),
          onPressed: state.submitting
              ? null
              : () => close(BlockEditorOutcome.rescheduleRequested(block.id)),
        ),
      // Concentrarse: estudio o repaso que no está hecho ni se quedó sin hacer.
      if (!block.completed && !missed && block.type.isStudy)
        AppSecondaryButton(
          label: l10n.plannerFocusOnBlock,
          icon: const Icon(Icons.timer_outlined),
          onPressed: state.submitting
              ? null
              : () => close(BlockEditorOutcome.focusRequested(block)),
        ),
    ];
    return [
      for (final (i, action) in actions.indexed) ...[
        if (i > 0) const SizedBox(height: TokensSpacing.s),
        action,
      ],
    ];
  }

  /// Nota de cómo cuenta una clase (no es un aviso: no hay nada mal).
  Widget _note(BuildContext context, String text) => Text(
    text,
    style: context.textStyles.bodyMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    ),
  );

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
        // Acciones del bloque arriba del formulario: el pie fijo solo lleva
        // el botón principal (con texto grande no se come la pantalla).
        if (_editing) ...[..._blockActions(context, state), gap],
        if (state.optionsError != null) ...[
          AppInlineMessage(
            message: l10n.plannerOptionsError,
            tone: AppMessageTone.warning,
          ),
          gap,
        ],
        // El grupo de abajo ya lo dice al lector: no se lee dos veces.
        ExcludeSemantics(
          child: Text(
            l10n.plannerFieldType,
            style: context.textStyles.titleSmall,
          ),
        ),
        const SizedBox(height: TokensSpacing.s),
        // Grupo con nombre: el lector dice «Tipo» al entrar en las opciones.
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: l10n.plannerFieldType,
          child: Wrap(
            spacing: TokensSpacing.xs,
            runSpacing: TokensSpacing.xs,
            children: [
              for (final t in BlockType.values.where(
                (t) => t == _type || context.usageFocus.allowsBlock(t),
              ))
                ChoiceChip(
                  avatar: Icon(
                    t.icon,
                    size: TokensSize.iconXs,
                    color: t.color(context),
                  ),
                  label: Text(t.label(context)),
                  selected: _type == t,
                  onSelected: (_) => _changeType(t),
                ),
            ],
          ),
        ),
        gap,
        Text(l10n.plannerSchedule, style: context.textStyles.titleSmall),
        const SizedBox(height: TokensSpacing.s),
        if (locked) ...[
          AppInlineMessage(
            message: l10n.plannerBlockLockedHint,
            tone: AppMessageTone.warning,
          ),
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
        ..._timeFields(context, locked),
        gap,
        Text(l10n.plannerDetails, style: context.textStyles.titleSmall),
        const SizedBox(height: TokensSpacing.s),
        if (_type.usesSubject) ...[
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
        ],
        if (_type.usesTopics) ...[
          AppTextField(
            label: l10n.plannerFieldTopics,
            hint: l10n.plannerFieldTopicsHint,
            controller: _topics,
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: TokensSpacing.s),
        ],
        if (_type.usesLocation)
          AppTextField(
            label: l10n.plannerFieldLocation,
            controller: _location,
            icon: Icons.place_outlined,
          ),
        if (_type.usesPriority) ...[
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
        ],
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
        if (_type == BlockType.sport ||
            _type.usesChallenge ||
            _type.usesDeadlineLink) ...[
          gap,
          Text(l10n.plannerLinks, style: context.textStyles.titleSmall),
          const SizedBox(height: TokensSpacing.s),
        ],
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
        if (_type.usesChallenge) ...[
          DropdownButtonFormField<String?>(
            initialValue: _challengeId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.plannerFieldChallenge,
              prefixIcon: const Icon(Icons.emoji_events_outlined),
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(l10n.plannerNoChallenge),
              ),
              for (final c in state.challenges)
                DropdownMenuItem(value: c.id, child: Text(c.title)),
              if (_challengeId != null &&
                  !state.challenges.any((c) => c.id == _challengeId))
                DropdownMenuItem(
                  value: _challengeId,
                  child: Text(l10n.plannerFieldChallenge),
                ),
            ],
            onChanged: (v) => setState(() {
              _challengeId = v;
              _milestoneId = null;
            }),
          ),
          const SizedBox(height: TokensSpacing.s),
          ..._taskField(state),
        ],
        if (_type.usesDeadlineLink)
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

  /// Hora del bloque según su tipo (ver [BlockType.timeInput]).
  List<Widget> _timeFields(BuildContext context, bool locked) {
    final l10n = context.localizations;
    Future<void> pickStart() async {
      final m = await pickPlannerTime(context, _startMin);
      if (m == null) return;
      setState(() {
        final duration = _endMin - _startMin;
        _startMin = m;
        _endMin = (m + (duration > 0 ? duration : _type.defaultDuration)).clamp(
          m,
          24 * 60 - 1,
        );
      });
    }

    final startField = PickerField(
      label: l10n.plannerFieldStart,
      value: PlannerFormats.minutes(_startMin),
      icon: Icons.schedule_rounded,
      onTap: locked ? null : pickStart,
    );
    switch (_type.timeInput) {
      case BlockTimeInput.moment:
        return [
          PickerField(
            label: l10n.plannerFieldDueTime,
            value: PlannerFormats.minutes(_endMin),
            icon: Icons.alarm_rounded,
            helper: l10n.plannerDueTimeHint(BlockType.momentDurationMinutes),
            onTap: locked
                ? null
                : () async {
                    final m = await pickPlannerTime(context, _endMin);
                    if (m != null) setState(() => _endMin = m);
                  },
          ),
        ];
      case BlockTimeInput.duration:
        final current = _endMin - _startMin;
        final options = {
          ..._type.durationOptions,
          if (current > 0) current,
        }.toList()..sort();
        return [
          startField,
          const SizedBox(height: TokensSpacing.m),
          ExcludeSemantics(
            child: Text(
              l10n.plannerFieldBlockDuration,
              style: context.textStyles.labelLarge,
            ),
          ),
          const SizedBox(height: TokensSpacing.xs),
          Semantics(
            container: true,
            explicitChildNodes: true,
            label: l10n.plannerFieldBlockDuration,
            child: Wrap(
              spacing: TokensSpacing.xs,
              runSpacing: TokensSpacing.xs,
              children: [
                for (final m in options)
                  ChoiceChip(
                    label: Text(PlannerFormats.duration(l10n, m)),
                    selected: current == m,
                    onSelected: locked
                        ? null
                        : (_) => setState(
                            () => _endMin = (_startMin + m).clamp(
                              _startMin,
                              24 * 60 - 1,
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ];
      case BlockTimeInput.range:
        return [
          Row(
            children: [
              Expanded(child: startField),
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
        ];
    }
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
        AppFocusOutline(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.event_repeat_rounded),
            title: Text(l10n.plannerDistributeRoutineWeekdays),
            subtitle: Text(l10n.plannerDistributeRoutineWeekdaysHint),
            value: _routineWeekdays,
            onChanged: (v) => setState(() => _routineWeekdays = v),
          ),
        ),
        if (!_routineWeekdays) ...[
          Text(l10n.plannerFieldWeekdays, style: context.textStyles.labelLarge),
          const SizedBox(height: TokensSpacing.xs),
          WeekdayPicker(
            selected: _weekdays,
            onChanged: (s) => setState(() => _weekdays = s),
          ),
        ],
        const SizedBox(height: TokensSpacing.s),
        // Volver a repartir sustituye lo que ya hubiera de esa rutina.
        AppInlineMessage(
          message: l10n.plannerDistributeReplaces,
          tone: AppMessageTone.warning,
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
