import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/home_banner_type.dart';
import '../../../../../domain/enums/guide_id.dart';
import '../../../../../domain/enums/home_event_kind.dart';
import '../../../../../domain/enums/usage_focus.dart';
import '../../../../../domain/models/home/home_dashboard.dart';
import '../../../../../domain/models/home/today_next.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../profile/legal/bloc/legal_acceptance_bloc.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../../shell/widgets/first_time_guide.dart';
import '../../home_external_paths.dart';
import '../../widgets/active_challenges_section.dart';
import '../../widgets/agenda_section.dart';
import '../../widgets/birthday_card.dart';
import '../../widgets/home_header.dart';
import '../../widgets/home_skeleton.dart';
import '../../widgets/missed_events_card.dart';
import '../../widgets/next_training_card.dart';
import '../../widgets/plan_week_bar.dart';
import '../../widgets/setup_checklist_card.dart';
import '../../widgets/smart_banner_card.dart';
import '../../widgets/today_hero_card.dart';
import '../../widgets/unfinished_session_card.dart';
import '../../../training/widgets/training_dialogs.dart';
import '../bloc/home_dashboard_bloc.dart';

/// Avisos que van arriba del todo, antes de «Tu día».
const _urgentBanners = {
  HomeBannerType.overdueDeadlines,
  HomeBannerType.physicalOverload,
  HomeBannerType.highFatigue,
};

