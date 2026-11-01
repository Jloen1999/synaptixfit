import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/academic/note.dart';
import '../../../../../domain/models/academic/study_material.dart';
import '../../../../../domain/models/academic/subject.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../../widgets/subject_card.dart';
import '../bloc/academic_home_bloc.dart';

/// Pestaña Académico: cuadrícula de asignaturas, repasos pendientes y accesos.
class AcademicHomePage extends StatelessWidget {
  const AcademicHomePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<AcademicHomeBloc>()..add(const AcademicHomeEvent.started()),
    child: const _AcademicHomeView(),
  );
}

class _AcademicHomeView extends StatelessWidget with ErrorsMessageMixin {
  const _AcademicHomeView();

  /// Abre una ruta y recarga al volver.
  Future<void> _open(BuildContext context, String location) async {
    final bloc = context.read<AcademicHomeBloc>();
    await context.push<Object?>(location);
    bloc.add(const AcademicHomeEvent.refreshed());
  }

  void _showAddSheet(BuildContext context) {
    final l10n = context.localizations;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // Seis opciones de dos líneas no caben en 9/16 de un móvil mediano.
      isScrollControlled: true,
      builder: (sheetContext) {
        Widget group(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensSpacing.m,
            TokensSpacing.s,
            TokensSpacing.m,
            TokensSpacing.xs,
          ),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: sheetContext.textStyles.titleSmall?.copyWith(
                color: sheetContext.colors.onSurfaceVariant,
              ),
            ),
          ),
        );
        Widget option(
          IconData icon,
          String title,
          String subtitle,
          String to,
        ) => AppFocusOutline(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: sheetContext.colors.tertiaryContainer,
              child: Icon(icon, color: sheetContext.colors.onTertiaryContainer),
            ),
            title: Text(title),
            subtitle: Text(subtitle),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _open(context, to);
            },
          ),
        );
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                group(l10n.academicAddGroupSubject),
                option(
                  Icons.description_rounded,
                  l10n.academicImportEntry,
                  l10n.academicImportEntryHint,
                  AcademicPaths.importGuide(),
                ),
                option(
                  Icons.library_add_rounded,
                  l10n.academicAddFromCatalog,
                  l10n.academicAddFromCatalogHint,
                  AcademicPaths.catalog,
                ),
                option(
                  Icons.edit_note_rounded,
                  l10n.academicAddManual,
                  l10n.academicAddManualHint,
                  AcademicPaths.newSubject,
                ),
                group(l10n.academicAddGroupNotes),
                option(
                  Icons.sticky_note_2_outlined,
                  l10n.academicQuickNote,
                  l10n.academicQuickNoteHint,
                  AcademicPaths.newNote(quick: true),
                ),
                option(
                  Icons.auto_awesome_rounded,
                  l10n.academicGenerateTitle,
                  l10n.academicGenerateHint,
                  AcademicPaths.generate(),
                ),
                const SizedBox(height: TokensSpacing.s),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Scaffold(
      appBar: AppPageBar(
        title: Text(l10n.tabAcademic),
        actions: [
          IconButton(
            tooltip: l10n.academicSharedNotesTitle,
            icon: const Icon(Icons.local_library_outlined),
            onPressed: () => context.push(AcademicPaths.sharedNotes),
          ),
          IconButton(
            tooltip: l10n.academicOpenPlanner,
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => context.push(AcademicPaths.planner),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.academicAdd),
      ),
      body: BlocConsumer<AcademicHomeBloc, AcademicHomeState>(
        listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
        listener: (context, state) {
          final notice = state.notice!;
          context.read<AcademicHomeBloc>().add(
            const AcademicHomeEvent.noticeHandled(),
          );
          context.showSnack(switch (notice) {
            AcademicHomeNoticeNoteMoved(:final subjectName) =>
              l10n.academicInboxMoved(subjectName),
            AcademicHomeNoticeFailed(:final error) => errorMessage(
              context,
              error,
            ),
          });
        },
        builder: (context, state) {
          if (state.loading && state.subjects.isEmpty) {
            return const AppSkeletonList(count: 6, height: 120);
          }
          if (state.error != null && state.subjects.isEmpty) {
            return AppErrorView(
              error: state.error!,
              onRetry: () => context.read<AcademicHomeBloc>().add(
                const AcademicHomeEvent.started(),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => context.read<AcademicHomeBloc>().add(
              const AcademicHomeEvent.refreshed(),
            ),
            child: AcademicBody(
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (state.due.isNotEmpty && !state.showArchived)
                    SliverToBoxAdapter(
                      child: _DueReviews(
                        due: state.due,
                        onOpen: (m) =>
                            _open(context, AcademicPaths.review(m.id)),
                        onReviewAll: () => _open(
                          context,
                          AcademicPaths.review(
                            state.due.first.id,
                            queue: [for (final m in state.due.skip(1)) m.id],
                          ),
                        ),
                      ),
                    ),
                  if (state.inbox.isNotEmpty && !state.showArchived)
                    SliverToBoxAdapter(
                      child: _NotesInbox(
                        notes: state.inbox,
                        subjects: state.subjects,
                        moving: state.movingNoteIds,
                        onOpen: (note) =>
                            _open(context, AcademicPaths.note(note.id)),
                        onMove: (note, subjectId) =>
                            context.read<AcademicHomeBloc>().add(
                              AcademicHomeEvent.noteMoved(
                                noteId: note.id,
                                subjectId: subjectId,
                              ),
                            ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensSpacing.m,
                      TokensSpacing.m,
                      TokensSpacing.m,
                      TokensSpacing.s,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.academicSubjectsTitle,
                              style: context.textStyles.titleMedium,
                            ),
                          ),
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: false,
                                label: Text(l10n.academicFilterActive),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text(l10n.academicFilterArchived),
                              ),
                            ],
                            selected: {state.showArchived},
                            onSelectionChanged: (s) =>
                                context.read<AcademicHomeBloc>().add(
                                  AcademicHomeEvent.archivedToggled(
                                    archived: s.first,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.loading)
                    const SliverToBoxAdapter(child: LinearProgressIndicator()),
                  if (state.subjects.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        icon: state.showArchived
                            ? Icons.archive_outlined
                            : Icons.school_outlined,
                        title: state.showArchived
                            ? l10n.academicArchivedEmptyTitle
                            : l10n.academicEmptyTitle,
                        message: state.showArchived
                            ? null
                            : l10n.academicEmptyMessage,
                        action: state.showArchived
                            ? null
                            : AppPrimaryButton(
                                label: l10n.academicImportEntry,
                                icon: Icons.description_rounded,
                                onPressed: () =>
                                    _open(context, AcademicPaths.importGuide()),
                              ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        TokensSpacing.m,
                        0,
                        TokensSpacing.m,
                        TokensSpacing.xxl * 2,
                      ),
                      sliver: SliverGrid.builder(
                        // El alto y el ancho crecen con el texto: al 200 %
                        // la tarjeta no se desborda (una columna en móvil).
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: context.scaled(
                            TokensSize.subjectCardMaxWidth,
                          ),
                          mainAxisExtent: context.scaled(
                            TokensSize.subjectCardHeight,
                          ),
                          crossAxisSpacing: TokensSpacing.s,
                          mainAxisSpacing: TokensSpacing.s,
                        ),
                        itemCount: state.subjects.length,
                        itemBuilder: (context, index) {
                          final subject = state.subjects[index];
                          return SubjectCard(
                            subject: subject,
                            onTap: () => _open(
                              context,
                              AcademicPaths.subject(subject.id),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DueReviews extends StatelessWidget {
  const _DueReviews({
    required this.due,
    required this.onOpen,
    required this.onReviewAll,
  });

  final List<StudyMaterial> due;
  final ValueChanged<StudyMaterial> onOpen;

  /// Repasa todos los pendientes seguidos (se ofrece con dos o más).
  final VoidCallback onReviewAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Padding(
      padding: const EdgeInsets.only(top: TokensSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.m),
            child: Row(
              children: [
                Icon(Icons.replay_rounded, color: context.palette.study),
                const SizedBox(width: TokensSpacing.s),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.academicDueReviews(due.length),
                      style: context.textStyles.titleMedium,
                    ),
                  ),
                ),
                if (due.length > 1 && !context.largeText)
                  TextButton.icon(
                    onPressed: onReviewAll,
                    icon: const Icon(Icons.playlist_play_rounded),
                    label: Text(l10n.academicReviewAll),
                  ),
              ],
            ),
          ),
          // Con el texto grande, el botón baja: al lado dejaba el título en
          // una letra por línea.
          if (due.length > 1 && context.largeText)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.m),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: onReviewAll,
                  icon: const Icon(Icons.playlist_play_rounded),
                  label: Text(l10n.academicReviewAll),
                ),
              ),
            ),
          const SizedBox(height: TokensSpacing.s),
          SizedBox(
            height: context.scaled(TokensSize.reviewCardHeight),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.m),
              scrollDirection: Axis.horizontal,
              itemCount: due.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: TokensSpacing.s),
              itemBuilder: (context, index) {
                final material = due[index];
                return SizedBox(
                  width: context.scaled(TokensSize.reviewCardWidth),
                  child: AppCard(
                    onTap: () => onOpen(material),
                    color: Color.alphaBlend(
                      context.palette.study.withValues(
                        alpha: AppPill.tintAlpha,
                      ),
                      context.colors.surface,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.titleSmall,
                        ),
                        const Spacer(),
                        AppPill(
                          label: context.masteryLabel(material.masteryState),
                          color: context.masteryColor(material.masteryState),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeja de notas sin asignatura: abrir cada una y llevarla a su
/// asignatura. Abrir y mover son acciones hermanas (sin toques anidados).
class _NotesInbox extends StatelessWidget {
  const _NotesInbox({
    required this.notes,
    required this.subjects,
    required this.moving,
    required this.onOpen,
    required this.onMove,
  });

  final List<Note> notes;
  final List<Subject> subjects;
  final Set<String> moving;
  final ValueChanged<Note> onOpen;
  final void Function(Note note, String subjectId) onMove;

  Future<void> _pickSubject(BuildContext context, Note note) async {
    final l10n = context.localizations;
    final subjectId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TokensSpacing.m,
                  0,
                  TokensSpacing.m,
                  TokensSpacing.s,
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.academicInboxMoveTitle(note.title),
                    style: sheetContext.textStyles.titleMedium,
                  ),
                ),
              ),
              for (final subject in subjects)
                AppFocusOutline(
                  child: ListTile(
                    leading: const Icon(Icons.school_outlined),
                    title: Text(subject.name),
                    onTap: () => Navigator.of(sheetContext).pop(subject.id),
                  ),
                ),
              const SizedBox(height: TokensSpacing.s),
            ],
          ),
        ),
      ),
    );
    if (subjectId != null) onMove(note, subjectId);
  }

  @override
  Widget build(BuildContext context) {
    // Con poco ancho o texto grande, el botón baja bajo el título para no
    // comérselo (mismo umbral que las filas con acciones).
    return LayoutBuilder(
      builder: (context, constraints) => _content(
        context,
        stacked:
            context.largeText ||
            constraints.maxWidth < TokensLayout.cardActionsInlineMin,
      ),
    );
  }

  Widget _content(BuildContext context, {required bool stacked}) {
    final l10n = context.localizations;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        TokensSpacing.m,
        TokensSpacing.m,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.inbox_outlined, color: context.palette.study),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.academicInboxTitle(notes.length),
                    style: context.textStyles.titleMedium,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.xxs),
          Text(
            l10n.academicInboxHint,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          AppCard(
            padding: const EdgeInsets.all(TokensSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final note in notes)
                  _InboxRow(
                    note: note,
                    stacked: stacked,
                    moving: moving.contains(note.id),
                    onOpen: () => onOpen(note),
                    onMove: subjects.isEmpty
                        ? null
                        : moving.contains(note.id)
                        ? null
                        : () => _pickSubject(context, note),
                    showMove: subjects.isNotEmpty,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxRow extends StatelessWidget {
  const _InboxRow({
    required this.note,
    required this.stacked,
    required this.moving,
    required this.onOpen,
    required this.onMove,
    required this.showMove,
  });

  final Note note;
  final bool stacked;
  final bool moving;
  final VoidCallback onOpen;
  final VoidCallback? onMove;
  final bool showMove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final updated = note.updatedAt;
    final open = AppCardTapArea(
      onTap: onOpen,
      semanticHint: l10n.academicInboxOpenHint,
      padding: const EdgeInsets.symmetric(
        horizontal: TokensSpacing.s,
        vertical: TokensSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            note.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.titleSmall,
          ),
          if (updated != null)
            Text(
              shortDate(updated),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
    // El lector oye a qué apunte se refiere cada «Mover»; mientras se mueve,
    // el botón lo dice.
    final move = Semantics(
      label: moving
          ? l10n.academicInboxMoving
          : l10n.academicInboxMoveSpoken(note.title),
      excludeSemantics: true,
      button: true,
      enabled: onMove != null,
      child: TextButton.icon(
        onPressed: onMove,
        icon: moving
            ? const SizedBox.square(
                dimension: TokensSize.iconXs,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.drive_file_move_outlined),
        label: Text(moving ? l10n.academicInboxMoving : l10n.academicInboxMove),
      ),
    );
    if (!showMove) return open;
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          open,
          Align(alignment: AlignmentDirectional.centerEnd, child: move),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: open),
        const SizedBox(width: TokensSpacing.xs),
        move,
      ],
    );
  }
}
