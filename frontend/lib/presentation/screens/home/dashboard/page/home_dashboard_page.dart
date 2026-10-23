import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/usage_focus.dart';
import '../../../../../domain/models/home/home_dashboard.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../home_external_paths.dart';
import '../../widgets/active_challenges_section.dart';
import '../../widgets/agenda_section.dart';
import '../../widgets/home_header.dart';
import '../../widgets/home_skeleton.dart';
import '../../widgets/next_training_card.dart';
import '../../widgets/plan_week_bar.dart';
import '../../widgets/smart_banner_card.dart';
import '../../widgets/state_section.dart';
import '../bloc/home_dashboard_bloc.dart';

/// Pestaña Inicio: lo importante ahora (aviso), cómo estás (equilibrio), qué
/// toca hoy y, al lado, tus retos y tu semana. El resto vive en su pestaña.
class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<SessionBloc>().account?.id ?? '';
    return BlocProvider(
      create: (_) =>
          getIt<HomeDashboardBloc>()
            ..add(HomeDashboardEvent.started(userId: userId)),
      child: const HomeDashboardView(),
    );
  }
}

/// Vista del inicio (separada para poder probarla con un bloc simulado).
class HomeDashboardView extends StatelessWidget with ErrorsMessageMixin {
  const HomeDashboardView({super.key});