/// Pestaña Inicio, al grano (vocabulario.md §4, ADR 0038 y 0059): arriba lo
/// que quedó a medias (la sesión sin terminar y lo de ayer sin marcar, cada
/// uno con sus botones), «Tu día» compacto (barra y filas que dicen cuál es
/// cada cosa), la agenda, el próximo entreno si no es hoy, los retos y tu
/// semana. Sin XP ni cifras técnicas (están en Progreso) y un solo camino al
/// calendario: su pestaña. Lo de configurar la app va al final.
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
      create: (_) =>
          getIt<HomeDashboardBloc>()
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
class HomeDashboardView extends StatefulWidget {
  const HomeDashboardView({super.key});

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView>
    with ErrorsMessageMixin {
  final _guide = _HomeGuideKeys();

  /// Título de la tarjeta «Sin terminar»: recibe el foco si «Empezar» no pudo.
  final _unfinishedFocus = FocusNode(debugLabel: 'home-unfinished');

  @override
  void dispose() {
    _unfinishedFocus.dispose();
    super.dispose();
  }

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

  /// Resultado de las tarjetas de arriba (sesión a medias y lo de ayer): lo
  /// que se borra lleva «Deshacer»; lo que se mueve dice dónde queda y «Ver».
  void _showActionNotice(BuildContext context, HomeActionNotice notice) {
    final l10n = context.localizations;
    final bloc = context.read<HomeDashboardBloc>();
    void undoable(String message, String key) => context.showUndoSnack(
      message,
      onUndo: () {
        if (!bloc.isClosed) bloc.add(HomeDashboardEvent.deferredUndone(key));
      },
      // Si Inicio ya se cerró, el bloc lo hizo al cerrarse.
      onCommit: () {
        if (!bloc.isClosed) {
          bloc.add(HomeDashboardEvent.deferredCommitted(key));
        }
      },
    );
    switch (notice) {
      case HomeActionNoticeSessionSaved():
        context.showSnack(l10n.homeUnfinishedSaved);
      case HomeActionNoticeSessionDiscarded(:final key):
        undoable(l10n.trainingSessionDiscarded, key);
      case HomeActionNoticeLogged():
        context.showSnack(l10n.homeMissedLogged);
      case HomeActionNoticeMoved(:final start):
        context.showActionSnack(
          l10n.homeMissedMoved(
            DateFormat.MMMMEEEEd(l10n.localeName).format(start),
            DateFormat.Hm(l10n.localeName).format(start),
          ),
          actionLabel: l10n.commonView,
          onAction: () =>
              _navigate(context, HomeExternalPaths.plannerAt(start)),
        );
      case HomeActionNoticeRemoved(:final key):
        undoable(l10n.plannerBlockDeleted, key);
      case HomeActionNoticeFailed(:final error):
        context.showSnack(errorMessage(context, error));
    }
  }

  /// Resultado de marcar o desmarcar desde la agenda, con «Deshacer», que
  /// pide lo contrario (y devuelve o recupera la misma XP en el servidor).
  void _showCompletionNotice(
    BuildContext context,
    HomeCompletionNotice notice,
  ) {
    final l10n = context.localizations;
    switch (notice) {
      case HomeCompletionNoticeDone(:final id, :final kind, :final completed):
        final status = completed
            ? l10n.plannerBlockCompleted
            : l10n.plannerBlockUncompleted;
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
        final controller = context.showActionSnack(
          message,
          duration: TokensDuration.undoWindow,
          actionLabel: l10n.commonUndo,
          onAction: () => bloc.add(
            HomeDashboardEvent.completionSet(
              id: id,
              kind: kind,
              completed: !completed,
              undo: true,
            ),
          ),
        );
        // Ctrl+Z vale mientras se ve el aviso, como su «Deshacer».
        unawaited(
          controller.closed.then((_) {
            if (!bloc.isClosed) bloc.add(HomeDashboardEvent.undoExpired(id));
          }),
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
    // Ctrl+Z (Cmd+Z) deshace lo último marcado, como «Deshacer» del aviso.
    // La guía, con Inicio ya cargado (ADR 0049); montada desde el principio
    // para saber si se llegó desde un aviso.
    return FirstTimeGuide(
      guide: GuideId.home,
      ready: context.select<HomeDashboardBloc, bool>(
        (b) => b.state.dashboard != null,
      ),
      steps: _guide.steps,
      child: AppUndoShortcut(
        onUndo: () {
          final bloc = context.read<HomeDashboardBloc>();
          if (bloc.state.lastUndoable == null) return;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          bloc.add(const HomeDashboardEvent.undoRequested());
        },
        child: Scaffold(
          body: SafeArea(
            child: BlocConsumer<HomeDashboardBloc, HomeDashboardState>(
              listenWhen: (previous, current) =>
                  (current.onboardingRequired &&
                      !previous.onboardingRequired) ||
                  (current.permissionsIntroRequired &&
                      !previous.permissionsIntroRequired) ||
                  (current.openSessionId != null &&
                      current.openSessionId != previous.openSessionId) ||
                  (current.trainingError != null &&
                      current.trainingError != previous.trainingError) ||
                  (current.actionNotice != null &&
                      current.actionNotice != previous.actionNotice) ||
                  (current.showUnfinished && !previous.showUnfinished) ||
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
                final actionNotice = state.actionNotice;
                if (actionNotice != null) {
                  context.read<HomeDashboardBloc>().add(
                    const HomeDashboardEvent.actionNoticeHandled(),
                  );
                  _showActionNotice(context, actionNotice);
                  return;
                }
                // «Empezar» no pudo por una sesión a medias: en vez de un
                // aviso sin salida, se lleva a su tarjeta (ADR 0059).
                if (state.showUnfinished) {
                  context.read<HomeDashboardBloc>().add(
                    const HomeDashboardEvent.trainingHandled(),
                  );
                  context.showSnack(context.localizations.homeUnfinishedFirst);
                  AppFocusAnchor.focusSoon(_unfinishedFocus);
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
                    guide: _guide,
                    unfinishedFocus: _unfinishedFocus,
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
        ),
      ),
    );
  }
}

/// Lo que señala la guía la primera vez (ADR 0049 y 0059): «Tu día», la
/// agenda, «Tu semana» y el icono de Comunidad. Un paso sin su parte en
/// pantalla (p. ej. sin semana planificada) no sale.
class _HomeGuideKeys {
  final day = GlobalKey(debugLabel: 'guide-home-day');
  final agenda = GlobalKey(debugLabel: 'guide-home-agenda');
  final week = GlobalKey(debugLabel: 'guide-home-week');
  final community = GlobalKey(debugLabel: 'guide-home-community');

  List<AppGuideStep> steps(BuildContext context) {
    final l10n = context.localizations;
    return [
      AppGuideStep(
        target: day,
        title: l10n.guideHomeDayTitle,
        body: l10n.guideHomeDayBody,
      ),
      AppGuideStep(
        target: agenda,
        title: l10n.guideHomeAgendaTitle,
        body: l10n.guideHomeAgendaBody,
      ),
      AppGuideStep(
        target: week,
        title: l10n.guideHomeWeekTitle,
        body: l10n.guideHomeWeekBody,
      ),
      AppGuideStep(
        target: community,
        title: l10n.guideHomeCommunityTitle,
        body: l10n.guideHomeCommunityBody,
      ),
    ];
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({
    required this.dashboard,
    required this.state,
    required this.onNavigate,
    required this.guide,
    required this.unfinishedFocus,
  });

  final HomeDashboard dashboard;
  final HomeDashboardState state;
  final ValueChanged<String> onNavigate;
  final _HomeGuideKeys guide;
  final FocusNode unfinishedFocus;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  static const _gap = SizedBox(height: TokensSpacing.l);

  /// Título de «Tu semana» (o de la agenda, si no hay semana): recibe el foco
  /// al ocultar «Termina de preparar tu app» con «Ahora no» (WCAG 2.4.3).
  final _afterSetupFocus = FocusNode(debugLabel: 'home-after-setup');

  /// Título de la agenda cuando «Tu semana» se ve (si no, es
  /// [_afterSetupFocus]): «y 2 más» de «Tu día» lleva aquí.
  final _agendaFocus = FocusNode(debugLabel: 'home-agenda');

  HomeDashboard get dashboard => widget.dashboard;
  HomeDashboardState get state => widget.state;
  ValueChanged<String> get onNavigate => widget.onNavigate;

  @override
  void dispose() {
    _afterSetupFocus.dispose();
    _agendaFocus.dispose();
    super.dispose();
  }

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
      pendingFriendRequests: dashboard.pendingFriendRequests,
      communityKey: widget.guide.community,
      onProfile: () => onNavigate(HomeExternalPaths.profile),
      onNotifications: () => onNavigate(HomeExternalPaths.notifications),
      // Tú › Comunidad, con las solicitudes recibidas arriba (ADR 0061).
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
    );
    final unfinished = dashboard.unfinishedSession;
    final unfinishedShown =
        unfinished != null &&
        !state.deferredKeys.contains(
          HomeDeferred.session(unfinished.sessionId),
        );
    final missed = [
      for (final e in dashboard.missedEvents)
        if (!e.completed &&
            !state.deferredKeys.contains(HomeDeferred.block(e.id)))
          e,
    ];
    // Columna principal: lo que hay que hacer (agenda de hoy y de los próximos
    // días y el próximo entreno), que es lo que se busca al abrir la app.
    void startTraining() => next == null
        ? onNavigate(HomeExternalPaths.newRoutine)
        : context.read<HomeDashboardBloc>().add(
            HomeDashboardEvent.trainingStarted(
              routineId: next.routineId,
              dayId: next.dayId,
            ),
          );
    // «Concentrarme» se liga al evento de la fila: sus fases cuentan para él
    // y para su asignatura.
    void focusOnNext() {
      final event = dashboard.spotlight;
      onNavigate(
        event == null
            ? HomeExternalPaths.pomodoro
            : HomeExternalPaths.pomodoroFor(
                blockId: event.id,
                title: event.title.isEmpty ? null : event.title,
              ),
      );
    }

    // «Tu día»: lo primero que se ve, con lo que toca hoy en filas.
    final nextDeadline = dashboard.nextDeadline;
    // Sin «Tu semana», el título de la agenda es también el destino de «Ahora
    // no» (un nodo de foco por widget).
    final agendaFocus = dashboard.planWeek.isEmpty
        ? _afterSetupFocus
        : _agendaFocus;
    final hero = TodayHeroCard(
      key: widget.guide.day,
      dashboard: dashboard,
      focus: focus,
      starting: state.startingTraining,
      completingIds: state.completingIds,
      primaryElsewhere: unfinishedShown,
      blockedBy: unfinishedShown ? unfinished : null,
      onStartTraining: startTraining,
      onOpenTraining: next == null
          ? null
          : () => onNavigate(HomeExternalPaths.routine(next.routineId)),
      onOpenEvent: (event) => onNavigate(
        HomeExternalPaths.plannerAt(
          event.start ?? DateTime.now(),
          blockId: event.id,
        ),
      ),
      onOpenDeadline: nextDeadline == null
          ? null
          : () => onNavigate(HomeExternalPaths.deadline(nextDeadline.id)),
      onMarkDone: (event) => _setCompleted(context, event, completed: true),
      // Lleva el foco (y la vista) al título de la agenda de hoy.
      onOpenAgenda: () => AppFocusAnchor.focusSoon(agendaFocus),
      onAction: (action) {
        switch (action) {
          case TodayAction.focus:
            focusOnNext();
          // Lo marca `onMarkDone` (devuelve el foco al título).
          case TodayAction.markDone:
            break;
          case TodayAction.addEvent:
            onNavigate(HomeExternalPaths.addEvent());
        }
      },
    );
    // El entreno de hoy ya está en «Tu día»: «Próximo entreno» solo si no es
    // hoy (ADR 0059).
    final showNextTraining =
        focus.includesFitness && dashboard.trainingToday == null;
    final setup = state.setup;
    final main = <Widget>[
      AgendaSection(
        key: widget.guide.agenda,
        // Sin «Tu semana», «Ahora no» devuelve el foco aquí (WCAG 2.4.3).
        headerFocusNode: agendaFocus,
        events: dashboard.todayEvents,
        upcoming: state.upcoming,
        focus: focus,
        reviews: state.dueReviews,
        completingIds: state.completingIds,
        // Con una sesión a medias, «Empezar» espera, como en «Tu día».
        startEnabled: !unfinishedShown,
        onSetCompleted: (event, completed) =>
            _setCompleted(context, event, completed: completed),
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
      if (showNextTraining)
        NextTrainingCard(
          day: next,
          checkInDone: dashboard.wellbeing.checkInDone,
          starting: state.startingTraining,
          // Igual que en Rutinas: empieza (o reanuda) la sesión directamente.
          onStart: startTraining,
          // Relleno solo si ni «Sin terminar» ni «Tu día» llevan ya el
          // destacado (un solo relleno por pantalla, ADR 0059 y 0065).
          startPrimary:
              !unfinishedShown &&
              !TodayHeroCard.hasPrimaryAction(
                dashboard: dashboard,
                focus: focus,
              ),
          onOpenRoutine: next == null
              ? null
              : () => onNavigate(HomeExternalPaths.routine(next.routineId)),
          onCheckIn: () => onNavigate(HomeExternalPaths.checkIn),
        ),
      // Un aviso informativo va después del próximo entreno: no lo tapa. Si
      // es el de «¿Qué tal estás hoy?» y la tarjeta del entreno ya lo ofrece,
      // no se repite (un camino por destino, vocabulario §4).
      if (!urgent &&
          !(showNextTraining &&
              dashboard.banner.type == HomeBannerType.checkInPending))
        banner,
    ];
    // Columna secundaria: retos en marcha (solo si hay) y la semana. Las
    // cifras de carga, energía y XP viven en Progreso.
    final side = <Widget>[
      if (dashboard.activeChallenges.isNotEmpty)
        ActiveChallengesSection(
          challenges: dashboard.activeChallenges,
          onOpen: (challenge) =>
              onNavigate(HomeExternalPaths.challenge(challenge.id)),
          onSeeAll: () => onNavigate(HomeExternalPaths.challenges),
        ),
      if (dashboard.planWeek.isNotEmpty)
        PlanWeekBar(
          key: widget.guide.week,
          days: dashboard.planWeek,
          week: dashboard.week,
          summary: dashboard.weekSummary,
          focus: focus,
          headerFocusNode: _afterSetupFocus,
          onOpenDay: (day) => onNavigate(HomeExternalPaths.plannerAt(day)),
        ),
    ];
    // Terminar de preparar la app va al final: no compite con lo de hoy.
    final setupCard = setup != null && setup.visibleAt(DateTime.now())
        ? SetupChecklistCard(
            setup: setup,
            onOpen: (task) => onNavigate(HomeExternalPaths.setupTask(task)),
            onLater: () {
              context.read<HomeDashboardBloc>().add(
                const HomeDashboardEvent.setupSnoozed(),
              );
              // Dice cuándo y dónde vuelve (vocabulario.md).
              context.showSnack(context.localizations.homeSetupSnoozedWhere);
              AppFocusAnchor.focusSoon(_afterSetupFocus);
            },
          )
        : null;

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
            // Lo que quedó a medias va arriba, con sus botones (ADR 0059).
            if (unfinishedShown) ...[
              UnfinishedSessionCard(
                session: unfinished,
                titleFocus: widget.unfinishedFocus,
                onOpen: () =>
                    onNavigate(HomeExternalPaths.session(unfinished.sessionId)),
                busy: state.actingIds.contains(unfinished.sessionId),
                onSave: (figures) => bloc.add(
                  HomeDashboardEvent.unfinishedSaved(
                    sessionId: unfinished.sessionId,
                    minutes: figures.minutes,
                    rpe: figures.rpe,
                  ),
                ),
                onDiscard: () => bloc.add(
                  HomeDashboardEvent.unfinishedDiscarded(unfinished.sessionId),
                ),
              ),
              _gap,
            ],
            if (missed.isNotEmpty) ...[
              MissedEventsCard(
                events: missed,
                onOpen: (event) => onNavigate(
                  HomeExternalPaths.plannerAt(
                    event.start ?? DateTime.now(),
                    blockId: event.id,
                  ),
                ),
                busyIds: {...state.actingIds, ...state.completingIds},
                onDone: (event) => _missedDone(context, event),
                onMove: (event, start, end) => bloc.add(
                  HomeDashboardEvent.missedMoved(
                    eventId: event.id,
                    start: start,
                    end: end,
                  ),
                ),
                onRemove: (event) =>
                    bloc.add(HomeDashboardEvent.missedRemoved(event.id)),
              ),
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
            if (setupCard != null) ...[_gap, setupCard],
            const SizedBox(height: TokensSpacing.l),
          ],
        );
      },
    );
  }
}

/// «Lo hice» de un evento de ayer: un día de rutina se apunta como sesión de
/// ese día (minutos y esfuerzo, como en Gimnasio; marcarlo a mano no avanza
/// la rutina); el resto se marca como en la agenda.
Future<void> _missedDone(BuildContext context, HomeTodayEvent event) async {
  final start = event.start;
  if (!event.isRoutineDay || start == null) {
    return _setCompleted(context, event, completed: true);
  }
  final bloc = context.read<HomeDashboardBloc>();
  final figures = await showSessionFiguresDialog(
    context,
    confirmLabel: context.localizations.commonSave,
    subtitle: event.title.isEmpty ? null : readableEventTitle(event.title),
    initialMinutes: event.end == null
        ? 60
        : event.end!.difference(start).inMinutes,
  );
  if (figures == null) return;
  bloc.add(
    HomeDashboardEvent.missedLogged(
      eventId: event.id,
      routineId: event.routineId!,
      dayId: event.routineDayId!,
      date: DateTime(start.year, start.month, start.day),
      minutes: figures.minutes,
      rpe: figures.rpe,
    ),
  );
}

/// Marca o desmarca un evento de hoy con los mismos casos de uso que el
/// planificador; si es un deporte que registra carga física (lo dice el
/// servidor), antes pregunta el esfuerzo con el mismo diálogo que él, así
/// marcar lo mismo desde Inicio o desde el calendario tiene el mismo efecto.
Future<void> _setCompleted(
  BuildContext context,
  HomeTodayEvent event, {
  required bool completed,
}) async {
  final bloc = context.read<HomeDashboardBloc>();
  int? effort;
  if (completed && event.tracksPhysicalLoad) {
    effort = await showEffortDialog(
      context,
      confirmLabel: context.localizations.plannerSportDoneAction,
      subtitle: event.title.isEmpty ? null : readableEventTitle(event.title),
    );
    if (effort == null) return;
  }
  bloc.add(
    HomeDashboardEvent.completionSet(
      id: event.id,
      kind: event.kind,
      completed: completed,
      effort: effort,
    ),
  );
}
