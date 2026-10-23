import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/usage_focus.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../progress_routes.dart';
import '../../widgets/study_week_card.dart';
import '../../widgets/analytics_summary.dart';
import '../../widgets/community_preview_card.dart';
import '../../widgets/earned_badges_preview.dart';
import '../../widgets/level_card.dart';
import '../../widgets/physical_load_card.dart';
import '../../widgets/streak_card.dart';
import '../bloc/progress_overview_bloc.dart';

/// Pestaña Progreso.
class ProgressOverviewPage extends StatelessWidget {
  const ProgressOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ProgressOverviewBloc>()
            ..add(const ProgressOverviewEvent.started()),
      child: const _ProgressOverviewView(),
    );
  }
}

class _ProgressOverviewView extends StatefulWidget {
  const _ProgressOverviewView();

  @override
  State<_ProgressOverviewView> createState() => _ProgressOverviewViewState();
}

class _ProgressOverviewViewState extends State<_ProgressOverviewView>
    with ErrorsMessageMixin {
  Future<void> _refresh() {
    final bloc = context.read<ProgressOverviewBloc>()
      ..add(const ProgressOverviewEvent.refreshed());
    return bloc.stream.firstWhere(
      (s) => s is! ProgressOverviewLoaded || !s.refreshing,
    );
  }

  /// Abre otra pantalla del módulo y recarga al volver (pueden cambiar datos).
  Future<void> _open(String path) async {
    await context.push(path);
    if (mounted) unawaited(_refresh());
  }

  Future<void> _onLoaded(ProgressOverviewLoaded state) async {
    final account = state.overview.account;
    final session = context.read<SessionBloc>();
    final current = session.state;
    if (current is SessionAuthenticatedState && current.account != account) {
      session.add(SessionEvent.accountUpdated(account));
    }
    final error = state.refreshError;
    if (error != null) context.showSnack(errorMessage(context, error));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<ProgressOverviewBloc, ProgressOverviewState>(
      listenWhen: (previous, current) =>
          current is ProgressOverviewLoaded && previous != current,
      listener: (context, state) {
        if (state is ProgressOverviewLoaded) unawaited(_onLoaded(state));
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppPageBar(title: Text(l10n.progressTitle)),
          body: switch (state) {
            ProgressOverviewLoading() => const _OverviewSkeleton(),
            ProgressOverviewFailure(:final error) => AppErrorView(
              error: error,
              onRetry: () => context.read<ProgressOverviewBloc>().add(
                const ProgressOverviewEvent.started(),
              ),
            ),
            ProgressOverviewLoaded(:final overview) => _focusAware(
              context,
              (focus) => RefreshIndicator(
                onRefresh: _refresh,
                child: _Constrained(
                  children: [
                    LevelCard(account: overview.account),
                    StreakCard(streak: overview.streak),
                    EarnedBadgesPreview(
                      badges: overview.earnedBadges,
                      onOpen: () => _open(ProgressPaths.badges),
                    ),
                    // Cifras de estudio: solo si la persona estudia.
                    if (focus.includesAcademic)
                      StudyWeekCard(
                        week: overview.studyWeek,
                        onFocus: () =>
                            context.push(ProgressExternalPaths.pomodoro),
                        // Los repasos pendientes están en la pestaña Académico.
                        onReview: () =>
                            context.go(ProgressExternalPaths.academic),
                        onRetry: () => context.read<ProgressOverviewBloc>().add(
                          const ProgressOverviewEvent.refreshed(),
                        ),
                      ),
                    // Cifras de entrenamiento: solo si la persona hace deporte.
                    if (focus.includesFitness) ...[
                      WeeklySummaryCard(
                        weekly: overview.weekly,
                        onOpen: () => _open(ProgressPaths.analytics),
                      ),
                      PhysicalLoadCard(load: overview.physicalLoad),
                    ],
                    CommunityPreviewCard(
                      posts: overview.communityPosts,
                      onOpenWall: () =>
                          context.push(ProgressExternalPaths.socialWall),
                      onOpenPost: (post) => context.push(
                        ProgressExternalPaths.socialPost(post.id),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          },
        );
      },
    );
  }
}

/// Construye con el enfoque de uso de la sesión (estudios, deporte o ambos).
Widget _focusAware(BuildContext context, Widget Function(UsageFocus) build) =>
    build(
      context.select(
        (SessionBloc bloc) => bloc.account?.usageFocus ?? UsageFocus.both,
      ),
    );

/// Lista centrada con ancho máximo para web y tablet.
class _Constrained extends StatelessWidget {
  const _Constrained({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(TokensSpacing.m),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: TokensSpacing.m),
      itemBuilder: (context, index) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: TokensLayout.contentMaxWidth,
          ),
          child: children[index],
        ),
      ),
    );
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppSkeletonGroup(
      child: _Constrained(
        children: [
          AppSkeleton(height: 148),
          AppSkeleton(height: 200),
          AppSkeleton(height: 160),
          AppSkeleton(height: 120),
          AppSkeleton(height: 160),
        ],
      ),
    );
  }
}
