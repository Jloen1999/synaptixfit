import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/academic/subject.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../bloc/subject_detail_bloc.dart';
import '../bloc/subject_progress_bloc.dart';
import '../bloc/subject_syllabus_bloc.dart';
import 'progress_tab.dart';
import 'syllabus_tab.dart';

/// Detalle de asignatura con dos pestañas planas: Progreso y Temario.
class SubjectDetailPage extends StatelessWidget {
  const SubjectDetailPage({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) =>
            getIt<SubjectDetailBloc>()
              ..add(SubjectDetailEvent.started(subjectId)),
      ),
      BlocProvider(
        create: (_) =>
            getIt<SubjectProgressBloc>()
              ..add(SubjectProgressEvent.started(subjectId)),
      ),
      BlocProvider(
        create: (_) =>
            getIt<SubjectSyllabusBloc>()
              ..add(SubjectSyllabusEvent.started(subjectId)),
      ),
    ],
    child: const _SubjectDetailView(),
  );
}

class _SubjectDetailView extends StatelessWidget with ErrorsMessageMixin {
  const _SubjectDetailView();

  Future<void> _edit(BuildContext context, Subject subject) async {
    final detail = context.read<SubjectDetailBloc>();
    final changed = await context.push<bool>(
      AcademicPaths.editSubject(subject.id),
    );
    if (changed ?? false) detail.add(const SubjectDetailEvent.refreshed());
  }

  Future<void> _delete(BuildContext context, Subject subject) async {
    final l10n = context.localizations;
    final bloc = context.read<SubjectDetailBloc>();
    final ok = await confirmDestructive(
      context,
      title: l10n.academicSubjectDeleteTitle,
      message: l10n.academicSubjectDeleteMessage(subject.name),
    );
    if (ok) bloc.add(const SubjectDetailEvent.deleteRequested());
  }

