import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/evaluation_mode.dart';
import '../../../../../domain/enums/syllabus_topic_kind.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/teaching_guide_import.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../../widgets/file_pick.dart';
import '../bloc/teaching_guide_import_bloc.dart';

/// Asistente «Importar plan docente»: elegir PDF → la IA lo lee → revisar →
/// guardar. Si se abre desde una asignatura ([subjectId]), se completa esa.
class TeachingGuideImportPage extends StatelessWidget {
  const TeachingGuideImportPage({super.key, this.subjectId});

  final String? subjectId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<TeachingGuideImportBloc>()
          ..add(TeachingGuideImportEvent.started(targetSubjectId: subjectId)),
    child: const _ImportView(),
  );
}

/// El borrador tiene cambios del estudiante que se perderían al salir.
bool _isDirty(TeachingGuideImportState s) =>
    s.phase == GuideImportPhase.review && s.draft != s.guideImport?.draft;

Future<bool> _confirmDiscard(BuildContext context) {
  final l10n = context.localizations;
  return confirmDestructive(
    context,
    title: l10n.academicImportDiscardTitle,
    message: l10n.academicImportDiscardMessage,
    confirmLabel: l10n.academicImportDiscardConfirm,
  );
}

class _ImportView extends StatelessWidget with ErrorsMessageMixin {
  const _ImportView();