  /// Navega a otra pantalla. Lo que vive en otra pestaña se abre cambiando
  /// de pestaña; el resto se apila. No hace falta refrescar al volver: el
  /// inicio escucha los cambios de datos de toda la app.
  void _navigate(BuildContext context, String path) {
    if (HomeExternalPaths.isTabRoute(path)) {
      context.go(path);
    } else {
      unawaited(context.push<void>(path));
    }
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<HomeDashboardBloc>()
      ..add(const HomeDashboardEvent.refreshed());
    await bloc.stream.firstWhere(
      (s) => !s.refreshing && s.status != HomeDashboardStatus.loading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<HomeDashboardBloc, HomeDashboardState>(
          listenWhen: (previous, current) =>
              (current.onboardingRequired && !previous.onboardingRequired) ||
              (current.openSessionId != null &&
                  current.openSessionId != previous.openSessionId) ||
              (current.trainingError != null &&
                  current.trainingError != previous.trainingError) ||
              (current.error != null &&
                  current.error != previous.error &&
                  current.dashboard != null),
          listener: (context, state) {
            final sessionId = state.openSessionId;
            final trainingError = state.trainingError;
            if (sessionId != null || trainingError != null) {
              context.read<HomeDashboardBloc>().add(
                const HomeDashboardEvent.trainingHandled(),
              );
              if (sessionId != null) {
                _navigate(context, HomeExternalPaths.session(sessionId));
              } else {
                context.showSnack(errorMessage(context, trainingError!));
              }
              return;
            }
            if (state.onboardingRequired) {
              context.read<HomeDashboardBloc>().add(
                const HomeDashboardEvent.onboardingHandled(),
              );
              _navigate(context, HomeExternalPaths.onboarding);
              return;
            }
            final error = state.error;
            if (error != null) {
              context.showSnack(
                '${context.localizations.homeRefreshFailed} '
                '${errorMessage(context, error)}',
              );
            }
          },
          builder: (context, state) {
            final dashboard = state.dashboard;
            final Widget content;
            if (dashboard != null) {
              content = _HomeContent(
                dashboard: dashboard,
                state: state,
                onNavigate: (path) => _navigate(context, path),
              );
            } else if (state.status == HomeDashboardStatus.failure &&
                state.error != null) {
              content = Padding(
                padding: const EdgeInsets.only(top: TokensSpacing.xxl),
                child: AppErrorView(
                  error: state.error!,
                  onRetry: () => context.read<HomeDashboardBloc>().add(
                    const HomeDashboardEvent.refreshed(),
                  ),
                ),
              );
            } else {
              content = const HomeSkeleton();
            }
            return RefreshIndicator(
              onRefresh: () => _refresh(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(TokensSpacing.m),
                children: [AppContentWidth.wide(child: content)],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.dashboard,
    required this.state,
    required this.onNavigate,
  });

  final HomeDashboard dashboard;
  final HomeDashboardState state;
  final ValueChanged<String> onNavigate;

  static const _gap = SizedBox(height: TokensSpacing.l);

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select(
      (SessionBloc bloc) => bloc.account?.isAdmin ?? false,
    );
    final focus = context.select(
      (SessionBloc bloc) => bloc.account?.usageFocus ?? UsageFocus.both,
    );
    final next = dashboard.nextTrainingDay;
    final header = HomeHeader(
      greeting: dashboard.greeting,
      unreadNotifications: state.unreadNotifications,
      isAdmin: isAdmin,
      onProfile: () => onNavigate(HomeExternalPaths.profile),
      onNotifications: () => onNavigate(HomeExternalPaths.notifications),
      onAdmin: () => onNavigate(HomeExternalPaths.admin),
      onProgress: () => onNavigate(HomeExternalPaths.progress),
    );
    // Un aviso urgente va arriba del todo; uno informativo (racha, equilibrio)
    // no debe empujar la agenda y va debajo de ella.
    final urgent =
        SmartBannerContent.of(context, dashboard.banner).tone ==
        SmartBannerTone.warning;
    final banner = SmartBannerCard(
      banner: dashboard.banner,
      onAction: onNavigate,
    );
    // Columna principal: primero lo que hay que hacer (agenda de hoy y los
    // próximos días y el próximo entreno), que es lo que el estudiante busca al
    // abrir la app; después, en una tarjeta compacta, cómo está para hacerlo.
    final main = <Widget>[
      AgendaSection(
        events: dashboard.todayEvents,
        upcoming: state.upcoming,
        focus: focus,
        reviews: state.dueReviews,
        onOpenPlanner: () => onNavigate(HomeExternalPaths.planner),
        onOpenReview: (review) =>
            onNavigate(HomeExternalPaths.materialReview(review.id)),
      ),
      if (!urgent) banner,
      if (focus.includesFitness)
        NextTrainingCard(
          day: next,
          checkInDone: dashboard.wellbeing.checkInDone,
          starting: state.startingTraining,
          // Igual que en Rutinas: empieza (o reanuda) la sesión directamente.
          onStart: () => next == null
              ? onNavigate(HomeExternalPaths.newRoutine)
              : context.read<HomeDashboardBloc>().add(
                  HomeDashboardEvent.trainingStarted(
                    routineId: next.routineId,
                    dayId: next.dayId,
                  ),
                ),
          onOpenRoutine: next == null
              ? null
              : () => onNavigate(HomeExternalPaths.routine(next.routineId)),
          onCheckIn: () => onNavigate(HomeExternalPaths.checkIn),
        ),
      StateSection(
        cognitive: dashboard.cognitive,
        crossRegulation: dashboard.crossRegulation,
        wellbeing: dashboard.wellbeing,
        focus: focus,
        onOpenAnalytics: () => onNavigate(HomeExternalPaths.analytics),
        onStudyNow: () => onNavigate(HomeExternalPaths.pomodoro),
      ),
    ];
    // Columna secundaria: metas y semana. Las cifras detalladas están en la
    // analítica y los atajos en su pestaña, para no repetir lo que ya hay.
    final side = <Widget>[
      ActiveChallengesSection(
        challenges: dashboard.activeChallenges,
        onOpen: (challenge) =>
            onNavigate(HomeExternalPaths.challenge(challenge.id)),
        onSeeAll: () => onNavigate(HomeExternalPaths.challenges),
        onCreate: () => onNavigate(HomeExternalPaths.newChallenge),
      ),
      if (dashboard.planWeek.isNotEmpty)
        PlanWeekBar(
          days: dashboard.planWeek,
          week: dashboard.week,
          focus: focus,
          onOpenPlanner: () => onNavigate(HomeExternalPaths.planner),
        ),
    ];

    List<Widget> spaced(List<Widget> items) => [
      for (final (i, item) in items.indexed) ...[if (i > 0) _gap, item],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= TokensLayout.twoColumnBreakpoint;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: TokensSpacing.m),
            if (urgent) ...[banner, _gap],
            // Un grupo de foco por columna: el Tabulador recorre la izquierda
            // entera y luego la derecha, en vez de saltar de una a otra según
            // la altura de cada tarjeta.
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppFocusGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: spaced(main),
                      ),
                    ),
                  ),
                  const SizedBox(width: TokensSpacing.l),
                  Expanded(
                    flex: 2,
                    child: AppFocusGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: spaced(side),
                      ),
                    ),
                  ),
                ],
              )
            else
              ...spaced([...main, ...side]),
            const SizedBox(height: TokensSpacing.l),
          ],
        );
      },
    );
  }
}