  /// Archivar se explica antes (qué deja de verse y que nada se pierde);
  /// restaurar no necesita explicación.
  Future<void> _toggleArchived(BuildContext context, Subject subject) async {
    final l10n = context.localizations;
    final bloc = context.read<SubjectDetailBloc>();
    if (!subject.archived) {
      final ok = await showConfirmDialog(
        context,
        title: l10n.academicSubjectArchiveTitle,
        message: l10n.academicSubjectArchiveMessage,
        confirmLabel: l10n.academicSubjectArchive,
        destructive: false,
      );
      if (!ok || bloc.isClosed) return;
    }
    bloc.add(const SubjectDetailEvent.archiveToggled());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<SubjectDetailBloc, SubjectDetailState>(
      listenWhen: (a, b) =>
          a.deleted != b.deleted ||
          a.actionError != b.actionError ||
          (a.subject != null &&
              b.subject != null &&
              a.subject!.archived != b.subject!.archived),
      listener: (context, state) {
        final archivedNow = state.subject?.archived;
        if (state.deleted) {
          context.showSnack(l10n.academicSubjectDeleted);
          context.pop(true);
        } else if (state.actionError != null) {
          context.showSnack(errorMessage(context, state.actionError!));
        } else if (archivedNow == true) {
          // Nunca «se puede recuperar» sin decir dónde (vocabulario.md).
          context.showActionSnack(
            l10n.academicSubjectArchivedWhere,
            actionLabel: l10n.commonView,
            onAction: () => context.go(AcademicPaths.archived),
          );
        } else if (archivedNow == false) {
          context.showSnack(l10n.academicSubjectUnarchivedWhere);
        }
      },
      builder: (context, state) {
        final subject = state.subject;
        if (subject == null) {
          return Scaffold(
            appBar: const AppPageBar(),
            body: state.error != null
                ? AppErrorView(
                    error: state.error!,
                    onRetry: () => context.read<SubjectDetailBloc>().add(
                      SubjectDetailEvent.started(state.subjectId),
                    ),
                  )
                : const AppLoadingView(),
          );
        }
        final color = subjectColor(context, subject.id);
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppPageBar(
              title: Text(
                subject.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                // Pomodoro con el tiempo contando para esta asignatura.
                IconButton(
                  tooltip: l10n.academicSubjectFocus(subject.name),
                  icon: const Icon(AppIcons.focusTimer),
                  onPressed: () => context.push(
                    AcademicPaths.pomodoro(
                      subjectId: subject.id,
                      title: subject.name,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.commonEdit,
                  icon: const Icon(AppIcons.edit),
                  onPressed: () => _edit(context, subject),
                ),
                IconButton(
                  tooltip: l10n.academicSubjectDeleteAction,
                  icon: Icon(AppIcons.delete, color: context.colors.error),
                  onPressed: () => _delete(context, subject),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: AcademicBody(
                  child: TabBar(
                    indicatorColor: color,
                    labelColor: color,
                    dividerColor: context.colors.outlineVariant,
                    tabs: [
                      Tab(text: l10n.academicTabProgress),
                      Tab(text: l10n.academicTabSyllabus),
                    ],
                  ),
                ),
              ),
            ),
            body: Column(
              children: [
                if (state.busy) const LinearProgressIndicator(),
                AcademicBody(
                  child: _SubjectHeader(
                    subject: subject,
                    semester: state.semester,
                    color: color,
                    busy: state.busy,
                    onArchiveToggled: () => _toggleArchived(context, subject),
                  ),
                ),
                const Expanded(
                  child: TabBarView(children: [ProgressTab(), SyllabusTab()]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SubjectHeader extends StatelessWidget {
  const _SubjectHeader({
    required this.subject,
    required this.semester,
    required this.color,
    required this.busy,
    required this.onArchiveToggled,
  });

  final Subject subject;
  final SubjectSemester? semester;
  final Color color;
  final bool busy;
  final VoidCallback onArchiveToggled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final days = classDaysText(context, subject.classDays);
    final details = [
      if (subject.teacher != null && subject.teacher!.isNotEmpty)
        (Icons.person_outline_rounded, subject.teacher!),
      if (subject.room != null && subject.room!.isNotEmpty)
        (Icons.meeting_room_outlined, subject.room!),
      if (days != null) (Icons.event_repeat_rounded, days),
      if (subject.credits > 0)
        (Icons.stars_outlined, l10n.academicCreditsShort(subject.credits)),
      if (semester != null)
        (
          Icons.calendar_view_week_outlined,
          l10n.academicCourseSemester(semester!.course, semester!.semester),
        ),
      if (subject.nextAssessmentAt != null)
        (
          Icons.event_rounded,
          l10n.academicNextAssessment(shortDate(subject.nextAssessmentAt!)),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        TokensSpacing.m,
        TokensSpacing.m,
        TokensSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(TokensRadius.m),
            ),
            child: Text(
              subjectAcronym(subject),
              maxLines: 1,
              style: context.textStyles.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: TokensSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: TokensSpacing.s,
                  runSpacing: TokensSpacing.xs,
                  children: [
                    if (subject.archived)
                      AppPill(
                        label: l10n.academicSubjectArchivedBadge,
                        color: context.colors.onSurfaceVariant,
                        icon: AppIcons.archive,
                      ),
                    AppPill(
                      label: context.priorityLabel(subject.priority),
                      color: color,
                      icon: Icons.flag_outlined,
                    ),
                    for (final (icon, text) in details)
                      AppPill(
                        label: text,
                        color: context.colors.onSurfaceVariant,
                        icon: icon,
                      ),
                  ],
                ),
                // Acción con texto (antes escondida en un menú de tres puntos).
                TextButton.icon(
                  onPressed: busy ? null : onArchiveToggled,
                  icon: Icon(
                    subject.archived ? AppIcons.unarchive : AppIcons.archive,
                  ),
                  label: Text(
                    subject.archived
                        ? l10n.academicSubjectUnarchive
                        : l10n.academicSubjectArchive,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
