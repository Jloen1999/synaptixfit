import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/academic/study_material.dart';
import '../../../../extensions/context_extensions.dart';
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

class _AcademicHomeView extends StatelessWidget {
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
            icon: const Icon(Icons.people_alt_outlined),
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
      body: BlocBuilder<AcademicHomeBloc, AcademicHomeState>(
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
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 260,
                              mainAxisExtent: 148,
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
  const _DueReviews({required this.due, required this.onOpen});

  final List<StudyMaterial> due;
  final ValueChanged<StudyMaterial> onOpen;

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
                Text(
                  l10n.academicDueReviews(due.length),
                  style: context.textStyles.titleMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          SizedBox(
            height: context.scaled(104),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.m),
              scrollDirection: Axis.horizontal,
              itemCount: due.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: TokensSpacing.s),
              itemBuilder: (context, index) {
                final material = due[index];
                return SizedBox(
                  width: 220,
                  child: AppCard(
                    onTap: () => onOpen(material),
                    color: context.colors.tertiaryContainer.withValues(
                      alpha: 0.5,
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
