import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../domain/enums/pass_outlook.dart';
import '../../../../../domain/models/academic/study_material.dart';
import '../../../../../domain/models/academic/subject.dart';
import '../../../../../domain/models/academic/subject_timeline_item.dart';
import '../../../../../domain/models/academic/teaching_guide.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../bloc/subject_detail_bloc.dart';
import '../bloc/subject_progress_bloc.dart';
import 'guide_import_entry.dart';
import 'subject_detail_page.dart';
import 'subject_tab_body.dart';

/// Pestaña Resumen (ADR 0057), de arriba abajo: «Concentrarme» y «Nueva
/// entrega», lo próximo, los repasos de hoy con «Lo que dominas», practicar
/// y, de un vistazo, temas hechos y tu nota (o la invitación a importar la
/// guía docente).
class SummaryTab extends StatelessWidget {
  const SummaryTab({super.key, this.reviewsKey, this.practiceKey});

  /// Partes que señala la guía de la primera vez (ADR 0049).
  final GlobalKey? reviewsKey;
  final GlobalKey? practiceKey;

  /// Abre una pantalla y, al volver, recarga la asignatura y sus pestañas
  /// (repasos hechos, preguntas nuevas, entregas).
  static Future<void> _open(BuildContext context, String location) async {
    final progress = context.read<SubjectProgressBloc>();
    final detail = context.read<SubjectDetailBloc>();
    await context.push<Object?>(location);
    progress.add(const SubjectProgressEvent.refreshed());
    detail.add(const SubjectDetailEvent.refreshed());
  }

  @override
  Widget build(BuildContext context) {
    final subject = context.select<SubjectDetailBloc, Subject?>(
      (b) => b.state.subject,
    );
    return SubjectTabBody(
      children: (context, state) => [
        if (subject != null && !subject.archived) ...[
          _MainActions(subject: subject, onOpen: _open),
          const SizedBox(height: TokensSpacing.m),
        ],
        _NextUpCard(items: state.timeline),
        const SizedBox(height: TokensSpacing.m),
        _ReviewsCard(
          key: reviewsKey,
          due: state.due,
          retention: state.retention,
          onReview: () => _open(
            context,
            AcademicPaths.review(
              state.due.first.id,
              queue: [for (final m in state.due.skip(1)) m.id],
            ),
          ),
        ),
        const SizedBox(height: TokensSpacing.m),
        _PracticeCard(
          key: practiceKey,
          onCreateQuestions: () => _open(
            context,
            AcademicPaths.generate(subjectId: state.subjectId),
          ),
          onMockExam: () =>
              _open(context, AcademicPaths.subjectMockExam(state.subjectId)),
        ),
        const SizedBox(height: TokensSpacing.m),
        if (state.guide case final guide?)
          _GlanceCard(guide: guide)
        else
          _GuideInvite(subjectId: state.subjectId),
      ],
    );
  }
}

/// «Concentrarme» (Pomodoro que cuenta para la asignatura) y «Nueva entrega»
/// con la asignatura ya puesta.
class _MainActions extends StatelessWidget {
  const _MainActions({required this.subject, required this.onOpen});

  final Subject subject;
  final Future<void> Function(BuildContext context, String location) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final focus = AppPrimaryButton(
      label: l10n.academicFocus,
      icon: AppIcons.focusTimer,
      onPressed: () => context.push(
        AcademicPaths.pomodoro(subjectId: subject.id, title: subject.name),
      ),
    );
    final deadline = AppSecondaryButton(
      label: l10n.academicNewDeadline,
      icon: const Icon(AppIcons.add),
      onPressed: () =>
          onOpen(context, AcademicPaths.newDeadline(subjectId: subject.id)),
    );
    // Con el texto grande, uno debajo del otro: en fila no caben.
    if (context.largeText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          focus,
          const SizedBox(height: TokensSpacing.s),
          deadline,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: focus),
        const SizedBox(width: TokensSpacing.s),
        deadline,
      ],
    );
  }
}

/// «Lo próximo»: las tres cosas más cercanas (clase, entrega, examen) y el
/// atajo al calendario.
class _NextUpCard extends StatelessWidget {
  const _NextUpCard({required this.items});

  /// Cuántas se enseñan: lo de esta semana, sin convertirse en una agenda.
  static const _shown = 3;

