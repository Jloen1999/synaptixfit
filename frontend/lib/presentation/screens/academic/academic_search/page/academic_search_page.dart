import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/academic/academic_search.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../bloc/academic_search_bloc.dart';

/// Buscador único de Académico (ADR 0036): asignaturas, apuntes, archivos y
/// entregas o exámenes, agrupados por tipo y con lo buscado resaltado. Es una
/// pantalla completa: cada resultado abre su pantalla completa con `push`
/// (nunca una ruta de dentro de una pestaña), así «atrás» vuelve aquí.
class AcademicSearchPage extends StatelessWidget {
  const AcademicSearchPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<AcademicSearchBloc>(),
    child: const _AcademicSearchView(),
  );
}

class _AcademicSearchView extends StatelessWidget {
  const _AcademicSearchView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<AcademicSearchBloc>();
    return Scaffold(
      appBar: AppPageBar.reading(title: Text(l10n.academicSearchTitle)),
      body: AcademicSearchBody(
        searchField: Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensSpacing.m,
            TokensSpacing.s,
            TokensSpacing.m,
            TokensSpacing.s,
          ),
          child: AppSearchField(
            label: l10n.academicSearchLabel,
            autofocus: true,
            debounce: AppSearchField.serverDebounce,
            onChanged: (q) => bloc.add(AcademicSearchEvent.queryChanged(q)),
          ),
        ),
      ),
    );
  }
}

/// Campo y resultados; separado de la página para probarlo sin red.
class AcademicSearchBody extends StatelessWidget {
  const AcademicSearchBody({super.key, required this.searchField});

  final Widget searchField;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: TokensLayout.readingMaxWidth,
        ),
        child: Column(
          children: [
            searchField,
            Expanded(
              child: BlocBuilder<AcademicSearchBloc, AcademicSearchState>(
                builder: (context, state) => switch (state.status) {
                  AcademicSearchStatus.idle => _Hint(
                    text: l10n.academicSearchHint,
                  ),
                  AcademicSearchStatus.loading =>
                    state.result == null
                        ? const AppSkeletonList(count: 5, height: 56)
                        : _Results(state: state),
                  AcademicSearchStatus.failure => AppErrorView(
                    error: state.error!,
                    onRetry: () => context.read<AcademicSearchBloc>().add(
                      const AcademicSearchEvent.retried(),
                    ),
                  ),
                  AcademicSearchStatus.ready =>
                    state.result == null || state.result!.isEmpty
                        ? SingleChildScrollView(
                            child: AppSearchEmpty(
                              query: state.query,
                              actionLabel: l10n.academicSearchCreateNote(
                                state.query,
                              ),
                              onAction: () => context.push(
                                AcademicPaths.newNote(title: state.query),
                              ),
                            ),
                          )
                        : _Results(state: state),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TokensSpacing.l),
      child: Column(
        children: [
          Icon(
            Icons.manage_search_rounded,
            size: TokensSize.iconL,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(height: TokensSpacing.s),
          Text(
            text,
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.state});

  final AcademicSearchState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final groups = state.result?.groups ?? const <AcademicSearchGroup>[];
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        0,
        TokensSpacing.m,
        TokensSpacing.xl,
      ),
      children: [
        if (state.status == AcademicSearchStatus.loading)
          const LinearProgressIndicator(),
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.only(top: TokensSpacing.xs),
            child: Text(
              l10n.commonSearchResultsCount(
                groups.fold(0, (n, g) => n + g.hits.length),
              ),
              style: context.textStyles.labelMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
        for (final group in groups) ...[
          AppSectionHeader(title: _groupTitle(context, group.kind)),
          for (final hit in group.hits)
            _HitTile(kind: group.kind, hit: hit, query: state.query),
          if (group.more)
            Padding(
              padding: const EdgeInsets.only(
                left: TokensSpacing.m,
                bottom: TokensSpacing.s,
              ),
              child: Text(
                l10n.academicSearchMore,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: TokensSpacing.s),
        ],
      ],
    );
  }

  static String _groupTitle(BuildContext context, AcademicSearchKind kind) {
    final l10n = context.localizations;
    return switch (kind) {
      AcademicSearchKind.subject => l10n.academicSearchGroupSubjects,
      AcademicSearchKind.note => l10n.academicSearchGroupNotes,
      AcademicSearchKind.file => l10n.academicSearchGroupFiles,
      AcademicSearchKind.deadline => l10n.academicSearchGroupDeadlines,
    };
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({required this.kind, required this.hit, required this.query});

  final AcademicSearchKind kind;
  final AcademicSearchHit hit;
  final String query;

  String _path() => switch (kind) {
    AcademicSearchKind.subject => AcademicPaths.subject(hit.id),
    AcademicSearchKind.note => AcademicPaths.note(hit.id),
    AcademicSearchKind.file => AcademicPaths.file(hit.id),
    AcademicSearchKind.deadline => AcademicPaths.deadline(hit.id),
  };

  IconData get _icon => switch (kind) {
    AcademicSearchKind.subject => Icons.school_outlined,
    AcademicSearchKind.note => Icons.description_outlined,
    AcademicSearchKind.file => Icons.attach_file_rounded,
    AcademicSearchKind.deadline =>
      hit.exam ? Icons.quiz_outlined : Icons.assignment_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final due = hit.at;
    final subtitle = [
      if (hit.context != null && hit.context!.isNotEmpty) hit.context!,
      if (due != null) AppDueDates.text(context, due, DateTime.now()),
    ].join(' · ');
    final soon = due != null && AppDueDates.isSoon(due, DateTime.now());
    return AppFocusOutline(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: TokensSpacing.s),
        leading: Icon(_icon, color: context.colors.primary),
        title: AppHighlightedText(
          text: hit.title.isEmpty ? l10n.academicSearchUntitled : hit.title,
          query: query,
          style: context.textStyles.titleSmall,
        ),
        subtitle: subtitle.isEmpty
            ? null
            : AppHighlightedText(
                text: subtitle,
                query: query,
                maxLines: 1,
                style: context.textStyles.bodySmall?.copyWith(
                  color: soon
                      ? context.palette.warning
                      : context.colors.onSurfaceVariant,
                ),
              ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push(_path()),
      ),
    );
  }
}
