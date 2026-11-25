import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/guide_id.dart';
import '../../../../../domain/models/academic/note.dart';
import '../../../../../domain/models/academic/subject.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../shell/widgets/first_time_guide.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../../widgets/subject_card.dart';
import '../bloc/academic_home_bloc.dart';

/// Pestaña Académico (ADR 0057): buscador, los repasos de hoy y las
/// asignaturas, cada una con lo que importa de un vistazo.
class AcademicHomePage extends StatelessWidget {
  const AcademicHomePage({super.key, this.showArchived = false});

  /// Abre con el filtro «Archivadas» puesto (`/academic?view=archived`).
  final bool showArchived;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<AcademicHomeBloc>()
          ..add(AcademicHomeEvent.started(archived: showArchived)),
    child: const _AcademicHomeView(),
  );
}

class _AcademicHomeView extends StatefulWidget {
  const _AcademicHomeView();

  @override
  State<_AcademicHomeView> createState() => _AcademicHomeViewState();
}

class _AcademicHomeViewState extends State<_AcademicHomeView>
    with ErrorsMessageMixin {
  /// Partes que señala la guía la primera vez (ADR 0049).
  final _addKey = GlobalKey(debugLabel: 'guide-academic-add');
  final _reviewsKey = GlobalKey(debugLabel: 'guide-academic-reviews');
  final _searchKey = GlobalKey(debugLabel: 'guide-academic-search');

  List<AppGuideStep> _guideSteps(BuildContext context) {
    final l10n = context.localizations;
    return [
      // «Añadir» también lleva a crear tests y tarjetas con IA: un solo paso.
      AppGuideStep(
        target: _addKey,
        title: l10n.guideAcademicAddTitle,
        body: l10n.guideAcademicAddBody,
      ),
      AppGuideStep(
        target: _reviewsKey,
        title: l10n.guideAcademicReviewsTitle,
        body: l10n.guideAcademicReviewsBody,
      ),
      AppGuideStep(
        target: _searchKey,
        title: l10n.guideAcademicSearchTitle,
        body: l10n.guideAcademicSearchBody,
      ),
    ];
  }

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
                  AppIcons.importGuide,
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
                  AppIcons.quickNote,
                  l10n.academicQuickNote,
                  l10n.academicQuickNoteHint,
                  AcademicPaths.newNote(quick: true),
                ),
                option(
                  Icons.photo_camera_outlined,
                  l10n.academicScanEntryLong,
                  l10n.academicScanEntryHint,
                  AcademicPaths.scanNote(),
                ),
                option(
                  AppIcons.proposal,
                  l10n.academicGenerateTitle,
                  l10n.academicGenerateHint,
                  AcademicPaths.generate(),
                ),
                // Antes era un botón de la lista; copiar apuntes de clase es
                // otra forma de tenerlos.
                option(
                  AppIcons.sharedNotes,
                  l10n.academicSharedNotesTitle,
                  l10n.academicSharedNotesHint,
                  AcademicPaths.sharedNotes,
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
    final ready = context.select<AcademicHomeBloc, bool>((b) {
      final s = b.state;
      return s.subjects.isNotEmpty || (!s.loading && s.error == null);
    });
    return FirstTimeGuide(
      guide: GuideId.academic,
      ready: ready,
      steps: _guideSteps,
      child: Scaffold(
        appBar: AppPageBar(
          title: Text(l10n.tabAcademic),
          actions: [
            // Con el texto grande no cabe en la barra: solo el icono.
            Padding(
              key: _addKey,
              padding: const EdgeInsetsDirectional.only(end: TokensSpacing.s),
              child: context.largeText
                  ? IconButton(
                      tooltip: l10n.academicAddSpoken,
                      icon: const Icon(AppIcons.add),
                      onPressed: () => _showAddSheet(context),
                    )
                  : Semantics(
                      container: true,
                      button: true,
                      excludeSemantics: true,
                      label: l10n.academicAddSpoken,
                      onTap: () => _showAddSheet(context),
                      child: AppSecondaryButton(
                        label: l10n.academicAdd,
                        icon: const Icon(AppIcons.add),
                        onPressed: () => _showAddSheet(context),
                      ),
                    ),
            ),
          ],
        ),
        body: BlocConsumer<AcademicHomeBloc, AcademicHomeState>(
          listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
          listener: (context, state) {
            final notice = state.notice!;
            context.read<AcademicHomeBloc>().add(
              const AcademicHomeEvent.noticeHandled(),
            );
            switch (notice) {
              // Dice dónde queda el apunte y lleva allí.
              case AcademicHomeNoticeNoteMoved(
                :final subjectName,
                :final subjectId,
              ):
                context.showActionSnack(
                  l10n.academicInboxMoved(subjectName),
                  actionLabel: l10n.commonView,
                  onAction: () =>
                      _open(context, AcademicPaths.subjectNotes(subjectId)),
                );
              case AcademicHomeNoticeFailed(:final error):
                context.showSnack(errorMessage(context, error));
            }
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
                    // El buscador, lo primero: encuentra cualquier asignatura,
                    // apunte, archivo o entrega sin bajar por las listas.
                    SliverToBoxAdapter(
                      child: _SearchEntry(
                        key: _searchKey,
                        onTap: () => context.push(AcademicPaths.search),
                      ),
                    ),
                    // Lo primero que se hace al abrir: repasar lo de hoy.
                    if (state.due.isNotEmpty && !state.showArchived)
                      SliverToBoxAdapter(
                        child: _ReviewsBanner(
                          key: _reviewsKey,
                          count: state.due.length,
                          onReview: () => _open(
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
                        child: _SubjectsHeader(
                          archived: state.showArchived,
                          onChanged: (archived) =>
                              context.read<AcademicHomeBloc>().add(
                                AcademicHomeEvent.archivedToggled(
                                  archived: archived,
                                ),
                              ),
                        ),
                      ),
                    ),
                    if (state.loading)
                      const SliverToBoxAdapter(
                        child: LinearProgressIndicator(),
                      ),
                    if (state.subjects.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: AppEmptyState(
                          icon: state.showArchived
                              ? AppIcons.archive
                              : AppIcons.subject,
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
                                  icon: AppIcons.importGuide,
                                  onPressed: () => _open(
                                    context,
                                    AcademicPaths.importGuide(),
                                  ),
                                ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensSpacing.m,
                          0,
                          TokensSpacing.m,
                          TokensSpacing.xl,
                        ),
                        sliver: SliverList.separated(
                          itemCount: state.subjects.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: TokensSpacing.s),
                          itemBuilder: (context, index) {
                            final subject = state.subjects[index];
                            return SubjectCard(
                              subject: subject,
                              onTap: () => _open(
                                context,
                                AcademicPaths.subject(subject.id),
                              ),
                              onImportGuide: () => _open(
                                context,
                                AcademicPaths.importGuide(
                                  subjectId: subject.id,
                                ),
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
      ),
    );
  }
}

/// «Tus asignaturas» (cabecera) y el filtro Activas / Archivadas; con el texto
/// grande, el filtro baja debajo (en fila se salía de la pantalla).
class _SubjectsHeader extends StatelessWidget {
  const _SubjectsHeader({required this.archived, required this.onChanged});

  final bool archived;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final title = Semantics(
      header: true,
      child: Text(
        l10n.academicSubjectsTitle,
        style: context.textStyles.titleMedium,
      ),
    );
    final filter = SegmentedButton<bool>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(value: false, label: Text(l10n.academicFilterActive)),
        ButtonSegment(value: true, label: Text(l10n.academicFilterArchived)),
      ],
      selected: {archived},
      onSelectionChanged: (s) => onChanged(s.first),
    );
    if (context.largeText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: TokensSpacing.s),
          AppSegmentedChoice<bool>(
            label: l10n.academicSubjectsTitle,
            values: const [false, true],
            selected: archived,
            labelOf: (v) =>
                v ? l10n.academicFilterArchived : l10n.academicFilterActive,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: title),
        filter,
      ],
    );
  }
}

/// «7 repasos para hoy · Repasar»: un solo toque repasa todos seguidos.
class _ReviewsBanner extends StatelessWidget {
  const _ReviewsBanner({
    super.key,
    required this.count,
    required this.onReview,
  });

  final int count;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final onTint = context.colors.onTertiaryContainer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        TokensSpacing.s,
        TokensSpacing.m,
        0,
      ),
      child: AppCard(
        color: context.colors.tertiaryContainer,
        onTap: onReview,
        child: Semantics(
          excludeSemantics: true,
          label:
              '${l10n.academicReviewsForToday(count)}. ${l10n.academicReviewNow}',
          child: Row(
            children: [
              Icon(AppIcons.review, color: onTint),
              const SizedBox(width: TokensSpacing.sm),
              Expanded(
                child: Text(
                  l10n.academicReviewsForToday(count),
                  style: context.textStyles.titleSmall?.copyWith(
                    color: onTint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: TokensSpacing.s),
              Text(
                l10n.academicReviewNow,
                style: context.textStyles.labelLarge?.copyWith(
                  color: onTint,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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
                    leading: const Icon(AppIcons.subject),
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
      container: true,
      label: moving
          ? l10n.academicInboxMoving
          : l10n.academicInboxMoveSpoken(note.title),
      excludeSemantics: true,
      button: true,
      enabled: onMove != null,
      // El hijo queda excluido: sin esto el lector anuncia un botón que no
      // se puede pulsar.
      onTap: onMove,
      child: TextButton.icon(
        onPressed: onMove,
        icon: moving
            ? const SizedBox.square(
                dimension: TokensSize.iconXs,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(AppIcons.move),
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

/// Entrada al buscador de Académico: parece un campo de búsqueda y abre la
/// pantalla del buscador (ADR 0036).
class _SearchEntry extends StatelessWidget {
  const _SearchEntry({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        TokensSpacing.s,
        TokensSpacing.m,
        TokensSpacing.xs,
      ),
      child: Semantics(
        button: true,
        child: AppFocusOutline(
          borderRadius: BorderRadius.circular(TokensRadius.l),
          child: Material(
            color: context.colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(TokensRadius.l),
            child: InkWell(
              borderRadius: BorderRadius.circular(TokensRadius.l),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: TokensLayout.minTouchTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TokensSpacing.m,
                    vertical: TokensSpacing.s,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.search,
                        color: context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: TokensSpacing.s),
                      Expanded(
                        child: Text(
                          l10n.academicSearchLabel,
                          style: context.textStyles.bodyLarge?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