  /// Los cambios de paso se anuncian: el foco se pierde al cambiar el
  /// contenido y quien usa lector de pantalla no vería que el análisis acabó.
  void _announce(BuildContext context, TeachingGuideImportState state) {
    final l10n = context.localizations;
    final message = switch (state.phase) {
      GuideImportPhase.review => l10n.academicImportReviewTitle,
      GuideImportPhase.done => l10n.academicImportDoneTitle,
      GuideImportPhase.failed => errorMessage(
        context,
        state.error ?? const AppError.unknown(),
      ),
      _ => null,
    };
    if (message != null) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TeachingGuideImportBloc, TeachingGuideImportState>(
          listenWhen: (a, b) =>
              a.actionError != b.actionError && b.actionError != null,
          listener: (context, state) =>
              context.showSnack(errorMessage(context, state.actionError!)),
        ),
        BlocListener<TeachingGuideImportBloc, TeachingGuideImportState>(
          listenWhen: (a, b) => a.phase != b.phase,
          listener: _announce,
        ),
      ],
      child: BlocBuilder<TeachingGuideImportBloc, TeachingGuideImportState>(
        builder: (context, state) => PopScope(
          canPop: !_isDirty(state),
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final navigator = Navigator.of(context);
            if (await _confirmDiscard(context)) navigator.pop();
          },
          child: Scaffold(
            appBar: AppPageBar.reading(
              title: Text(context.localizations.academicImportTitle),
            ),
            body: AcademicBody(
              maxWidth: TokensLayout.readingMaxWidth,
              child: AnimatedSwitcher(
                duration: context.motion(TokensDuration.normal),
                child: switch (state.phase) {
                  GuideImportPhase.pick => const _PickStep(
                    key: ValueKey('pick'),
                  ),
                  GuideImportPhase.uploading || GuideImportPhase.analyzing =>
                    _WorkingStep(key: const ValueKey('working'), state: state),
                  GuideImportPhase.review ||
                  GuideImportPhase.applying => _ReviewStep(
                    key: ValueKey('review-${state.guideImport?.id}'),
                    state: state,
                  ),
                  GuideImportPhase.done => _DoneStep(
                    key: const ValueKey('done'),
                    state: state,
                  ),
                  GuideImportPhase.failed => _FailedStep(
                    key: const ValueKey('failed'),
                    state: state,
                  ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Título de paso, marcado como cabecera para la navegación por títulos.
class _StepTitle extends StatelessWidget {
  const _StepTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: context.textStyles.headlineSmall),
  );
}

// ---------------------------------------------------------------- 1. Elegir

class _PickStep extends StatelessWidget {
  const _PickStep({super.key});

  Future<void> _pick(BuildContext context) async {
    final bloc = context.read<TeachingGuideImportBloc>();
    final l10n = context.localizations;
    final picked = await pickPdfFile();
    if (!context.mounted || picked == null) return;
    switch (picked) {
      case PickedPayload(:final payload):
        bloc.add(TeachingGuideImportEvent.filePicked(payload));
      case PickedTooLarge():
        context.showSnack(l10n.academicImportTooLarge);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        AppCard(
          padding: const EdgeInsets.all(TokensSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: TokensSize.emptyBadge / 2,
                  backgroundColor: context.colors.tertiaryContainer,
                  child: Icon(
                    Icons.description_rounded,
                    size: TokensSize.iconL,
                    color: context.colors.onTertiaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              _StepTitle(l10n.academicImportIntroTitle),
              const SizedBox(height: TokensSpacing.s),
              Text(
                l10n.academicImportIntroBody,
                style: context.textStyles.bodyLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              _Benefit(
                icon: Icons.format_list_numbered_rounded,
                text: l10n.academicImportBenefitTopics,
              ),
              _Benefit(
                icon: Icons.pie_chart_outline_rounded,
                text: l10n.academicImportBenefitAssessments,
              ),
              _Benefit(
                icon: Icons.event_available_rounded,
                text: l10n.academicImportBenefitDates,
              ),
              const SizedBox(height: TokensSpacing.l),
              SizedBox(
                width: double.infinity,
                child: AppPrimaryButton(
                  label: l10n.academicImportPick,
                  icon: Icons.upload_file_rounded,
                  onPressed: () => _pick(context),
                ),
              ),
              const SizedBox(height: TokensSpacing.s),
              Center(
                child: Text(
                  l10n.academicImportPickHint,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
    child: Row(
      children: [
        Icon(icon, size: TokensSize.iconM, color: context.colors.tertiary),
        const SizedBox(width: TokensSpacing.sm),
        Expanded(child: Text(text, style: context.textStyles.bodyMedium)),
      ],
    ),
  );
}

// ---------------------------------------------------------------- 2. Analizar

class _WorkingStep extends StatelessWidget {
  const _WorkingStep({super.key, required this.state});

  final TeachingGuideImportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final uploading = state.phase == GuideImportPhase.uploading;
    final current = uploading
        ? l10n.academicImportStepUpload
        : l10n.academicImportStepRead;
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        AppCard(
          padding: const EdgeInsets.all(TokensSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.fileName != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppPill(
                    label: state.fileName!,
                    icon: Icons.picture_as_pdf_rounded,
                  ),
                ),
                const SizedBox(height: TokensSpacing.s),
              ],
              _StepRow(
                label: l10n.academicImportStepUpload,
                done: !uploading,
                active: uploading,
                progress: uploading ? state.uploadProgress : null,
              ),
              _StepRow(
                label: l10n.academicImportStepRead,
                done: false,
                active: !uploading,
              ),
              const SizedBox(height: TokensSpacing.m),
              // Solo cambia una vez por paso: el lector no repite cada avance.
              Semantics(
                liveRegion: true,
                child: Text(
                  '$current · ${l10n.academicImportWaitHint}',
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.done,
    required this.active,
    this.progress,
  });

  final String label;
  final bool done;
  final bool active;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final status = done
        ? l10n.academicImportStepDone
        : active
        ? l10n.academicImportStepRunning
        : l10n.academicImportStepPending;
    final color = done || active
        ? context.colors.onSurface
        : context.colors.onSurfaceVariant;
    return Semantics(
      label: l10n.academicImportStepStatus(label, status),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: TokensSpacing.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox.square(
                    dimension: TokensSize.iconM,
                    child: done
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: context.palette.success,
                          )
                        : active
                        ? const CircularProgressIndicator()
                        : Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: context.colors.outline,
                          ),
                  ),
                  const SizedBox(width: TokensSpacing.sm),
                  Expanded(
                    child: Text(
                      label,
                      style: context.textStyles.titleSmall?.copyWith(
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: TokensSpacing.s),
                AcademicProgressBar(
                  value: progress!,
                  color: context.colors.tertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- 3. Revisar

class _ReviewStep extends StatefulWidget {
  const _ReviewStep({super.key, required this.state});

  final TeachingGuideImportState state;

  @override
  State<_ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends State<_ReviewStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameKey = GlobalKey();
  final _nameFocus = FocusNode();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _credits;

  GuideDraft get _draft => widget.state.draft!;

  @override
  void initState() {
    super.initState();
    final info = _draft.info;
    _name = TextEditingController(text: info.name ?? '');
    _code = TextEditingController(text: info.code ?? '');
    _credits = TextEditingController(
      text: info.ectsCredits == null ? '' : grade(info.ectsCredits!),
    );
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _name.dispose();
    _code.dispose();
    _credits.dispose();
    super.dispose();
  }

  void _update(GuideDraft draft) => context.read<TeachingGuideImportBloc>().add(
    TeachingGuideImportEvent.draftChanged(draft),
  );

  void _onInfoChanged() => _update(
    _draft.copyWith(
      info: _draft.info.copyWith(
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        code: _code.text.trim().isEmpty ? null : _code.text.trim(),
        ectsCredits: double.tryParse(_credits.text.trim().replaceAll(',', '.')),
      ),
    ),
  );

  /// El botón siempre está activo: si falta el nombre, el error sale junto al
  /// campo y el foco va a él (un botón gris no explica qué falta).
  void _submit() {
    final creatingNew = widget.state.destinationSubjectId == null;
    if (creatingNew && !(_formKey.currentState?.validate() ?? false)) {
      final field = _nameKey.currentContext;
      if (field != null) Scrollable.ensureVisible(field);
      _nameFocus.requestFocus();
      return;
    }
    context.read<TeachingGuideImportBloc>().add(
      const TeachingGuideImportEvent.applied(),
    );
  }

  Future<void> _pickAnother() async {
    final bloc = context.read<TeachingGuideImportBloc>();
    if (_isDirty(widget.state) && !await _confirmDiscard(context)) return;
    bloc.add(const TeachingGuideImportEvent.restarted());
  }

  void _removeTopic(int index) {
    final before = _draft;
    _update(
      before.copyWith(
        topics: [...before.topics]..removeAt(index),
        assessments: _renumber(before, index),
      ),
    );
    final l10n = context.localizations;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.academicImportTopicRemoved),
          action: SnackBarAction(
            label: l10n.academicImportUndo,
            onPressed: () => _update(before),
          ),
        ),
      );
  }

  Future<void> _pickDate(int index, AssessmentDraft a) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: a.dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    _setDate(index, picked);
  }

  void _setDate(int index, DateTime? date) => _update(
    _draft.copyWith(
      assessments: [
        for (var i = 0; i < _draft.assessments.length; i++)
          i == index
              ? _draft.assessments[i].copyWith(dueDate: date)
              : _draft.assessments[i],
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final state = widget.state;
    final draft = _draft;
    final import = state.guideImport!;
    final applying = state.phase == GuideImportPhase.applying;
    final creatingNew = state.destinationSubjectId == null;
    final canChooseDestination =
        import.targetSubjectId == null &&
        import.suggestedSubjectId != null &&
        import.suggestedSubjectName != null;
    final dated = draft.activeAssessments
        .where((e) => e.$2.dueDate != null)
        .length;
    final mode = draft.effectiveMode;
    final total = draft.activeTotal.round();
    final place = [
      draft.info.degree,
      draft.info.university,
    ].whereType<String>().join(' · ');

    return Column(
      children: [
        Expanded(
          child: AbsorbPointer(
            absorbing: applying,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(TokensSpacing.m),
                children: [
                  _StepTitle(l10n.academicImportReviewTitle),
                  const SizedBox(height: TokensSpacing.xs),
                  Text(
                    l10n.academicImportReviewHint,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),

                  // Destino primero: decide si el nombre hace falta.
                  if (canChooseDestination) ...[
                    const SizedBox(height: TokensSpacing.l),
                    AppSectionHeader(title: l10n.academicImportDestination),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: RadioGroup<String?>(
                        groupValue: state.destinationSubjectId,
                        onChanged: (v) =>
                            context.read<TeachingGuideImportBloc>().add(
                              TeachingGuideImportEvent.destinationChanged(v),
                            ),
                        child: Column(
                          children: [
                            AppFocusOutline(
                              child: RadioListTile<String?>(
                                value: import.suggestedSubjectId,
                                title: Text(
                                  l10n.academicImportDestinationExisting(
                                    import.suggestedSubjectName!,
                                  ),
                                ),
                              ),
                            ),
                            AppFocusOutline(
                              child: RadioListTile<String?>(
                                value: null,
                                title: Text(l10n.academicImportDestinationNew),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (!creatingNew &&
                      import.suggestedSubjectName != null) ...[
                    const SizedBox(height: TokensSpacing.s),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppPill(
                        label: l10n.academicImportSavedInto(
                          import.suggestedSubjectName!,
                        ),
                        icon: Icons.bookmark_added_rounded,
                      ),
                    ),
                  ],

                  // Asignatura
                  const SizedBox(height: TokensSpacing.l),
                  AppSectionHeader(title: l10n.academicImportSubject),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Al completar una asignatura existente se conserva su
                        // nombre: el campo solo aparece al crear una nueva.
                        if (creatingNew) ...[
                          AppTextField(
                            key: _nameKey,
                            label: l10n.academicImportName,
                            controller: _name,
                            focusNode: _nameFocus,
                            textCapitalization: TextCapitalization.sentences,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(150),
                            ],
                            validator: (v) => (v ?? '').trim().length < 2
                                ? l10n.academicImportNameRequired
                                : null,
                            onChanged: (_) => _onInfoChanged(),
                          ),
                          const SizedBox(height: TokensSpacing.s),
                        ],
                        _CodeAndCredits(
                          code: AppTextField(
                            label: l10n.academicImportCode,
                            controller: _code,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(50),
                            ],
                            onChanged: (_) => _onInfoChanged(),
                          ),
                          credits: AppTextField(
                            label: l10n.academicImportCreditsShort,
                            suffixText: l10n.academicImportEctsSuffix,
                            controller: _credits,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                            ],
                            onChanged: (_) => _onInfoChanged(),
                          ),
                        ),
                        if (draft.info.semester != null ||
                            draft.info.character != null) ...[
                          const SizedBox(height: TokensSpacing.s),
                          Wrap(
                            spacing: TokensSpacing.s,
                            runSpacing: TokensSpacing.xs,
                            children: [
                              if (draft.info.semester != null)
                                AppPill(
                                  label: l10n.academicGuideInfoSemester(
                                    draft.info.semester!,
                                  ),
                                  icon: Icons.calendar_view_month_rounded,
                                ),
                              if (draft.info.character != null)
                                AppPill(
                                  label: sentenceCase(draft.info.character!),
                                ),
                            ],
                          ),
                        ],
                        if (place.isNotEmpty) ...[
                          const SizedBox(height: TokensSpacing.s),
                          Text(
                            place,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Temario
                  const SizedBox(height: TokensSpacing.l),
                  AppSectionHeader(
                    title: l10n.academicImportSyllabus(draft.topics.length),
                  ),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: draft.topics.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(TokensSpacing.m),
                            child: Text(l10n.academicGuideNoTopics),
                          )
                        : AppFocusOutline(
                            child: ExpansionTile(
                              shape: const Border(),
                              title: Text(l10n.academicImportSeeTopics),
                              children: [
                                for (var i = 0; i < draft.topics.length; i++)
                                  _TopicTile(
                                    number: i + 1,
                                    topic: draft.topics[i],
                                    onRemove: () => _removeTopic(i),
                                  ),
                              ],
                            ),
                          ),
                  ),

                  // Evaluación
                  const SizedBox(height: TokensSpacing.l),
                  AppSectionHeader(title: l10n.academicImportEvaluation),
                  if (draft.modes.length > 1) ...[
                    _ModeSelector(
                      label: l10n.academicImportModeQuestion,
                      selected: mode ?? draft.modes.first,
                      onChanged: (m) =>
                          _update(draft.copyWith(selectedMode: m)),
                    ),
                    const SizedBox(height: TokensSpacing.s),
                  ],
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (draft.activeAssessments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(TokensSpacing.m),
                            child: Text(l10n.academicGradeNoCriteria),
                          ),
                        for (final (index, a) in draft.activeAssessments)
                          _AssessmentTile(
                            assessment: a,
                            onPickDate: () => _pickDate(index, a),
                            onClearDate: () => _setDate(index, null),
                          ),
                      ],
                    ),
                  ),
                  if (draft.activeAssessments.isNotEmpty && total != 100)
                    Padding(
                      padding: const EdgeInsets.only(top: TokensSpacing.s),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: TokensSize.iconXs,
                            color: context.palette.warning,
                          ),
                          const SizedBox(width: TokensSpacing.xs),
                          Expanded(
                            child: Text(
                              l10n.academicImportTotalWarning(total),
                              // El color de aviso va solo en el icono: como
                              // texto no llega al contraste AA en tema claro.
                              style: context.textStyles.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: TokensSpacing.s),
                  AppFocusOutline(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: state.createDeadlines,
                      onChanged: (v) =>
                          context.read<TeachingGuideImportBloc>().add(
                            TeachingGuideImportEvent.createDeadlinesChanged(v),
                          ),
                      title: Text(l10n.academicImportCreateDeadlines),
                      subtitle: Text(
                        l10n.academicImportCreateDeadlinesHint(dated),
                      ),
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.xl),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensSpacing.m,
              TokensSpacing.s,
              TokensSpacing.m,
              TokensSpacing.m,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPrimaryButton(
                  label: creatingNew
                      ? l10n.academicImportApplyNew
                      : l10n.academicImportApplyExisting,
                  icon: Icons.check_rounded,
                  loading: applying,
                  onPressed: _submit,
                ),
                TextButton(
                  onPressed: applying ? null : _pickAnother,
                  child: Text(l10n.academicImportPickAnother),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Al quitar un tema, las pruebas dejan de citarlo y los posteriores bajan
  /// un número para seguir apuntando al mismo tema.
  static List<AssessmentDraft> _renumber(GuideDraft draft, int removed) {
    final number = removed + 1;
    return [
      for (final a in draft.assessments)
        a.copyWith(
          topicNumbers: [
            for (final n in a.topicNumbers)
              if (n != number) n > number ? n - 1 : n,
          ],
        ),
    ];
  }
}

/// Código y créditos: en fila si cabe; apilados en móviles estrechos o con
/// texto grande, donde la etiqueta se cortaría.
class _CodeAndCredits extends StatelessWidget {
  const _CodeAndCredits({required this.code, required this.credits});

  final Widget code;
  final Widget credits;

  /// Ancho mínimo para dos campos con su etiqueta completa.
  static const _rowMinWidth = TokensLayout.readingMaxWidth / 2;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final roomy = constraints.maxWidth >= context.scaled(_rowMinWidth);
      if (!roomy) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            code,
            const SizedBox(height: TokensSpacing.s),
            credits,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: code),
          const SizedBox(width: TokensSpacing.s),
          Expanded(child: credits),
        ],
      );
    },
  );
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final EvaluationMode selected;
  final ValueChanged<EvaluationMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.textStyles.titleSmall),
        const SizedBox(height: TokensSpacing.s),
        Semantics(
          label: label,
          child: SegmentedButton<EvaluationMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: EvaluationMode.continuous,
                label: Text(l10n.academicModeContinuous),
              ),
              ButtonSegment(
                value: EvaluationMode.global,
                label: Text(l10n.academicModeGlobal),
              ),
            ],
            selected: {selected},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ),
      ],
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.number,
    required this.topic,
    required this.onRemove,
  });

  final int number;
  final TopicDraft topic;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final details = [
      if (topic.kind == SyllabusTopicKind.practice) l10n.academicTopicPractice,
      if (topic.subtopics.isNotEmpty)
        l10n.academicImportSubtopics(topic.subtopics.length),
      if (topic.hours != null) l10n.academicImportHours(topic.hours!.round()),
    ];
    return ListTile(
      leading: SizedBox(
        width: context.scaled(TokensSize.iconL),
        child: Text(
          '$number',
          textAlign: TextAlign.center,
          style: context.textStyles.titleSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ),
      title: Text(topic.title),
      subtitle: details.isEmpty ? null : Text(details.join(' · ')),
      trailing: IconButton(
        tooltip: l10n.academicImportRemoveTopicNamed(number, topic.title),
        icon: const Icon(Icons.close_rounded),
        onPressed: onRemove,
      ),
    );
  }
}

/// Prueba con su peso y detalles; el control de fecha va debajo (no en el
/// `trailing`) para que en móviles estrechos el nombre siga teniendo sitio.
class _AssessmentTile extends StatelessWidget {
  const _AssessmentTile({
    required this.assessment,
    required this.onPickDate,
    required this.onClearDate,
  });

  final AssessmentDraft assessment;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final a = assessment;
    final details = [
      l10n.academicGradeWeight(a.percentage.round()),
      if (a.durationMinutes != null)
        l10n.academicImportDuration(a.durationMinutes!),
      if (a.topicNumbers.isNotEmpty)
        l10n.academicImportTopicsCovered(a.topicNumbers.join(', ')),
      if (a.recoverable == false) l10n.academicNotRecoverable,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        TokensSpacing.sm,
        TokensSpacing.s,
        TokensSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.name, style: context.textStyles.titleSmall),
          const SizedBox(height: TokensSpacing.xs),
          Text(
            details.join(' · '),
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (a.dueDate == null)
                Semantics(
                  label: l10n.academicImportAddDateFor(a.name),
                  button: true,
                  excludeSemantics: true,
                  child: TextButton.icon(
                    onPressed: onPickDate,
                    icon: const Icon(Icons.event_rounded),
                    label: Text(l10n.academicImportAddDate),
                  ),
                )
              else ...[
                Semantics(
                  label: l10n.academicImportDateOf(
                    a.name,
                    shortDate(a.dueDate!),
                  ),
                  button: true,
                  excludeSemantics: true,
                  child: TextButton.icon(
                    onPressed: onPickDate,
                    icon: const Icon(Icons.event_available_rounded),
                    label: Text(shortDate(a.dueDate!)),
                  ),
                ),
                IconButton(
                  tooltip: l10n.academicImportClearDateOf(a.name),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClearDate,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- 4. Listo

class _DoneStep extends StatelessWidget {
  const _DoneStep({super.key, required this.state});

  final TeachingGuideImportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final result = state.result!;
    final name = result.subjectCreated
        ? state.draft?.info.name ?? ''
        : state.guideImport?.suggestedSubjectName ??
              state.draft?.info.name ??
              '';
    final message = [
      result.subjectCreated
          ? l10n.academicImportDoneCreated(name)
          : l10n.academicImportDoneUpdated(name),
      if (result.deadlinesRequested > 0)
        l10n.academicImportDoneDeadlines(result.deadlinesRequested),
    ].join(' ');
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: Icons.check_circle_rounded,
            title: l10n.academicImportDoneTitle,
            message: message,
            action: AppPrimaryButton(
              label: l10n.academicImportOpenSubject,
              icon: Icons.arrow_forward_rounded,
              onPressed: () => context.pushReplacement(
                AcademicPaths.subject(result.subjectId),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Fallo

class _FailedStep extends StatelessWidget {
  const _FailedStep({super.key, required this.state});

  final TeachingGuideImportState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TeachingGuideImportBloc>();
    final l10n = context.localizations;
    void pickAnother() => bloc.add(const TeachingGuideImportEvent.restarted());
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppErrorView(
                error: state.error ?? const AppError.unknown(),
                onRetry: state.canRetry
                    ? () => bloc.add(const TeachingGuideImportEvent.retried())
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.all(TokensSpacing.m),
                child: state.canRetry
                    ? AppSecondaryButton(
                        label: l10n.academicImportPickAnother,
                        icon: const Icon(Icons.upload_file_rounded),
                        onPressed: pickAnother,
                      )
                    : AppPrimaryButton(
                        label: l10n.academicImportPickAnother,
                        icon: Icons.upload_file_rounded,
                        onPressed: pickAnother,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
