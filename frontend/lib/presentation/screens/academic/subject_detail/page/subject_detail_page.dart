import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/guide_id.dart';
import '../../../../../domain/models/academic/subject.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../shell/widgets/first_time_guide.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../bloc/subject_detail_bloc.dart';
import '../bloc/subject_progress_bloc.dart';
import '../bloc/subject_syllabus_bloc.dart';
import 'progress_tab.dart';
import 'syllabus_tab.dart';

/// Pestañas del detalle de asignatura; `?tab=notes` abre la segunda.
enum SubjectDetailTab { progress, notes }

/// Detalle de asignatura con dos pestañas planas: Progreso y «Apuntes y
/// archivos». [initialTab] la elige quien enlaza (p. ej. el «Ver» de mover un
/// apunte).
class SubjectDetailPage extends StatelessWidget {
  const SubjectDetailPage({
    super.key,
    required this.subjectId,
    this.initialTab = SubjectDetailTab.progress,
  });

  final String subjectId;
  final SubjectDetailTab initialTab;

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
    child: _SubjectDetailView(initialTab: initialTab),
  );
}

class _SubjectDetailView extends StatefulWidget {
  const _SubjectDetailView({required this.initialTab});

  final SubjectDetailTab initialTab;

  @override
  State<_SubjectDetailView> createState() => _SubjectDetailViewState();
}

