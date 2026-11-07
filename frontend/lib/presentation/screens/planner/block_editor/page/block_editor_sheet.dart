import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/item_time_status.dart';
import '../../../../../domain/enums/planner_enums.dart';
import '../../../../../domain/models/planner/block_draft.dart';
import '../../../../../domain/models/planner/calendar_block.dart';
import '../../../../../domain/models/planner/deadline.dart';
import '../../../../../domain/models/planner/planner_options.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../planner_routes.dart';
import '../../widgets/block_type_picker.dart';
import '../../widgets/planner_focus.dart';
import '../../widgets/planner_form_fields.dart';
import '../../widgets/planner_visuals.dart';
import '../bloc/block_editor_bloc.dart';

/// Hoja de crear/editar un evento del calendario en tres pasos («¿Qué es?»,
/// «¿Cuándo?», «Repetir y aviso») y «Más opciones» con lo que aplica a su
/// tipo. Al crear incluye la pestaña para repartir una rutina. Devuelve un
/// [BlockEditorOutcome] al cerrarse; lo resuelve el calendario.
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
  /// Pasos numerados de la hoja (el tercero siempre está: el aviso).
  /// Descanso, comida y sueño no llevan aviso (`ReminderPlanner`).
  bool get _hasReminder => switch (_type) {
    BlockType.rest || BlockType.meal || BlockType.sleep => false,
    _ => true,
  };

  /// Atajos de duración para los tipos con inicio y fin libres.
  static const _quickDurations = [30, 60, 120];

  /// Esta semana y 15 más: el límite del servidor (`MAX_WEEKLY_REPEATS`).
  static const _maxRepeatTotalWeeks = 16;

  /// La pestaña «Distribuir rutina» solo al crear y si se ve el deporte.
  late final bool _withRoutineTab;
  late final TabController _tabs;

  // Evento.
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
  ClassKind? _classKind;
  String? _routineId;
  String? _challengeId;
  String? _milestoneId;
  String? _deadlineId;
  PlannerPriority _deadlineDifficulty = PlannerPriority.medium;
  final _topics = TextEditingController();
  final _location = TextEditingController();
  final _deadlineTitle = TextEditingController();

  /// Nombre de un evento personal («Dentista»). Va al servidor en los temas,
  /// pero se edita aparte para no mezclarlo con los temas de un estudio.
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  final _nameKey = GlobalKey();

  /// Aviso de nombre vacío que la persona ya está corrigiendo (escribió
  /// después): no se repite hasta el siguiente intento de guardar.
  int? _nameErrorHandled;

  /// «Más opciones» desplegado: de entrada solo si al editar ya hay algo.
  late bool _moreOptions;

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
    final focus = context.usageFocus;
    _withRoutineTab = b == null && focus.allowsBlock(BlockType.sport);
    _tabs = TabController(length: _withRoutineTab ? 2 : 1, vsync: this)
      ..addListener(() => setState(() {}));
    final start = b?.start ?? widget.start;
    final end = b?.end ?? widget.start.add(const Duration(hours: 1));
    _type =
        b?.type ?? (focus.includesAcademic ? BlockType.study : BlockType.sport);
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
    if (b != null && b.type.requiresName) {
      _name.text = b.topics ?? '';
    } else {
      _topics.text = b?.topics ?? '';
    }
    _location.text = b?.location ?? '';
    _moreOptions =
        b != null &&
        (b.subjectId != null ||
            _topics.text.isNotEmpty ||
            _location.text.isNotEmpty ||
            b.priority != null ||
            b.classKind != null ||
            b.privateBlock ||
            b.routineId != null ||
            b.challengeId != null ||
            b.deadlineId != null);
    _distStart = _day;
  }

  @override
  void dispose() {
    _tabs.dispose();
    _topics.dispose();
    _location.dispose();
    _deadlineTitle.dispose();
    _name.dispose();
    _nameFocus.dispose();
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

  void _setDuration(int minutes) => setState(
    () => _endMin = (_startMin + minutes).clamp(_startMin, 24 * 60 - 1),
  );

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
          topics: t.requiresName
              ? _name.text.trim()
              : (t.usesTopics ? _topics.text : ''),
          location: t.usesLocation ? _location.text : '',
          priority: t.usesPriority ? _priority : null,
          privateBlock: _private,
          classKind: t == BlockType.classSession ? _classKind : null,
          routineId: t == BlockType.sport ? _routineId : null,
          // Si sigue siendo la misma rutina, el evento conserva su día
          // enlazado (si no, editarlo lo convertiría en deporte libre).
          routineWeekId: _keepsRoutineDay(t)
              ? widget.block?.routineWeekId
              : null,
          routineDayId: _keepsRoutineDay(t) ? widget.block?.routineDayId : null,
          challengeId: t.usesChallenge ? _challengeId : null,
          milestoneId: t.usesChallenge && _challengeId != null
              ? _milestoneId
              : null,
          deadlineId: t.usesDeadlineLink ? _deadlineId : null,
          deadlineTitle: t.createsDeadline && _deadlineId == null
              ? _deadlineTitle.text
              : null,
          deadlineDifficulty: t.createsDeadline && _deadlineId == null
              ? _deadlineDifficulty
              : null,
          repeatWeeks: !_editing && _repeat && t.canRepeatWeekly
              ? _repeatTotalWeeks - 1
              : 0,
        ),
      ),
    );
  }

  /// Lleva al campo «Nombre» y le da el foco cuando falta (lo diga la hoja o
  /// el servidor), aunque la persona esté abajo del todo.
  void _revealName() {
    final target = _nameKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: TokensDuration.normal,
        alignment: 0.1,
      );
    }
    _nameFocus.requestFocus();
  }

  /// «Tarea del reto»: las pendientes del reto elegido que avanzan con
  /// eventos (las vinculadas a una entrega las completa esa entrega). Cada
  /// evento hecho hace avanzar la tarea; el servidor comprueba que sea de ese
  /// reto y que el evento caiga en su periodo.
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

  /// El aviso de nombre vacío se ve mientras la persona no lo corrija.
  bool _showsNameError(BlockEditorState state) =>
      state.nameMissing && _nameErrorHandled != state.feedbackId;

  String? _feedback(BuildContext context, BlockEditorState state) {
    final l10n = context.localizations;
    if (state.nameMissing) {
      return _showsNameError(state) ? l10n.plannerIssueNameMissing : null;
    }
    final issue = state.issue;
    if (issue != null) {
      return switch (issue) {
        BlockEditorIssue.inPast => l10n.plannerInPast,
        BlockEditorIssue.tooShort => l10n.plannerIssueTooShort,
        BlockEditorIssue.noWeekdays => l10n.plannerIssueNoWeekdays,
        BlockEditorIssue.nameMissing => l10n.plannerIssueNameMissing,
      };
    }
    final error = state.error;
    return error == null ? null : errorMessage(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<BlockEditorBloc, BlockEditorState>(
      listenWhen: (a, b) =>
          (a.outcome != b.outcome && b.outcome != null) ||
          (a.feedbackId != b.feedbackId && b.nameMissing),
      listener: (context, state) {
        final outcome = state.outcome;
        if (outcome != null) {
          Navigator.of(context).pop(outcome);
        } else {
          _revealName();
        }
      },
      builder: (context, state) {
        final feedback = _feedback(context, state);
        final onRoutineTab = _withRoutineTab && _tabs.index == 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.m),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        _editing
                            ? l10n.plannerEditBlockTitle(_type.apiValue)
                            : l10n.plannerNewBlockTitle,
                        style: context.textStyles.titleLarge,
                      ),
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
                      icon: Icon(AppIcons.delete, color: context.colors.error),
                    ),
                  IconButton(
                    tooltip: l10n.commonClose,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(AppIcons.close),
                  ),
                ],
              ),
            ),
            if (_withRoutineTab)
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
                        if (_withRoutineTab) _routineForm(context, state),
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
    // El evento de un día de rutina sigue a su sesión: no se marca a mano, se
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
        // Un evento que aún no ha empezado no se marca como hecho.
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
            icon: const Icon(AppIcons.markDone),
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
          icon: Icon(block.completed ? AppIcons.undo : AppIcons.markDone),
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
          icon: const Icon(AppIcons.focusTimer),
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
    final focus = context.usageFocus;
    const small = SizedBox(height: TokensSpacing.s);
    const gap = SizedBox(height: TokensSpacing.m);
    // Entre pasos, más aire que entre campos: se ve dónde empieza cada uno.
    const stepGap = SizedBox(height: TokensSpacing.l);
    final canRepeat = !_editing && _type.canRepeatWeekly;
    // El paso 3 solo sale si hay algo que elegir o explicar: sin aviso
    // (descanso, comida, sueño) se queda en «Repetir» o desaparece.
    final hasReminder = _hasReminder;
    final showStep3 = canRepeat || hasReminder;
    final steps = showStep3 ? 3 : 2;
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        // Acciones del evento arriba del formulario: el pie fijo solo lleva
        // el botón principal (con texto grande no se come la pantalla).
        if (_editing) ...[..._blockActions(context, state), gap],
        if (state.optionsError != null) ...[
          AppInlineMessage(
            message: l10n.plannerOptionsError,
            tone: AppMessageTone.warning,
          ),
          gap,
        ],
        _StepHeader(number: 1, total: steps, title: l10n.plannerStepWhat),
        small,
        BlockTypePicker(
          label: l10n.plannerFieldType,
          // El tipo actual se conserva aunque el modo de uso ya no lo ofrezca.
          types: [
            for (final t in BlockType.values)
              if (t == _type || focus.allowsBlock(t)) t,
          ],
          selected: _type,
          onChanged: _changeType,
        ),
        if (_type.requiresName) ...[gap, ..._nameField(context, state)],
        stepGap,
        _StepHeader(number: 2, total: steps, title: l10n.plannerStepWhen),
        small,
        if (locked) ...[
          AppInlineMessage(
            message: l10n.plannerBlockLockedHint,
            tone: AppMessageTone.warning,
          ),
          small,
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
        small,
        ..._timeFields(context, locked),
        if (showStep3) ...[
          stepGap,
          _StepHeader(
            number: 3,
            total: steps,
            title: !hasReminder
                ? l10n.plannerStepRepeat
                : canRepeat
                ? l10n.plannerStepRepeatReminder
                : l10n.plannerStepReminder,
          ),
          small,
          // Exámenes y entregas no se repiten: cada uno tiene su fecha.
          if (canRepeat) ...[
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
            small,
          ],
          if (hasReminder) _reminderNote(context),
        ],
        stepGap,
        _moreOptionsToggle(context),
        if (_moreOptions) ...[small, ..._advancedFields(context, state)],
      ],
    );
  }

  /// «Nombre» de un evento personal: obligatorio. Su error sale aquí tanto si
  /// lo detecta la hoja como si lo devuelve el servidor.
  List<Widget> _nameField(BuildContext context, BlockEditorState state) {
    final l10n = context.localizations;
    return [
      // Qué cabe en «Personal», antes del campo: con texto grande la ayuda
      // del propio campo se cortaría.
      Text(l10n.plannerFieldNameHelper, style: context.textStyles.bodyLarge),
      const SizedBox(height: TokensSpacing.s),
      KeyedSubtree(
        key: _nameKey,
        child: AppTextField(
          label: l10n.plannerFieldName,
          hint: l10n.plannerFieldNameHint,
          controller: _name,
          focusNode: _nameFocus,
          icon: Icons.label_outline_rounded,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          errorText: _showsNameError(state)
              ? l10n.plannerIssueNameMissing
              : null,
          onChanged: (_) {
            final current = context.read<BlockEditorBloc>().state;
            if (_showsNameError(current)) {
              setState(() => _nameErrorHandled = current.feedbackId);
            }
          },
        ),
      ),
    ];
  }

  /// Cuándo avisa el servidor de este tipo de evento (la antelación es la de
  /// Ajustes › Avisos, igual para todos) y botón para cambiarla.
  Widget _reminderNote(BuildContext context) {
    final l10n = context.localizations;
    final hasReminder = _hasReminder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                hasReminder
                    ? AppIcons.notifications
                    : Icons.notifications_off_outlined,
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: TokensSpacing.m),
            Expanded(
              child: Text(
                l10n.plannerReminderLine(_type.apiValue),
                style: context.textStyles.bodyLarge,
              ),
            ),
          ],
        ),
        if (hasReminder)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: TokensSize.iconM + TokensSpacing.s,
            ),
            child: TextButton(
              onPressed: () =>
                  context.push(PlannerExternalPaths.notificationSettings),
              child: Text(l10n.plannerReminderSettings),
            ),
          ),
      ],
    );
  }

  /// Nombres de lo que hay en «Más opciones» para este tipo: se leen sin
  /// desplegarlo.
  List<String> _advancedLabels(BuildContext context) {
    final l10n = context.localizations;
    final t = _type;
    return [
      if (t.usesSubject) l10n.plannerFieldSubject,
      if (t.usesTopics && !t.requiresName) l10n.plannerFieldTopics,
      if (t.usesLocation) l10n.plannerFieldLocation,
      if (t.usesPriority) l10n.plannerFieldPriority,
      if (t == BlockType.classSession) l10n.plannerFieldClassKind,
      l10n.plannerFieldPrivate,
      if (t == BlockType.sport) l10n.plannerFieldRoutine,
      if (t.usesChallenge) l10n.plannerFieldChallenge,
      if (t.usesDeadlineLink) l10n.plannerFieldDeadline,
    ];
  }

  Widget _moreOptionsToggle(BuildContext context) {
    final l10n = context.localizations;
    return MergeSemantics(
      child: Semantics(
        expanded: _moreOptions,
        child: AppFocusOutline(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(AppIcons.filters),
            title: Text(
              l10n.plannerMoreOptions,
              style: context.textStyles.titleMedium,
            ),
            subtitle: Text(_advancedLabels(context).join(' · ')),
            trailing: Icon(
              _moreOptions
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
            ),
            onTap: () => setState(() => _moreOptions = !_moreOptions),
          ),
        ),
      ),
    );
  }

  /// Lo avanzado, solo lo que aplica a este tipo.
  List<Widget> _advancedFields(BuildContext context, BlockEditorState state) {
    final l10n = context.localizations;
    final deadlines = state.deadlines
        .where((d) => _subjectId == null || d.subjectId == _subjectId)
        .toList();
    // La entrega ya vinculada se conserva aunque no esté en la lista de pendientes.
    final linkedMissing =
        _deadlineId != null && !deadlines.any((d) => d.id == _deadlineId);
    const small = SizedBox(height: TokensSpacing.s);
    const gap = SizedBox(height: TokensSpacing.m);
    return [
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
        small,
      ],
      if (_type.usesTopics && !_type.requiresName) ...[
        AppTextField(
          label: l10n.plannerFieldTopics,
          hint: l10n.plannerFieldTopicsHint,
          controller: _topics,
          icon: Icons.notes_rounded,
          maxLines: 3,
        ),
        small,
      ],
      if (_type.usesLocation) ...[
        AppTextField(
          label: l10n.plannerFieldLocation,
          controller: _location,
          icon: Icons.place_outlined,
        ),
        small,
      ],
      if (_type.usesPriority) ...[
        small,
        // Con el texto al 200 % pasa a chips en varias filas: no se corta.
        AppSegmentedChoice<PlannerPriority>(
          label: l10n.plannerFieldPriority,
          values: PlannerPriority.values,
          selected: _priority,
          allowEmpty: true,
          labelOf: (p) => p.label(context),
          onChanged: (p) => setState(() => _priority = p),
        ),
        small,
      ],
      if (_type == BlockType.classSession) ...[
        small,
        AppSegmentedChoice<ClassKind>(
          label: l10n.plannerFieldClassKind,
          values: ClassKind.values,
          selected: _classKind,
          allowEmpty: true,
          labelOf: (k) => k.label(context),
          onChanged: (k) => setState(() => _classKind = k),
        ),
        small,
      ],
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
      if (_type == BlockType.sport) ...[
        gap,
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
      ],
      if (_type.usesChallenge) ...[
        gap,
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
          onChanged: (v) => setState(() {
            _challengeId = v;
            _milestoneId = null;
          }),
        ),
        small,
        ..._taskField(state),
      ],
      if (_type.usesDeadlineLink) ...[
        if (!_type.usesChallenge) gap,
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
      ],
      if (_type.createsDeadline && _deadlineId == null && !_editing) ...[
        small,
        AppTextField(
          label: l10n.plannerFieldDeadlineTitle,
          hint: l10n.plannerFieldDeadlineTitleHint,
          controller: _deadlineTitle,
          icon: Icons.title_rounded,
        ),
        small,
        AppSegmentedChoice<PlannerPriority>(
          label: l10n.plannerFieldDifficulty,
          values: PlannerPriority.values,
          selected: _deadlineDifficulty,
          labelOf: (p) => p.label(context),
          onChanged: (p) {
            if (p != null) setState(() => _deadlineDifficulty = p);
          },
        ),
      ],
    ];
  }

  /// Hora del evento según su tipo (ver [BlockType.timeInput]): una entrega
  /// pide su hora límite; examen, comida y descanso, inicio y duración
  /// típica; el resto, inicio, fin y atajos de duración.
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
        return [
          startField,
          const SizedBox(height: TokensSpacing.m),
          _durationChoices(context, _type.durationOptions, locked),
        ];
      case BlockTimeInput.range:
        final endField = PickerField(
          label: l10n.plannerFieldEnd,
          value: PlannerFormats.minutes(_endMin),
          icon: Icons.schedule_rounded,
          onTap: locked
              ? null
              : () async {
                  final m = await pickPlannerTime(context, _endMin);
                  if (m != null) setState(() => _endMin = m);
                },
        );
        return [
          // Con texto grande, uno debajo del otro: la hora no se corta.
          if (context.largeText) ...[
            startField,
            const SizedBox(height: TokensSpacing.s),
            endField,
          ] else
            Row(
              children: [
                Expanded(child: startField),
                const SizedBox(width: TokensSpacing.s),
                Expanded(child: endField),
              ],
            ),
          const SizedBox(height: TokensSpacing.m),
          _durationChoices(context, _quickDurations, locked),
        ];
    }
  }

  /// Duraciones en un toque. La actual se añade si no es una de ellas, para
  /// que siempre se vea cuánto dura. Ninguna baja de 30 min, el mínimo.
  Widget _durationChoices(BuildContext context, List<int> base, bool locked) {
    final l10n = context.localizations;
    final current = _endMin - _startMin;
    final options = {...base, if (current > 0) current}.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // El grupo de abajo ya lo dice al lector: no se lee dos veces.
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
                  onSelected: locked ? null : (_) => _setDuration(m),
                ),
            ],
          ),
        ),
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

/// Cabecera de un paso: número en círculo y pregunta. El lector de pantalla
/// la oye como encabezado («Paso 1 de 3: ¿Qué es?») y puede saltar de paso
/// en paso.
class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.number,
    required this.total,
    required this.title,
  });

  final int number;
  final int total;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: context.localizations.plannerStepSemantics(number, total, title),
      child: ExcludeSemantics(
        child: Row(
          children: [
            AppStepBadge(number: number),
            const SizedBox(width: TokensSpacing.s),
            Expanded(child: Text(title, style: context.textStyles.titleMedium)),
          ],
        ),
      ),
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
