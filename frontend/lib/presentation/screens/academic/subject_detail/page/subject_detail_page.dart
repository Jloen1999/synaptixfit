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
import '../../material_share/bloc/material_share_bloc.dart';
import '../../material_share/page/material_share_sheet.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../bloc/subject_detail_bloc.dart';
import '../bloc/subject_progress_bloc.dart';
import '../bloc/subject_syllabus_bloc.dart';
import 'evaluation_tab.dart';
import 'guide_tab.dart';
import 'summary_tab.dart';
import 'syllabus_tab.dart';
import 'topics_tab.dart';

/// Pestañas del detalle de asignatura, en orden (ADR 0057 y 0064: Apuntes
/// antes que Evaluación); `?tab=<nombre>` abre una (`?tab=notes`, el «Ver» de
/// mover un apunte). Los nombres no cambian: los enlaces viejos siguen valiendo.
enum SubjectDetailTab {
  summary,
  topics,
  notes,
  evaluation,
  guide;

  /// La de `?tab=`; un valor desconocido (p. ej. `progress` de un enlace
  /// antiguo) abre el Resumen.
  static SubjectDetailTab fromQuery(String? value) =>
      values.asNameMap()[value] ?? summary;
}

/// Detalle de asignatura en cinco pestañas: Resumen, Temario, Apuntes,
/// Evaluación y Guía (ADR 0057 y 0064). [initialTab] la elige quien enlaza.
/// «Compartir» y «Descargar» de la lista «Material» usan un
/// [MaterialShareBloc] de la página, que pinta sus avisos.
class SubjectDetailPage extends StatelessWidget {
  const SubjectDetailPage({
    super.key,
    required this.subjectId,
    this.initialTab = SubjectDetailTab.summary,
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
      BlocProvider(create: (_) => getIt<MaterialShareBloc>()),
    ],
    child: MaterialShareFeedback(
      child: _SubjectDetailView(initialTab: initialTab),
    ),
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

  /// Partes que señala la guía la primera vez (ADR 0049): las pestañas, los
  /// repasos de hoy y practicar (las dos últimas, en el Resumen).
  final _tabsKey = GlobalKey(debugLabel: 'guide-subject-tabs');
  final _reviewsKey = GlobalKey(debugLabel: 'guide-subject-reviews');
  final _practiceKey = GlobalKey(debugLabel: 'guide-subject-practice');

  List<AppGuideStep> _guideSteps(BuildContext context) {
    final l10n = context.localizations;
    return [
      AppGuideStep(
        target: _tabsKey,
        title: l10n.guideSubjectTabsTitle,
        body: l10n.guideSubjectTabsBody,
      ),
      AppGuideStep(
        target: _reviewsKey,
        title: l10n.guideSubjectReviewsTitle,
        body: l10n.guideSubjectReviewsBody,
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
    // La guía, con la asignatura y el Resumen ya cargados (repasos y practicar
    // están ahí); montada desde el principio para saber cómo se llegó.
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
      // Errores de marcar temas, poner notas o cambiar la modalidad: un aviso.
      child: BlocListener<SubjectProgressBloc, SubjectProgressState>(
        listenWhen: (a, b) =>
            a.actionError != b.actionError && b.actionError != null,
        listener: (context, state) =>
            context.showSnack(errorMessage(context, state.actionError!)),
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
                ),
                // La cabecera y las pestañas, en este orden, se desplazan con
                // el contenido (como en la maqueta): el lector oye el nombre
                // antes que las pestañas, y con el texto al 200 % (o en
                // horizontal) no se comen la pantalla.
                body: NestedScrollView(
                  headerSliverBuilder: (context, _) => [
                    if (state.busy)
                      const SliverToBoxAdapter(
                        child: LinearProgressIndicator(),
                      ),
                    SliverToBoxAdapter(
                      child: AcademicBody(
                        child: _SubjectHeader(subject: subject),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: AcademicBody(
                        child: TabBar(
                          key: _tabsKey,
                          // Cinco pestañas: con el texto grande o en un móvil
                          // estrecho se desplazan en vez de cortarse.
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          indicatorColor: color,
                          labelColor: color,
                          dividerColor: context.colors.outlineVariant,
                          tabs: [
                            Tab(text: l10n.academicTabSummary),
                            Tab(text: l10n.academicTabTopics),
                            Tab(text: l10n.academicTabNotes),
                            Tab(text: l10n.academicTabEvaluation),
                            Tab(text: l10n.academicTabGuide),
                          ],
                        ),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    children: [
                      SummaryTab(
                        reviewsKey: _reviewsKey,
                        practiceKey: _practiceKey,
                      ),
                      const TopicsTab(),
                      const SyllabusTab(),
                      const EvaluationTab(),
                      const GuideTab(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Cabecera de la maqueta (ADR 0064): una franja con el color de la
/// asignatura, el nombre entero (en varias líneas si hace falta) y una sola
/// línea de datos, «6 ECTS · 2.º curso · 1.er cuatri» ([subjectMetaText]). El
/// color acompaña al nombre, nunca lo sustituye. «Archivada» va en su píldora.
class _SubjectHeader extends StatelessWidget {
  const _SubjectHeader({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final meta = subjectMetaText(context, subject);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        TokensSpacing.s,
        TokensSpacing.m,
        TokensSpacing.xs,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: Container(
                width: TokensSize.blockStripe,
                decoration: BoxDecoration(
                  color: subjectColor(context, subject.id),
                  borderRadius: BorderRadius.circular(TokensRadius.pill),
                ),
              ),
            ),
            const SizedBox(width: TokensSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      subject.name,
                      style: context.textStyles.headlineSmall,
                    ),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: TokensSpacing.xxs),
                    Text(
                      meta,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (subject.archived) ...[
                    const SizedBox(height: TokensSpacing.xs),
                    AppPill(
                      label: l10n.academicSubjectArchivedBadge,
                      color: context.colors.onSurfaceVariant,
                      icon: AppIcons.archive,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
        // Eliminar, aparte y en rojo.
        const PopupMenuDivider(),
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