class _SubjectDetailViewState extends State<_SubjectDetailView>
    with ErrorsMessageMixin {
  SubjectDetailTab get initialTab => widget.initialTab;

  /// Partes que señala la guía la primera vez (ADR 0049).
  final _progressKey = GlobalKey(debugLabel: 'guide-subject-progress');
  final _notesKey = GlobalKey(debugLabel: 'guide-subject-notes');
  final _practiceKey = GlobalKey(debugLabel: 'guide-subject-practice');

  List<AppGuideStep> _guideSteps(BuildContext context) {
    final l10n = context.localizations;
    return [
      AppGuideStep(
        target: _progressKey,
        title: l10n.guideSubjectProgressTitle,
        body: l10n.guideSubjectProgressBody,
      ),
      AppGuideStep(
        target: _notesKey,
        title: l10n.guideSubjectNotesTitle,
        body: l10n.guideSubjectNotesBody,
      ),
      AppGuideStep(
        target: _practiceKey,
        title: l10n.guideSubjectPracticeTitle,
        body: l10n.guideSubjectPracticeBody,
      ),
    ];
  }

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
    // La guía, con la asignatura y su progreso ya cargados (el simulacro está
    // ahí); montada desde el principio para saber cómo se llegó (ADR 0049).
    final loaded = context.select<SubjectDetailBloc, bool>(
      (b) => b.state.subject != null,
    );
    final progressLoaded = context.select<SubjectProgressBloc, bool>(
      (b) => !b.state.loading,
    );
    final ready = loaded && progressLoaded;
    return FirstTimeGuide(
      guide: GuideId.subject,
      ready: ready,
      steps: _guideSteps,
      child: BlocConsumer<SubjectDetailBloc, SubjectDetailState>(
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
            context.popOrGo(AcademicPaths.root, true);
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
              appBar: const AppPageBar(
                leading: AppBackButton(fallback: AcademicPaths.root),
              ),
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
            length: SubjectDetailTab.values.length,
            initialIndex: initialTab.index,
            child: Scaffold(
              appBar: AppPageBar(
                leading: const AppBackButton(fallback: AcademicPaths.root),
                title: Text(
                  subject.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Solo el ⋮: el título no se recorta por los iconos y lo
                // ocasional (editar, archivar, eliminar) no compite con el
                // estudio (ADR 0039).
                actions: [
                  _SubjectMenu(
                    subject: subject,
                    busy: state.busy,
                    onEdit: () => _edit(context, subject),
                    onArchiveToggled: () => _toggleArchived(context, subject),
                    onDelete: () => _delete(context, subject),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(
                    TokensLayout.minTouchTarget,
                  ),
                  child: AcademicBody(
                    child: TabBar(
                      indicatorColor: color,
                      labelColor: color,
                      dividerColor: context.colors.outlineVariant,
                      tabs: [
                        Tab(key: _progressKey, text: l10n.academicTabProgress),
                        Tab(key: _notesKey, text: l10n.academicTabSyllabus),
                      ],
                    ),
                  ),
                ),
              ),
              // La cabecera se desplaza con el contenido: con el texto al 200 %
              // (o en horizontal) no deja las pestañas sin sitio.
              body: NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  if (state.busy)
                    const SliverToBoxAdapter(child: LinearProgressIndicator()),
                  SliverToBoxAdapter(
                    child: AcademicBody(
                      child: _SubjectHeader(
                        subject: subject,
                        semester: state.semester,
                        color: color,
                        onFocus: () => context.push(
                          AcademicPaths.pomodoro(
                            subjectId: subject.id,
                            title: subject.name,
                          ),
                        ),
                        onNewDeadline: () => context.push(
                          AcademicPaths.newDeadline(subjectId: subject.id),
                        ),
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  children: [
                    ProgressTab(practiceKey: _practiceKey),
                    const SyllabusTab(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SubjectHeader extends StatelessWidget {
  const _SubjectHeader({
    required this.subject,
    required this.semester,
    required this.color,
    required this.onFocus,
    required this.onNewDeadline,
  });

  final Subject subject;
  final SubjectSemester? semester;
  final Color color;

  /// «Concentrarme en esta asignatura» (Pomodoro que cuenta para ella).
  final VoidCallback onFocus;

  /// «+ Entrega» con la asignatura ya puesta.
  final VoidCallback onNewDeadline;

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
            width: TokensSize.emblem,
            height: TokensSize.emblem,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: AppPill.tintAlpha),
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
                      icon: AppIcons.priority,
                    ),
                    for (final (icon, text) in details)
                      AppPill(
                        label: text,
                        color: context.colors.onSurfaceVariant,
                        icon: icon,
                      ),
                  ],
                ),
                const SizedBox(height: TokensSpacing.s),
                // Lo que más se hace con una asignatura, a la vista y con
                // texto: estudiarla y apuntar una entrega (ADR 0039). Una
                // archivada no los lleva, como en Académico.
                if (!subject.archived)
                  Wrap(
                    spacing: TokensSpacing.s,
                    runSpacing: TokensSpacing.xs,
                    children: [
                      AppSecondaryButton(
                        label: l10n.academicSubjectFocusHere,
                        icon: const Icon(AppIcons.focusTimer),
                        onPressed: onFocus,
                      ),
                      AppSecondaryButton(
                        label: l10n.academicNewDeadline,
                        icon: const Icon(AppIcons.add),
                        onPressed: onNewDeadline,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ⋮ de la asignatura: editar, archivar (o restaurar) y eliminar, con texto.
class _SubjectMenu extends StatelessWidget {
  const _SubjectMenu({
    required this.subject,
    required this.busy,
    required this.onEdit,
    required this.onArchiveToggled,
    required this.onDelete,
  });

  final Subject subject;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onArchiveToggled;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return PopupMenuButton<VoidCallback>(
      tooltip: l10n.academicSubjectMoreActions(subject.name),
      icon: const Icon(Icons.more_vert_rounded),
      enabled: !busy,
      onSelected: (action) => action(),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: onEdit,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(AppIcons.edit),
            title: Text(l10n.commonEdit),
          ),
        ),
        PopupMenuItem(
          value: onArchiveToggled,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              subject.archived ? AppIcons.unarchive : AppIcons.archive,
            ),
            title: Text(
              subject.archived
                  ? l10n.academicSubjectUnarchive
                  : l10n.academicSubjectArchive,
            ),
          ),
        ),
        PopupMenuItem(
          value: onDelete,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            iconColor: context.colors.error,
            textColor: context.colors.error,
            leading: const Icon(AppIcons.delete),
            title: Text(l10n.academicSubjectDeleteAction),
          ),
        ),
      ],
    );
  }
}
