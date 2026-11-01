import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../domain/enums/evaluation_mode.dart';
import '../../../../../domain/enums/mastery_state.dart';
import '../../../../../domain/enums/syllabus_topic_kind.dart';
import '../../../../../domain/models/academic/study_material.dart';
import '../../../../../domain/models/academic/subject.dart';
import '../../../../../domain/models/academic/subject_timeline_item.dart';
import '../../../../../domain/models/academic/teaching_guide.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../bloc/subject_progress_bloc.dart';

/// Pestaña Progreso del detalle de asignatura.
class ProgressTab extends StatelessWidget with ErrorsMessageMixin {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubjectProgressBloc, SubjectProgressState>(
      listenWhen: (a, b) =>
          a.actionError != b.actionError && b.actionError != null,
      listener: (context, state) =>
          context.showSnack(errorMessage(context, state.actionError!)),
      builder: (context, state) {
        if (state.loading) {
          return const AppSkeletonList(height: 96);
        }
        if (state.error != null) {
          return AppErrorView(
            error: state.error!,
            onRetry: () => context.read<SubjectProgressBloc>().add(
              SubjectProgressEvent.started(state.subjectId),
            ),
          );
        }
        final guide = state.guide;
        return RefreshIndicator(
          onRefresh: () async => context.read<SubjectProgressBloc>().add(
            const SubjectProgressEvent.refreshed(),
          ),
          child: AcademicBody(
            child: ListView(
              padding: const EdgeInsets.all(TokensSpacing.m),
              children: [
                // Lo que toca y cómo va la memoria, primero: es lo que se
                // consulta a diario; el plan docente, debajo.
                _TimelineSection(items: state.timeline),
                const SizedBox(height: TokensSpacing.l),
                _RetentionSection(
                  retention: state.retention,
                  materials: state.materials,
                ),
                const SizedBox(height: TokensSpacing.l),
                if (guide == null)
                  _GuideEmpty(subjectId: state.subjectId)
                else ...[
                  _SyllabusSection(guide: guide),
                  const SizedBox(height: TokensSpacing.l),
                  _GradeSimulator(guide: guide, saving: state.savingGrade),
                  if (guide.professors.isNotEmpty) ...[
                    const SizedBox(height: TokensSpacing.l),
                    _ProfessorsSection(professors: guide.professors),
                  ],
                  if (guide.bibliography.isNotEmpty) ...[
                    const SizedBox(height: TokensSpacing.l),
                    _BibliographySection(items: guide.bibliography),
                  ],
                  const SizedBox(height: TokensSpacing.s),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () =>
                          _reimport(context, state.subjectId, guide),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        context.localizations.academicGuideRegenerate,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: TokensSpacing.xxl),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Abre «Importar plan docente» para esta asignatura y recarga al volver.
Future<void> _openImport(BuildContext context, String subjectId) async {
  final bloc = context.read<SubjectProgressBloc>();
  await context.push<Object?>(AcademicPaths.importGuide(subjectId: subjectId));
  bloc.add(const SubjectProgressEvent.refreshed());
}

/// Volver a importar conserva el progreso, pero se avisa si lo hay.
Future<void> _reimport(
  BuildContext context,
  String subjectId,
  TeachingGuide guide,
) async {
  final hasProgress =
      guide.topics.any((t) => t.completed) ||
      guide.assessments.any((a) => a.grade != null);
  if (hasProgress) {
    final l10n = context.localizations;
    final ok = await confirmDestructive(
      context,
      title: l10n.academicGuideReimportTitle,
      message: l10n.academicGuideReimportMessage,
      confirmLabel: l10n.academicGuideReimportConfirm,
    );
    if (!ok || !context.mounted) return;
  }
  await _openImport(context, subjectId);
}

/// Invitación compacta a importar el plan docente: icono, una frase y la acción.
class _GuideEmpty extends StatelessWidget {
  const _GuideEmpty({required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AppCard(
      // Wrap: con el texto grande el botón baja debajo en vez de aplastar el texto.
      child: Wrap(
        spacing: TokensSpacing.m,
        runSpacing: TokensSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_rounded, color: context.palette.study),
              const SizedBox(width: TokensSpacing.sm),
              Flexible(
                child: Text(
                  l10n.academicGuideEmptyTitle,
                  style: context.textStyles.titleSmall,
                ),
              ),
            ],
          ),
          AppPrimaryButton(
            label: l10n.academicImportEntry,
            icon: Icons.description_rounded,
            onPressed: () => _openImport(context, subjectId),
          ),
        ],
      ),
    );
  }
}

class _SyllabusSection extends StatefulWidget {
  const _SyllabusSection({required this.guide});

  final TeachingGuide guide;

  @override
  State<_SyllabusSection> createState() => _SyllabusSectionState();
}

class _SyllabusSectionState extends State<_SyllabusSection> {
  /// Con más temas la lista empuja el simulador demasiado abajo.
  static const _collapsedTopics = 5;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final guide = widget.guide;
    final progress = guide.syllabusProgress > 1
        ? guide.syllabusProgress / 100
        : guide.syllabusProgress;
    final pills = _infoPills(context, guide);
    final collapsible = guide.topics.length > _collapsedTopics;
    final visible = collapsible && !_expanded
        ? guide.topics.take(_collapsedTopics)
        : guide.topics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: l10n.academicGuideSyllabus,
          actionLabel: collapsible
              ? (_expanded ? l10n.academicGuideSeeLess : l10n.commonSeeAll)
              : null,
          actionExpanded: collapsible ? _expanded : null,
          onAction: collapsible
              ? () => setState(() => _expanded = !_expanded)
              : null,
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (pills.isNotEmpty) ...[
                Wrap(
                  spacing: TokensSpacing.s,
                  runSpacing: TokensSpacing.xs,
                  children: pills,
                ),
                const SizedBox(height: TokensSpacing.m),
              ],
              Text(
                l10n.academicGuideSyllabusCount(
                  guide.topics.where((t) => t.completed).length,
                  guide.topics.length,
                  (progress * 100).round(),
                ),
                style: context.textStyles.labelLarge,
              ),
              const SizedBox(height: TokensSpacing.s),
              ExcludeSemantics(
                child: AcademicProgressBar(
                  value: progress,
                  color: context.colors.tertiary,
                ),
              ),
              if (guide.topics.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: TokensSpacing.m),
                  child: Text(l10n.academicGuideNoTopics),
                ),
              for (final topic in visible)
                AppFocusOutline(
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: topic.completed,
                    onChanged: (v) => context.read<SubjectProgressBloc>().add(
                      SubjectProgressEvent.topicToggled(
                        index: topic.index,
                        completed: v ?? false,
                      ),
                    ),
                    title: Text(topic.title),
                    subtitle: Text(
                      [
                        topic.kind == SyllabusTopicKind.practice
                            ? l10n.academicTopicPractice
                            : l10n.academicTopicTheory,
                        if (topic.hours != null)
                          l10n.academicImportHours(topic.hours!.round()),
                        if (topic.subtopics.isNotEmpty)
                          l10n.academicImportSubtopics(topic.subtopics.length),
                      ].join(' · '),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Semestre y carácter del plan docente, si los trae. Los créditos ya salen
  /// en la cabecera de la asignatura: aquí no se repiten.
  static List<Widget> _infoPills(BuildContext context, TeachingGuide guide) {
    final l10n = context.localizations;
    final info = guide.info;
    return [
      if (info.semester != null)
        AppPill(
          label: l10n.academicGuideInfoSemester(info.semester!),
          icon: Icons.calendar_view_month_rounded,
        ),
      if (info.character != null) AppPill(label: sentenceCase(info.character!)),
    ];
  }
}

class _GradeSimulator extends StatelessWidget {
  const _GradeSimulator({required this.guide, required this.saving});

  final TeachingGuide guide;
  final bool saving;

  Future<void> _editGrade(BuildContext context, Assessment assessment) async {
    final bloc = context.read<SubjectProgressBloc>();
    final result = await showModalBottomSheet<({double? value})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _GradeSheet(assessment: assessment),
    );
    if (result != null) {
      bloc.add(
        SubjectProgressEvent.gradeChanged(
          index: assessment.index,
          grade: result.value,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final estimate = guide.estimate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: l10n.academicGradeSimulator),
        if (guide.availableModes.length > 1) ...[
          Text(
            l10n.academicGuideModeLabel,
            style: context.textStyles.titleSmall,
          ),
          const SizedBox(height: TokensSpacing.s),
          SegmentedButton<EvaluationMode>(
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
            selected: {guide.effectiveMode ?? guide.availableModes.first},
            onSelectionChanged: saving
                ? null
                : (s) => context.read<SubjectProgressBloc>().add(
                    SubjectProgressEvent.modeChanged(s.first),
                  ),
          ),
          const SizedBox(height: TokensSpacing.s),
        ],
        if (estimate != null)
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  icon: Icons.grade_rounded,
                  color: context.palette.accent,
                  value: grade(estimate.estimatedGrade),
                  label: l10n.academicGradeEstimated,
                ),
              ),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                child: AppMetricTile(
                  icon: Icons.pie_chart_outline_rounded,
                  color: context.colors.tertiary,
                  value: '${estimate.coveredPercentage.round()}%',
                  label: l10n.academicGradeCovered,
                ),
              ),
            ],
          ),
        if (estimate?.requiredGradeToPass != null ||
            estimate?.nextPendingAssessment != null)
          Padding(
            padding: const EdgeInsets.only(top: TokensSpacing.s),
            child: Text(
              [
                if (estimate!.requiredGradeToPass != null)
                  l10n.academicGradeRequired(
                    grade(estimate.requiredGradeToPass!),
                  ),
                if (estimate.nextPendingAssessment != null)
                  l10n.academicGradeNextPending(
                    estimate.nextPendingAssessment!,
                  ),
              ].join('\n'),
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: TokensSpacing.s),
        // Alto reservado: la barra de guardado no desplaza la lista.
        SizedBox(
          height: TokensSize.progressBar,
          child: saving ? const LinearProgressIndicator() : null,
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (guide.assessments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(TokensSpacing.m),
                  child: Text(l10n.academicGradeNoCriteria),
                ),
              for (final a in guide.assessments.where((a) => a.active))
                AppFocusOutline(
                  child: ListTile(
                    title: Text(a.name),
                    subtitle: Text(
                      [
                        l10n.academicGradeWeight(a.percentage.round()),
                        if (a.dueDate != null) shortDate(a.dueDate!),
                        if (a.recoverable == false) l10n.academicNotRecoverable,
                      ].join(' · '),
                    ),
                    // La acción se ve: «Poner nota» o la nota (verde si
                    // aprueba) con un lápiz para cambiarla.
                    trailing: a.grade == null
                        ? OutlinedButton.icon(
                            onPressed: saving
                                ? null
                                : () => _editGrade(context, a),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(l10n.academicGradeAdd),
                          )
                        : _GradeChip(
                            value: a.grade!,
                            onPressed: saving
                                ? null
                                : () => _editGrade(context, a),
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

/// Nota puesta: verde si aprueba (5 o más), de aviso si no; con lápiz.
class _GradeChip extends StatelessWidget {
  const _GradeChip({required this.value, required this.onPressed});

  final double value;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final passed = value >= _GradeSheet.passMark;
    final color = passed ? context.palette.success : context.palette.warning;
    // Aprobado o no con icono y en el texto accesible, no solo con el color.
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: color),
      icon: Icon(
        passed
            ? Icons.check_circle_outline_rounded
            : Icons.error_outline_rounded,
        size: TokensSize.iconXs,
      ),
      label: Text(
        grade(value),
        semanticsLabel: l10n.academicGradeEditSemantics(
          grade(value),
          passed ? l10n.academicGradePassed : l10n.academicGradeFailed,
        ),
        style: context.textStyles.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Hoja para poner la nota de un criterio: número grande, deslizador de 0 a
/// 10 (de 0,25 en 0,25), atajos 5-10 y un campo para la nota exacta.
class _GradeSheet extends StatefulWidget {
  const _GradeSheet({required this.assessment});

  final Assessment assessment;

  /// Aprobado en la escala española (0-10).
  static const passMark = 5.0;

  @override
  State<_GradeSheet> createState() => _GradeSheetState();
}

class _GradeSheetState extends State<_GradeSheet> {
  late double _value = widget.assessment.grade ?? _GradeSheet.passMark;
  late final _text = TextEditingController(text: grade(_value));

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// El campo tiene un valor que no es una nota de 0 a 10.
  bool _invalid = false;

  void _set(double v, {bool fromText = false}) {
    setState(() {
      _value = v.clamp(0, 10).toDouble();
      _invalid = false;
    });
    if (!fromText) _text.text = grade(_value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final color = _value >= _GradeSheet.passMark
        ? context.palette.success
        : context.palette.warning;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        TokensSpacing.m,
        0,
        TokensSpacing.m,
        TokensSpacing.m + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.assessment.name, style: context.textStyles.titleMedium),
            Text(
              l10n.academicGradeWeight(widget.assessment.percentage.round()),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TokensSpacing.m),
            Center(
              child: Text(
                grade(_value),
                style: context.textStyles.displaySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Center(
              child: Text(
                _value >= _GradeSheet.passMark
                    ? l10n.academicGradePassed
                    : l10n.academicGradeFailed,
                style: context.textStyles.labelLarge?.copyWith(color: color),
              ),
            ),
            Slider(
              value: _value,
              max: 10,
              divisions: 40,
              label: grade(_value),
              semanticFormatterCallback: (v) => grade(v),
              onChanged: _set,
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: TokensSpacing.xs,
              runSpacing: TokensSpacing.xs,
              children: [
                for (final quick in const [5.0, 6.0, 7.0, 8.0, 9.0, 10.0])
                  ChoiceChip(
                    label: Text(grade(quick)),
                    selected: _value == quick,
                    onSelected: (_) => _set(quick),
                  ),
              ],
            ),
            const SizedBox(height: TokensSpacing.m),
            TextField(
              controller: _text,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.academicGradeLabel,
                hintText: l10n.academicGradeHint,
                errorText: _invalid ? l10n.academicGradeOutOfRange : null,
              ),
              onChanged: (t) {
                final v = double.tryParse(t.trim().replaceAll(',', '.'));
                if (v != null && v >= 0 && v <= 10) {
                  _set(v, fromText: true);
                } else {
                  setState(() => _invalid = t.trim().isNotEmpty);
                }
              },
            ),
            const SizedBox(height: TokensSpacing.m),
            Row(
              children: [
                if (widget.assessment.grade != null)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop((value: null)),
                    child: Text(l10n.academicGradeClear),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _invalid
                      ? null
                      : () => Navigator.of(context).pop((value: _value)),
                  child: Text(l10n.commonSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfessorsSection extends StatelessWidget {
  const _ProfessorsSection({required this.professors});

  final List<Professor> professors;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppSectionHeader(title: context.localizations.academicGuideProfessors),
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (final p in professors)
              ListTile(
                leading: AppAvatar(name: p.name),
                title: Text(p.name),
                subtitle: Text([?p.email, ?p.office].join(' · ')),
              ),
          ],
        ),
      ),
    ],
  );
}

class _BibliographySection extends StatelessWidget {
  const _BibliographySection({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppSectionHeader(title: context.localizations.academicGuideBibliography),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.book_outlined,
                      size: TokensSize.iconXs,
                      color: context.colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: TokensSpacing.s),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class _RetentionSection extends StatelessWidget {
  const _RetentionSection({required this.retention, required this.materials});

  final Retention? retention;
  final List<StudyMaterial> materials;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final r = retention;
    final counts = r == null
        ? const <(MasteryState, int)>[]
        : [
            (MasteryState.mastered, r.mastered),
            (MasteryState.inProgress, r.inProgress),
            (MasteryState.needsReview, r.needsReview),
            (MasteryState.notEvaluated, r.notEvaluated),
            (MasteryState.abandoned, r.abandoned),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: l10n.academicRetentionTitle),
        AppCard(
          child: r == null || r.total == 0
              ? Text(l10n.academicRetentionEmpty)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.academicRetentionSummary(
                        (r.masteredRatio * 100).round(),
                        r.total,
                      ),
                      style: context.textStyles.labelLarge,
                    ),
                    const SizedBox(height: TokensSpacing.s),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(TokensRadius.pill),
                      child: SizedBox(
                        height: TokensSize.progressBar,
                        child: Row(
                          children: [
                            for (final (state, count) in counts)
                              if (count > 0)
                                Expanded(
                                  flex: count,
                                  child: ColoredBox(
                                    color: context.masteryColor(state),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: TokensSpacing.s),
                    Wrap(
                      spacing: TokensSpacing.s,
                      runSpacing: TokensSpacing.xs,
                      children: [
                        for (final (state, count) in counts)
                          AppPill(
                            label: '${context.masteryLabel(state)} · $count',
                            color: context.masteryColor(state),
                          ),
                      ],
                    ),
                  ],
                ),
        ),
        if (materials.isNotEmpty) ...[
          const SizedBox(height: TokensSpacing.s),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final m in materials)
                  AppFocusOutline(
                    child: ListTile(
                      leading: Icon(
                        Icons.replay_rounded,
                        color: context.masteryColor(m.masteryState),
                      ),
                      title: Text(
                        m.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        m.nextReviewAt == null
                            ? context.masteryLabel(m.masteryState)
                            : '${context.masteryLabel(m.masteryState)} · ${l10n.academicNextReview(shortDate(m.nextReviewAt!))}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(AcademicPaths.review(m.id)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.items});

  final List<SubjectTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: l10n.academicTimelineTitle,
          actionLabel: l10n.academicOpenPlanner,
          onAction: () => context.push(AcademicPaths.planner),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(TokensSpacing.m),
                  child: Text(l10n.academicTimelineEmpty),
                )
              : Column(
                  children: [
                    for (final item in items)
                      AppFocusOutline(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                (item.isDeadline
                                        ? context.palette.warning
                                        : context.colors.tertiary)
                                    .withValues(alpha: AppPill.tintAlpha),
                            child: Icon(
                              timelineIcon(item.type),
                              color: item.isDeadline
                                  ? context.palette.warning
                                  : context.colors.tertiary,
                            ),
                          ),
                          title: Text(
                            item.title.isEmpty
                                ? context.timelineLabel(item.type)
                                : item.title,
                            style: item.completed
                                ? context.textStyles.bodyLarge?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                  )
                                : null,
                          ),
                          subtitle: Text(
                            '${context.timelineLabel(item.type)} · ${dateTime(item.start)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.completed)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: context.palette.success,
                                  semanticLabel: l10n.academicCompleted,
                                ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                          // Abre lo mismo que la agenda de Inicio: el bloque en
                          // su día del calendario o la lista de entregas.
                          onTap: () => context.push(
                            item.isDeadline
                                ? AcademicPaths.deadlines
                                : AcademicPaths.plannerBlock(
                                    item.id,
                                    item.start,
                                  ),
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
