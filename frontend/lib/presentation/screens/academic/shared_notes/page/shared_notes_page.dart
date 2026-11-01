import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/shared_notes_scope.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_widgets.dart';
import '../../widgets/shared_note_card.dart';
import '../bloc/shared_notes_bloc.dart';

/// Apuntes que comparten otros usuarios, en dos pestañas: «Amigos» (lo que
/// me llega por ser su amigo) y «Comunidad» (lo que cualquiera puede ver).
/// Con [authorId], solo los de ese autor y sin pestañas.
class SharedNotesPage extends StatelessWidget {
  const SharedNotesPage({super.key, this.authorId});

  final String? authorId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final author = authorId;
    if (author != null) {
      return Scaffold(
        appBar: AppPageBar(title: Text(l10n.academicSharedNotesTitle)),
        body: _SharedNotesList(scope: SharedNotesScope.all, authorId: author),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppPageBar(
          title: Text(l10n.academicSharedNotesTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.academicSharedTabFriends),
              Tab(text: l10n.academicSharedTabCommunity),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SharedNotesList(scope: SharedNotesScope.friends),
            _SharedNotesList(scope: SharedNotesScope.community),
          ],
        ),
      ),
    );
  }
}

/// Una lista con su propio bloc; se conserva al cambiar de pestaña.
class _SharedNotesList extends StatefulWidget {
  const _SharedNotesList({required this.scope, this.authorId});

  final SharedNotesScope scope;
  final String? authorId;

  @override
  State<_SharedNotesList> createState() => _SharedNotesListState();
}

class _SharedNotesListState extends State<_SharedNotesList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider(
      create: (_) => getIt<SharedNotesBloc>()
        ..add(
          SharedNotesEvent.started(
            scope: widget.scope,
            authorId: widget.authorId,
          ),
        ),
      child: const _SharedNotesView(),
    );
  }
}

class _SharedNotesView extends StatelessWidget with ErrorsMessageMixin {
  const _SharedNotesView();

  Widget _empty(BuildContext context, SharedNotesState state) {
    final l10n = context.localizations;
    if (state.authorId != null) {
      return AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: l10n.academicSharedAuthorEmptyTitle,
        message: l10n.academicSharedAuthorEmptyMessage,
      );
    }
    return switch (state.scope) {
      // La comunidad no depende de tener amigos: se invita a compartir uno.
      SharedNotesScope.community => AppEmptyState(
        icon: Icons.public_rounded,
        title: l10n.academicSharedCommunityEmptyTitle,
        message: l10n.academicSharedCommunityEmptyMessage,
        action: AppSecondaryButton(
          label: l10n.academicSharedShareNote,
          icon: const Icon(Icons.note_add_outlined),
          onPressed: () => context.push(AcademicPaths.newNote()),
        ),
      ),
      _ => AppEmptyState(
        icon: Icons.group_outlined,
        title: l10n.academicSharedFriendsEmptyTitle,
        message: l10n.academicSharedFriendsEmptyMessage,
        action: AppPrimaryButton(
          label: l10n.academicSharedFindFriends,
          icon: Icons.person_search_rounded,
          onPressed: () => context.push(AcademicExternalPaths.friends),
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SharedNotesBloc>();
    return BlocConsumer<SharedNotesBloc, SharedNotesState>(
      // Con la lista ya cargada, un fallo al refrescar se avisa sin taparla.
      listenWhen: (a, b) =>
          b.error != null && a.error != b.error && b.items.isNotEmpty,
      listener: (context, state) =>
          context.showSnack(errorMessage(context, state.error!)),
      builder: (context, state) {
        if (state.loading) {
          return const AcademicBody(
            child: AppSkeletonList(count: 4, height: _cardHeight),
          );
        }
        if (state.error != null && state.items.isEmpty) {
          return AppErrorView(
            error: state.error!,
            onRetry: () => bloc.add(const SharedNotesEvent.refreshed()),
          );
        }
        Future<void> refresh() async {
          bloc.add(const SharedNotesEvent.refreshed());
          await bloc.stream.firstWhere((s) => !s.refreshing);
        }

        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: refresh,
            child: AcademicBody(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [_empty(context, state)],
              ),
            ),
          );
        }
        final moreError = state.loadMoreError;
        final footer = state.hasMore || moreError != null;
        return RefreshIndicator(
          onRefresh: refresh,
          child: AcademicBody(
            child: NotificationListener<ScrollNotification>(
              // Tras un fallo no se reintenta solo al desplazarse: lo decide
              // la persona con «Reintentar».
              onNotification: (n) => moreError != null
                  ? false
                  : onScrollNearEnd(
                      n,
                      () => bloc.add(const SharedNotesEvent.moreRequested()),
                    ),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(TokensSpacing.m),
                itemCount: state.items.length + (footer ? 1 : 0),
                separatorBuilder: (_, _) =>
                    const SizedBox(height: TokensSpacing.s),
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    return moreError != null
                        ? LoadMoreError(
                            error: moreError,
                            onRetry: () => bloc.add(
                              const SharedNotesEvent.moreRequested(),
                            ),
                          )
                        : const LoadMoreIndicator();
                  }
                  final note = state.items[index];
                  return SharedNoteCard(
                    note: note,
                    onOpen: () async {
                      await context.push<void>(
                        AcademicPaths.sharedNote(note.id),
                      );
                      bloc.add(const SharedNotesEvent.refreshed());
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Altura aproximada de una tarjeta, para que el esqueleto no salte al cargar.
const double _cardHeight = TokensSize.heroStat + TokensSize.thumbnailS;
