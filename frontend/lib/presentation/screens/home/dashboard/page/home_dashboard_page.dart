import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/home_banner_type.dart';
import '../../../../../domain/enums/home_event_kind.dart';
import '../../../../../domain/enums/usage_focus.dart';
import '../../../../../domain/models/home/home_dashboard.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../profile/legal/bloc/legal_acceptance_bloc.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../home_external_paths.dart';
import '../../widgets/active_challenges_section.dart';
import '../../widgets/agenda_section.dart';
import '../../widgets/birthday_card.dart';
import '../../widgets/home_header.dart';
import '../../widgets/home_skeleton.dart';
import '../../widgets/next_training_card.dart';
import '../../widgets/plan_week_bar.dart';
import '../../widgets/setup_checklist_card.dart';
import '../../widgets/smart_banner_card.dart';
import '../../widgets/state_section.dart';
import '../../widgets/today_hero_card.dart';
import '../bloc/home_dashboard_bloc.dart';

/// Pestaña Inicio: lo importante ahora (aviso), cómo estás (equilibrio), qué
/// toca hoy y, al lado, tus retos y tu semana. El resto vive en su pestaña.
/// Avisos que van arriba del todo, antes de «Tu día».
const _urgentBanners = {
  HomeBannerType.overdueDeadlines,
  HomeBannerType.physicalOverload,
  HomeBannerType.highFatigue,
};

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<SessionBloc>().account?.id ?? '';
    // El onboarding y los permisos esperan a que la política esté aceptada:
    // si no, se abrirían encima de la pantalla de aceptación (ADR 0034).
    final legalReady =
        context.read<LegalAcceptanceBloc>().state.status ==
        LegalGateStatus.accepted;
    return BlocProvider(
      create: (_) => getIt<HomeDashboardBloc>()
        ..add(HomeDashboardEvent.started(userId: legalReady ? userId : '')),
      child: BlocListener<LegalAcceptanceBloc, LegalAcceptanceState>(
        listenWhen: (a, b) =>
            a.status != LegalGateStatus.accepted &&
            b.status == LegalGateStatus.accepted,
        listener: (context, _) => context.read<HomeDashboardBloc>().add(
          HomeDashboardEvent.onboardingCheckRequested(userId: userId),
        ),
        child: const HomeDashboardView(),
      ),
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

  /// Resultado de «Hecho» o «Al próximo hueco» del aviso.
  void _showBannerNotice(BuildContext context, HomeBannerNotice notice) {
    final l10n = context.localizations;
    context.showSnack(switch (notice) {
      HomeBannerNoticeCompleted(:final xpDelta) =>
        xpDelta > 0
            ? l10n.plannerBlockCompletedXp(xpDelta)
            : l10n.plannerBlockCompleted,
      HomeBannerNoticeRescheduled(:final start) => l10n.plannerRescheduledTo(
        DateFormat.MMMEd().add_Hm().format(start),
      ),
      HomeBannerNoticeFailed(:final error) => errorMessage(context, error),
    });
  }

  /// Resultado de marcar o desmarcar desde la agenda, con «Deshacer», que
  /// pide lo contrario (y devuelve o recupera la misma XP en el servidor).
  void _showCompletionNotice(BuildContext context, HomeCompletionNotice notice) {
    final l10n = context.localizations;
    switch (notice) {
      case HomeCompletionNoticeDone(
        :final id,
        :final kind,
        :final completed,
        :final xpDelta,
      ):
        final xp = xpDelta.abs();
        final status = completed
            ? (xp > 0
                  ? l10n.plannerBlockCompletedXp(xp)
                  : l10n.plannerBlockCompleted)
            : (xp > 0
                  ? l10n.plannerBlockUncompletedXp(xp)
                  : l10n.plannerBlockUncompleted);
        // Se nombra lo marcado: el aviso se lee sin mirar la lista.
        final state = context.read<HomeDashboardBloc>().state;
        final event = [
          ...?state.dashboard?.todayEvents,
          ...state.upcoming,
        ].where((e) => e.id == id).firstOrNull;
        final title = event == null
            ? null
            : event.title.isEmpty
            ? eventTypeLabel(context, event.type)
            : readableEventTitle(event.title);
        final message = title == null
            ? status
            : l10n.homeCompletionNotice(title, status);
        final bloc = context.read<HomeDashboardBloc>();
        context.showActionSnack(
          message,
          duration: TokensDuration.undoWindow,
          actionLabel: l10n.commonUndo,
          onAction: () => bloc.add(
            HomeDashboardEvent.completionSet(
              id: id,
              kind: kind,
              completed: !completed,
            ),
          ),
        );
      case HomeCompletionNoticeFailed(:final error):
        context.showSnack(errorMessage(context, error));
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
              (current.permissionsIntroRequired &&
                  !previous.permissionsIntroRequired) ||
              (current.openSessionId != null &&
                  current.openSessionId != previous.openSessionId) ||
              (current.trainingError != null &&
                  current.trainingError != previous.trainingError) ||
              (current.bannerNotice != null &&
                  current.bannerNotice != previous.bannerNotice) ||
              (current.completionNotice != null &&
                  current.completionNotice != previous.completionNotice) ||
              (current.error != null &&
                  current.error != previous.error &&
                  current.dashboard != null),
          listener: (context, state) {
            final completionNotice = state.completionNotice;
            if (completionNotice != null) {
              context.read<HomeDashboardBloc>().add(
                const HomeDashboardEvent.completionNoticeHandled(),
              );
              _showCompletionNotice(context, completionNotice);
              return;
            }
            final bannerNotice = state.bannerNotice;
            if (bannerNotice != null) {
              context.read<HomeDashboardBloc>().add(
                const HomeDashboardEvent.bannerNoticeHandled(),
              );
              _showBannerNotice(context, bannerNotice);
              return;
            }
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
            if (state.permissionsIntroRequired) {
              context.read<HomeDashboardBloc>().add(
                const HomeDashboardEvent.permissionsIntroHandled(),
              );
              _navigate(context, HomeExternalPaths.permissionsIntro);
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
      onCommunity: () => onNavigate(HomeExternalPaths.community),
      onAdmin: () => onNavigate(HomeExternalPaths.admin),
      onProgress: () => onNavigate(HomeExternalPaths.progress),
    );
    // Solo lo que no puede esperar (entregas vencidas, sobrecarga, mucha
    // fatiga) va arriba del todo; el resto de avisos, aunque sean de aviso
    // (entregas próximas, poca energía…), no empuja «Tu día» y va debajo.
    final urgent = _urgentBanners.contains(dashboard.banner.type);
    final bloc = context.read<HomeDashboardBloc>();
    final banner = SmartBannerCard(
      banner: dashboard.banner,
      onAction: onNavigate,
      busy: state.bannerBusy,
      onRescheduleBlock: (id) =>
          bloc.add(HomeDashboardEvent.bannerBlockRescheduled(id)),
      onCompleteBlock: (id) =>
          bloc.add(HomeDashboardEvent.bannerBlockCompleted(id)),
    );
    // Columna principal: primero lo que hay que hacer (agenda de hoy y los
    // próximos días y el próximo entreno), que es lo que el estudiante busca al
    // abrir la app; después, en una tarjeta compacta, cómo está para hacerlo.
    void startTraining() => next == null
        ? onNavigate(HomeExternalPaths.newRoutine)
        : context.read<HomeDashboardBloc>().add(
            HomeDashboardEvent.trainingStarted(
              routineId: next.routineId,
              dayId: next.dayId,
            ),
          );
    // «Entrenar» de «Tu día» empieza el día de rutina del bloque que toca
    // ahora (lo que dice el calendario); sin enlace, el próximo de la rutina.
    void trainTodayBlock() {
      final event = TodayHeroCard.nextEvent(dashboard.todayEvents);
      final routineId = event?.routineId;
      final dayId = event?.routineDayId;
      if (routineId != null && dayId != null) {
        context.read<HomeDashboardBloc>().add(
          HomeDashboardEvent.trainingStarted(
            routineId: routineId,
            dayId: dayId,
          ),
        );
      } else {
        startTraining();
      }
    }

    // «Concentrarme» se liga al bloque que toca: sus fases cuentan para él y
    // para su asignatura.
    void focusOnNext() {
      final event = TodayHeroCard.nextEvent(dashboard.todayEvents);
      onNavigate(
        event == null
            ? HomeExternalPaths.pomodoro
            : HomeExternalPaths.pomodoroFor(
                blockId: event.id,
                title: event.title.isEmpty ? null : event.title,
              ),
      );
    }

    // «Tu día»: lo primero que se ve, con lo que toca ahora y su botón.
    final hero = TodayHeroCard(
      dashboard: dashboard,
      focus: focus,
      starting: state.startingTraining,
      completingIds: state.completingIds,
      onMarkDone: (event) => context.read<HomeDashboardBloc>().add(
        HomeDashboardEvent.completionSet(
          id: event.id,
          kind: event.kind,
          completed: true,
        ),
      ),
      onAction: (action) => switch (action) {
        TodayHeroAction.focus => focusOnNext(),
        TodayHeroAction.train => trainTodayBlock(),
        TodayHeroAction.openPlanner => onNavigate(HomeExternalPaths.planner),
      },
    );
    final setup = state.setup;
    final main = <Widget>[
      AgendaSection(
        events: dashboard.todayEvents,
        upcoming: state.upcoming,
        focus: focus,
        reviews: state.dueReviews,
        onOpenPlanner: () => onNavigate(HomeExternalPaths.planner),
        completingIds: state.completingIds,
        onSetCompleted: (event, completed) => context
            .read<HomeDashboardBloc>()
            .add(
              HomeDashboardEvent.completionSet(
                id: event.id,
                kind: event.kind,
                completed: completed,
              ),
            ),
        onStartTraining: (event) => context.read<HomeDashboardBloc>().add(
          HomeDashboardEvent.trainingStarted(
            routineId: event.routineId!,
            dayId: event.routineDayId!,
          ),
        ),
        onOpenEvent: (event) => onNavigate(
          event.kind == HomeEventKind.deadline
              ? HomeExternalPaths.deadline(event.id)
              : HomeExternalPaths.plannerAt(
                  event.start ?? DateTime.now(),
                  blockId: event.id,
                ),
        ),
        onOpenReview: (review) =>
            onNavigate(HomeExternalPaths.materialReview(review.id)),
        onReviewAll: () => onNavigate(
          HomeExternalPaths.materialReview(
            state.dueReviews.first.id,
            queue: [for (final r in state.dueReviews.skip(1)) r.id],
          ),
        ),
      ),
      if (focus.includesFitness)
        NextTrainingCard(
          day: next,
          checkInDone: dashboard.wellbeing.checkInDone,
          starting: state.startingTraining,
          // Igual que en Rutinas: empieza (o reanuda) la sesión directamente.
          onStart: startTraining,
          onOpenRoutine: next == null
              ? null
              : () => onNavigate(HomeExternalPaths.routine(next.routineId)),
          onCheckIn: () => onNavigate(HomeExternalPaths.checkIn),
          onRun: () => onNavigate(HomeExternalPaths.recordRun),
        ),
      if (setup != null && setup.visibleAt(DateTime.now()))
        SetupChecklistCard(
          setup: setup,
          onOpen: (task) => onNavigate(HomeExternalPaths.setupTask(task)),
          onLater: () => context.read<HomeDashboardBloc>().add(
            const HomeDashboardEvent.setupSnoozed(),
          ),
        ),
      // Un aviso informativo va después del próximo entreno: no lo tapa.
      if (!urgent) banner,
      // Sin «Concentrarme»: ya está en «Tu día» (una parada por destino).
      StateSection(
        cognitive: dashboard.cognitive,
        crossRegulation: dashboard.crossRegulation,
        wellbeing: dashboard.wellbeing,
        focus: focus,
        onOpenAnalytics: () => onNavigate(HomeExternalPaths.analytics),
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
          onOpenDay: (day) => onNavigate(HomeExternalPaths.plannerAt(day)),
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
            // Solo ese día y arriba: es lo primero que debe ver (ADR 0036).
            if (dashboard.greeting.birthday) ...[
              BirthdayCard(name: dashboard.greeting.firstName),
              _gap,
            ],
            if (urgent) ...[banner, _gap],
            hero,
            _gap,
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
