import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/usage_focus.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../../challenges/challenges_list/page/challenges_page.dart';
import '../../badges/page/badges_page.dart';
import '../../progress_routes.dart';
import '../../widgets/study_by_subject_card.dart';
import '../../widgets/study_week_card.dart';
import '../../widgets/analytics_summary.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/community_preview_card.dart';
import '../../widgets/level_card.dart';
import '../../widgets/next_badge_card.dart';
import '../../widgets/physical_load_card.dart';
import '../../widgets/streak_card.dart';
import '../bloc/progress_overview_bloc.dart';

/// Pestaña Progreso: «Resumen» (nivel, racha y cifras), «Retos» e
/// «Insignias». Aquí viven el XP, las rachas, las insignias y los retos
/// (vocabulario.md §4); el resto de la app no enseña cifras de XP. El apartado
/// llega con `?tab=` (avisos, Inicio, celebraciones).
class ProgressOverviewPage extends StatefulWidget {
  const ProgressOverviewPage({super.key, this.tab = ProgressTab.summary});

  final ProgressTab tab;

  @override
  State<ProgressOverviewPage> createState() => _ProgressOverviewPageState();
}

class _ProgressOverviewPageState extends State<ProgressOverviewPage>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: ProgressTab.values.length,
    vsync: this,
    initialIndex: widget.tab.index,
  );

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_syncLocation);
  }

  /// La dirección sigue al apartado elegido a mano: así un enlace posterior a
  /// ese mismo apartado (`go('/progress?tab=…')`) vuelve a llevar a él.
  void _syncLocation() {
    if (_tabs.indexIsChanging || !mounted) return;
    final tab = ProgressTab.values[_tabs.index];
    if (tab == widget.tab) return;
    context.go(switch (tab) {
      ProgressTab.summary => ProgressPaths.root,
      ProgressTab.challenges => ProgressPaths.challenges,
      ProgressTab.badges => ProgressPaths.badgesTab,
    });
  }

  @override
  void didUpdateWidget(ProgressOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Un enlace nuevo (`go('/progress?tab=…')`) cambia de apartado.
    if (widget.tab != oldWidget.tab) _show(widget.tab);
  }

  void _show(ProgressTab tab) => _tabs.animateTo(
    tab.index,
    duration: context.motion(TokensDuration.normal),
  );

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Scaffold(
      appBar: AppPageBar(
        title: Text(l10n.progressTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.progressTabSummary),
            Tab(text: l10n.challengesTitle),
            Tab(text: l10n.progressBadgesPageTitle),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          AppKeepAlive(
            child: BlocProvider(
              create: (_) =>
                  getIt<ProgressOverviewBloc>()
                    ..add(const ProgressOverviewEvent.started()),
              child: _ProgressOverviewView(
                onOpenBadges: () => _show(ProgressTab.badges),
              ),
            ),
          ),
          const AppKeepAlive(child: ChallengesPage()),
          const AppKeepAlive(child: BadgesPage()),
        ],
      ),
    );
  }
}

class _ProgressOverviewView extends StatefulWidget {
  const _ProgressOverviewView({required this.onOpenBadges});

  /// Lleva al apartado «Insignias» de la misma pestaña.
  final VoidCallback onOpenBadges;

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
    return BlocConsumer<ProgressOverviewBloc, ProgressOverviewState>(
      listenWhen: (previous, current) =>
          current is ProgressOverviewLoaded && previous != current,
      listener: (context, state) {
        if (state is ProgressOverviewLoaded) unawaited(_onLoaded(state));
      },
      builder: (context, state) {
        return switch (state) {
          ProgressOverviewLoading() => const _OverviewSkeleton(),
          ProgressOverviewFailure(:final error) => AppErrorView(
            error: error,
            onRetry: () => context.read<ProgressOverviewBloc>().add(
              const ProgressOverviewEvent.started(),
            ),
          ),
          ProgressOverviewLoaded(
            :final overview,
            :final today,
            :final todayError,
          ) =>
            _focusAware(
              context,
              (focus) => RefreshIndicator(
                onRefresh: _refresh,
                child: _Constrained(
                  children: [
                    LevelCard(account: overview.account),
                    StreakCard(streak: overview.streak),
                    // Carga cognitiva, carga física y energía de hoy: cifras
                    // técnicas que salieron de Inicio (ADR 0038).
                    if (today != null)
                      BalanceCard(
                        cognitive: today.cognitive,
                        crossRegulation: today.crossRegulation,
                        wellbeing: today.wellbeing,
                        focus: focus,
                        // Sin enlaces propios: el análisis y el Pomodoro ya se
                        // abren desde sus tarjetas (un camino por destino).
                      )
                    else if (todayError != null)
                      _BalanceError(
                        focus: focus,
                        error: todayError,
                        onRetry: () => context.read<ProgressOverviewBloc>().add(
                          const ProgressOverviewEvent.refreshed(),
                        ),
                      ),
                    // Las ganadas están en «Insignias»: aquí solo la siguiente.
                    if (overview.nextBadge case final next?)
                      NextBadgeCard(badge: next, onOpen: widget.onOpenBadges),
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
                    if (focus.includesAcademic)
                      StudyBySubjectCard(report: overview.studyBySubject),
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
        };
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

/// «Tu equilibrio» sin datos por un error: el título se conserva (la persona
/// sabe qué falta) y debajo el motivo con «Reintentar».
class _BalanceError extends StatelessWidget {
  const _BalanceError({
    required this.focus,
    required this.error,
    required this.onRetry,
  });

  /// Mismo título que la tarjeta con datos («Tu estado» con un solo enfoque).
  final UsageFocus focus;
  final AppError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppSectionHeader(
        title: focus == UsageFocus.both
            ? context.localizations.homeBalanceTitle
            : context.localizations.homeStateTitle,
      ),
      AppCard(
        child: AppErrorView(error: error, onRetry: onRetry),
      ),
    ],
  );
}