  final List<SubjectTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final now = DateTime.now();
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        TokensSpacing.xs,
        TokensSpacing.xs,
        TokensSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.academicTimelineTitle,
                    style: context.textStyles.titleMedium,
                  ),
                ),
              ),
              // El calendario es una pestaña: se cambia a ella (no se apila).
              TextButton(
                onPressed: () => context.go(AcademicPaths.planner),
                child: Text(l10n.academicOpenPlanner),
              ),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(
                right: TokensSpacing.s,
                bottom: TokensSpacing.s,
              ),
              child: Text(
                l10n.academicTimelineEmpty,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          for (final item in items.take(_shown))
            AppFocusOutline(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: context.timelineLabel(item.type),
                        style: context.textStyles.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.title.isNotEmpty)
                        TextSpan(text: ' · ${item.title}'),
                    ],
                  ),
                  style: context.textStyles.bodyLarge?.copyWith(
                    decoration: item.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Text(
                  item.isDeadline && !item.completed
                      ? AppDueDates.text(context, item.start, now)
                      : dateTime(item.start),
                ),
                trailing: const Icon(AppIcons.next),
                // Una entrega es pantalla completa (`push`); el evento vive en
                // la pestaña Calendario (`go`).
                onTap: () => item.isDeadline
                    ? context.push(AcademicPaths.deadline(item.id))
                    : context.go(
                        AcademicPaths.plannerBlock(item.id, item.start),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

/// «3 repasos para hoy · Repasar» y «Lo que dominas» con su «?».
class _ReviewsCard extends StatelessWidget {
  const _ReviewsCard({
    super.key,
    required this.due,
    required this.retention,
    required this.onReview,
  });

  final List<StudyMaterial> due;
  final Retention? retention;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final r = retention;
    final percent = r == null ? 0 : (r.masteredRatio * 100).round();
    final title = Semantics(
      header: true,
      child: Text(
        due.isEmpty
            ? l10n.academicNoReviewsToday
            : l10n.academicReviewsForToday(due.length),
        style: context.textStyles.titleMedium,
      ),
    );
    final review = AppPrimaryButton(
      label: l10n.academicReviewNow,
      icon: AppIcons.review,
      onPressed: onReview,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Con el texto grande, el botón debajo: al lado partía el título.
          if (due.isNotEmpty && context.largeText) ...[
            title,
            const SizedBox(height: TokensSpacing.s),
            review,
          ] else
            Row(
              children: [
                Expanded(child: title),
                if (due.isNotEmpty) review,
              ],
            ),
          const SizedBox(height: TokensSpacing.s),
          AppHelpToggle(
            tooltip: l10n.academicMasteryHelpTooltip,
            help: l10n.academicMasteryHelp,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.academicRetentionTitle,
                    style: context.textStyles.titleSmall,
                  ),
                ),
                if (r != null && r.total > 0)
                  Text(
                    l10n.academicPercent(percent),
                    style: context.textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          if (r == null || r.total == 0)
            Text(
              l10n.academicRetentionEmpty,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            )
          else ...[
            ExcludeSemantics(
              child: AcademicProgressBar(
                value: r.masteredRatio,
                color: context.palette.study,
              ),
            ),
            const SizedBox(height: TokensSpacing.xs),
            Text(
              l10n.academicMasteryFrom(r.total),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// «Practicar»: crear preguntas (por ahora, el flujo de «Crear material») y
/// el simulacro de la asignatura.
class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    super.key,
    required this.onCreateQuestions,
    required this.onMockExam,
  });

  final VoidCallback onCreateQuestions;
  final VoidCallback onMockExam;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.academicPracticeAction,
              style: context.textStyles.titleMedium,
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.xs,
            children: [
              AppSecondaryButton(
                label: l10n.academicCreateQuestions,
                icon: const Icon(AppIcons.proposal),
                onPressed: onCreateQuestions,
              ),
              AppSecondaryButton(
                label: l10n.academicMockShort,
                icon: const Icon(AppIcons.exam),
                onPressed: onMockExam,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// «De un vistazo»: temas hechos (lleva a Temario) y tu nota (a Evaluación).
class _GlanceCard extends StatelessWidget {
  const _GlanceCard({required this.guide});

  final TeachingGuide guide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final done = guide.topicsDone;
    final estimate = guide.estimate;
    final graded = estimate != null && estimate.outlook != PassOutlook.noGrades;
    final tabs = DefaultTabController.maybeOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final stacked = context.largeText;
    void open(int tab) {
      if (tabs == null) return;
      // «Reducir movimiento»: se cambia de pestaña sin deslizar.
      reduceMotion ? tabs.index = tab : tabs.animateTo(tab);
    }

    Widget row(String label, String value, int tab) {
      final valueText = Text(
        value,
        style: context.textStyles.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      );
      // Con el texto grande, la cifra baja: al lado dejaba la etiqueta sin sitio.
      return AppFocusOutline(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label, style: context.textStyles.titleSmall),
          subtitle: stacked ? valueText : null,
          trailing: stacked
              ? const Icon(AppIcons.next)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    valueText,
                    const SizedBox(width: TokensSpacing.xs),
                    const Icon(AppIcons.next),
                  ],
                ),
          onTap: tabs == null ? null : () => open(tab),
        ),
      );
    }

    return Semantics(
      label: l10n.academicAtAGlance,
      container: true,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.m),
        child: Column(
          children: [
            if (guide.topics.isNotEmpty)
              row(
                l10n.academicTopicsDone,
                l10n.academicTopicsDoneValue(done, guide.topics.length),
                SubjectDetailTab.topics.index,
              ),
            if (guide.assessments.isNotEmpty)
              row(
                l10n.academicGradeSimulator,
                graded
                    ? l10n.academicPointsOfTotal(
                        grade(estimate.earnedPoints),
                        grade(estimate.possiblePoints),
                      )
                    : l10n.academicNoGradesYet,
                SubjectDetailTab.evaluation.index,
              ),
          ],
        ),
      ),
    );
  }
}

/// Sin guía docente: qué se gana y el botón para importarla.
class _GuideInvite extends StatelessWidget {
  const _GuideInvite({required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.importGuide, color: context.palette.study),
              const SizedBox(width: TokensSpacing.sm),
              Expanded(
                child: Text(
                  l10n.academicGuideEmptyTitle,
                  style: context.textStyles.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          // Secundario: «Concentrarme» y «Repasar» ya son los destacados.
          AppSecondaryButton(
            label: l10n.academicImportEntry,
            icon: const Icon(AppIcons.importGuide),
            onPressed: () => openGuideImport(context, subjectId),
          ),
        ],
      ),
    );
  }
}
