import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/guide_id.dart';
import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/models/training/recommendation.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../shell/widgets/first_time_guide.dart';
import '../../quick_check_in/page/quick_check_in_card.dart';
import '../../training_routes.dart';
import '../../widgets/continue_session_target.dart';
import '../../widgets/open_session_card.dart';
import '../../widgets/recommendation_card.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_effect_handler.dart';
import '../../widgets/training_labels.dart';
import '../../widgets/training_quick_actions.dart';
import '../../widgets/training_section_bar.dart';
import '../bloc/training_home_bloc.dart';
import 'training_week_strip.dart';

/// Apartado «Gimnasio» de la pestaña Entreno (rutinas, sesiones y registro).
class TrainingHomePage extends StatelessWidget {
  const TrainingHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<TrainingHomeBloc>()..add(const TrainingHomeEvent.started()),
      child: const _TrainingHomeView(),
    );
  }
}

class _TrainingHomeView extends StatefulWidget {
  const _TrainingHomeView();

  /// Abre una pantalla y recarga al volver (los datos pueden haber cambiado).
  static Future<void> open(BuildContext context, String location) async {
    final bloc = context.read<TrainingHomeBloc>();
    await context.push(location);
    if (!bloc.isClosed) bloc.add(const TrainingHomeEvent.refreshed());
  }

  @override
  State<_TrainingHomeView> createState() => _TrainingHomeViewState();
}

class _TrainingHomeViewState extends State<_TrainingHomeView> {
  final _guide = _GymGuideKeys();

  static Future<void> open(BuildContext context, String location) =>
      _TrainingHomeView.open(context, location);

  Future<void> _newRoutine(BuildContext context) async {
    final l10n = context.localizations;
    final mode = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFocusOutline(
              child: ListTile(
                leading: Icon(
                  Icons.view_list_rounded,
                  color: context.colors.secondary,
                ),
                title: Text(l10n.trainingTemplatesEntry),
                subtitle: Text(l10n.trainingTemplatesEntryHint),
                onTap: () => Navigator.of(context).pop(TrainingPaths.templates),
              ),
            ),
            AppFocusOutline(
              child: ListTile(
                leading: Icon(
                  AppIcons.proposal,
                  color: context.colors.tertiary,
                ),
                title: Text(l10n.trainingNewRoutineAi),
                subtitle: Text(l10n.trainingNewRoutineAiHint),
                onTap: () => Navigator.of(context).pop(TrainingPaths.modeAi),
              ),
            ),
            AppFocusOutline(
              child: ListTile(
                leading: Icon(
                  Icons.edit_note_rounded,
                  color: context.colors.secondary,
                ),
                title: Text(l10n.trainingNewRoutineManual),
                subtitle: Text(l10n.trainingNewRoutineManualHint),
                onTap: () =>
                    Navigator.of(context).pop(TrainingPaths.modeManual),
              ),
            ),
            const SizedBox(height: TokensSpacing.m),
          ],
        ),
      ),
    );
    if (mode != null && context.mounted) {
      await open(
        context,
        mode == TrainingPaths.templates
            ? TrainingPaths.templates
            : TrainingPaths.newRoutine(mode: mode),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<TrainingHomeBloc, TrainingHomeState>(
      listenWhen: (p, c) => c.effect != null && p.effect != c.effect,
      listener: (context, state) {
        // El aviso puede cerrarse con la pantalla ya cerrada: se guarda el
        // bloc y solo se le habla si sigue abierto.
        final bloc = context.read<TrainingHomeBloc>();
        void send(TrainingHomeEvent event) {
          if (!bloc.isClosed) bloc.add(event);
        }

        const TrainingEffectHandler().handle(
          context,
          state.effect!,
          onUnskipDay: (routineId, dayId) => send(
            TrainingHomeEvent.dayUnskipped(routineId: routineId, dayId: dayId),
          ),
          onRestoreRecommendation: (r) =>
              send(TrainingHomeEvent.recommendationRestored(r)),
          onConfirmDiscard: (id) =>
              send(TrainingHomeEvent.recommendationDiscardConfirmed(id)),
        );
      },
      builder: (context, state) {
        // La guía, con Gimnasio ya cargado (ADR 0049).
        _guide.empty = state.routines.isEmpty;
        return FirstTimeGuide(
          guide: GuideId.gym,
          ready: state.status == HomeStatus.ready,
          steps: _guide.steps,
          child: Scaffold(
            appBar: AppPageBar(
              title: Text(l10n.tabTraining),
              bottom: const TrainingSectionBar(current: TrainingSection.gym),
            ),
            body: switch (state.status) {
              HomeStatus.loading => const AppSkeletonList(
                height: TokensSize.skeletonCard,
              ),
              HomeStatus.failure => AppErrorView(
                error: state.error!,
                onRetry: () => context.read<TrainingHomeBloc>().add(
                  const TrainingHomeEvent.started(),
                ),
              ),
              HomeStatus.ready => RefreshIndicator(
                onRefresh: () async {
                  final bloc = context.read<TrainingHomeBloc>()
                    ..add(const TrainingHomeEvent.refreshed());
                  await bloc.stream.firstWhere((s) => !s.refreshing);
                },
                child: _HomeContent(
                  guide: _guide,
                  state: state,
                  onNewRoutine: () => _newRoutine(context),
                ),
              ),
            },
          ),
        );
      },
    );
  }
}

/// Partes de Gimnasio que señala la guía la primera vez (ADR 0049): el
/// próximo entreno, «Mis rutinas» y las plantillas. Van por clave: si
/// Gimnasio se reordena, cada clave se mueve con su parte.
class _GymGuideKeys {
  final start = GlobalKey(debugLabel: 'guide-gym-start');
  final routines = GlobalKey(debugLabel: 'guide-gym-routines');
  final templates = GlobalKey(debugLabel: 'guide-gym-templates');

  /// Sin rutinas aún, cada paso dice lo que hay de verdad (no «Continuar» ni
  /// «Nueva rutina», que todavía no salen).
  bool empty = false;

  List<AppGuideStep> steps(BuildContext context) {
    final l10n = context.localizations;
    return [
      AppGuideStep(
        target: start,
        title: empty ? l10n.guideGymStartEmptyTitle : l10n.guideGymStartTitle,
        body: empty ? l10n.guideGymStartEmptyBody : l10n.guideGymStartBody,
      ),
      AppGuideStep(
        target: routines,
        title: l10n.guideGymRoutinesTitle,
        body: empty
            ? l10n.guideGymRoutinesEmptyBody
            : l10n.guideGymRoutinesBody,
      ),
      AppGuideStep(
        target: templates,
        title: l10n.guideGymTemplatesTitle,
        body: l10n.guideGymTemplatesBody,
      ),
    ];
  }
}

/// Lo que se ve en Gimnasio, de arriba abajo: el próximo entreno, «¿Qué tal
/// estás hoy?» plegado, tus rutinas (con «Nueva rutina» en su cabecera, no
/// flotando sobre los botones) y, plegadas, las sugerencias (ADR 0039). La
/// guía la primera vez señala sus partes por clave (ADR 0049): si Gimnasio se
/// reordena, basta con mover cada clave con su parte.
class _HomeContent extends StatefulWidget {
  const _HomeContent({
    required this.state,
    required this.onNewRoutine,
    required this.guide,
  });

  final TrainingHomeState state;
  final VoidCallback onNewRoutine;
  final _GymGuideKeys guide;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  TrainingHomeState get state => widget.state;
  VoidCallback get onNewRoutine => widget.onNewRoutine;
  _GymGuideKeys get _guide => widget.guide;

  /// «Más»: lo que se usa de vez en cuando, fuera de la fila de atajos. Lleva
  /// siempre Historial y Ejercicios: en el móvil no están en la fila.
  Future<void> _showMore(BuildContext context) async {
    final l10n = context.localizations;
    final path = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TokensSpacing.l,
                0,
                TokensSpacing.l,
                TokensSpacing.s,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.trainingMoreTitle,
                  style: context.textStyles.titleLarge,
                ),
              ),
            ),
            for (final (icon, label, path) in [
              (
                AppIcons.history,
                l10n.trainingHistoryTitle,
                TrainingPaths.history,
              ),
              (
                AppIcons.search,
                l10n.trainingQuickExercises,
                TrainingPaths.exercises,
              ),
              (
                AppIcons.calendar,
                l10n.trainingWeeklyPlanTitle,
                TrainingPaths.weeklyPlan,
              ),
              (
                Icons.groups_rounded,
                l10n.trainingCommunityTitle,
                TrainingPaths.community,
              ),
              (
                Icons.handshake_rounded,
                l10n.togetherTrainWithFriends,
                TrainingPaths.together,
              ),
            ])
              AppFocusOutline(
                child: ListTile(
                  leading: Icon(icon, color: context.colors.secondary),
                  title: Text(label),
                  onTap: () => Navigator.of(context).pop(path),
                ),
              ),
            const SizedBox(height: TokensSpacing.m),
          ],
        ),
      ),
    );
    if (path != null && context.mounted) {
      await _TrainingHomeView.open(context, path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<TrainingHomeBloc>();
    // Ciclo terminado: no queda día que hacer y no hay otra rutina en curso.
    final finished = state.routines.finishedCycle(
      hasPendingDay: state.pendingDay != null,
    );
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        TokensSpacing.s,
        TokensSpacing.m,
        TokensSpacing.xxl,
      ),
      children: [
        TrainingContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ContinueTargetSync(
                dayId: state.pendingDay?.dayStatus == ProgressStatus.inProgress
                    ? state.pendingDay?.dayId
                    : null,
              ),
              for (final stale in state.staleSessions) ...[
                OpenSessionCard(
                  open: stale,
                  busy: state.working,
                  onDiscard: () => bloc.add(
                    TrainingHomeEvent.staleDiscarded(stale.session.id),
                  ),
                  onFinish: (figures) => bloc.add(
                    TrainingHomeEvent.staleFinished(
                      stale.session.id,
                      minutes: figures.minutes,
                      rpe: figures.rpe,
                    ),
                  ),
                ),
                const SizedBox(height: TokensSpacing.m),
              ],
              if (finished != null) ...[
                _CycleDoneCard(
                  routine: finished,
                  busy: state.working,
                  onRestart: () =>
                      bloc.add(TrainingHomeEvent.cycleRestarted(finished.id)),
                  onNextWithAi: () => _TrainingHomeView.open(
                    context,
                    TrainingPaths.newRoutine(),
                  ),
                ),
                const SizedBox(height: TokensSpacing.m),
              ],
              // Con el ciclo terminado, su tarjeta ya dice qué hacer.
              if (finished == null)
                _TodayCard(
                  key: _guide.start,
                  hasRoutines: state.routines.isNotEmpty,
                  onTemplates: () =>
                      _TrainingHomeView.open(context, TrainingPaths.templates),
                  pendingDay: state.pendingDay,
                  starting: state.startingSession,
                  busy: state.working,
                  onStart: (day) => bloc.add(
                    TrainingHomeEvent.sessionStarted(
                      routineId: day.routineId,
                      dayId: day.dayId,
                    ),
                  ),
                  onOpenRoutine: (id) => _TrainingHomeView.open(
                    context,
                    TrainingPaths.routine(id),
                  ),
                ),
              const SizedBox(height: TokensSpacing.s),
              // Lo que más se usa, a un toque y sin bajar (ADR 0055): «Nueva
              // rutina» primero; Ejercicios e Historial solo si caben los seis
              // en una fila (si no, están en «Más»).
              TrainingQuickActions(
                actions: [
                  TrainingQuickAction(
                    icon: AppIcons.add,
                    label: l10n.trainingNewRoutine,
                    onTap: onNewRoutine,
                  ),
                  TrainingQuickAction(
                    icon: AppIcons.freeSession,
                    label: l10n.trainingFreeSession,
                    onTap: state.startingSession || state.working
                        ? null
                        : () => bloc.add(
                            const TrainingHomeEvent.sessionStarted(),
                          ),
                  ),
                  TrainingQuickAction(
                    key: _guide.templates,
                    icon: Icons.view_list_rounded,
                    label: l10n.trainingQuickTemplates,
                    onTap: () => _TrainingHomeView.open(
                      context,
                      TrainingPaths.templates,
                    ),
                  ),
                  TrainingQuickAction(
                    icon: AppIcons.search,
                    label: l10n.trainingQuickExercises,
                    wideOnly: true,
                    onTap: () => _TrainingHomeView.open(
                      context,
                      TrainingPaths.exercises,
                    ),
                  ),
                  TrainingQuickAction(
                    icon: AppIcons.history,
                    label: l10n.trainingHistoryTitle,
                    wideOnly: true,
                    onTap: () =>
                        _TrainingHomeView.open(context, TrainingPaths.history),
                  ),
                  TrainingQuickAction(
                    icon: AppIcons.moreActions,
                    label: l10n.trainingQuickMore,
                    onTap: () => _showMore(context),
                  ),
                ],
              ),
              if (state.week case final week?) ...[
                const SizedBox(height: TokensSpacing.s),
                TrainingWeekStrip(
                  week: week,
                  onOpenSession: (id) => _TrainingHomeView.open(
                    context,
                    TrainingPaths.sessionDetail(id),
                  ),
                  onOpenPlanned: switch (state.pendingDay) {
                    final day? => () => _TrainingHomeView.open(
                      context,
                      TrainingPaths.routine(day.routineId),
                    ),
                    null => null,
                  },
                ),
              ],
              const SizedBox(height: TokensSpacing.s),
              // Tres toques y el porqué de la adaptación de hoy (ADR 0033),
              // plegado en una línea hasta que se abre. Los partidos y otras
              // actividades se apuntan en Correr (ADR 0039).
              const QuickCheckInCard(),
              const SizedBox(height: TokensSpacing.l),
              AppSectionHeader(
                // Sin rutinas, la guía señala la tarjeta con los botones.
                key: state.routines.isEmpty ? null : _guide.routines,
                title: l10n.trainingMyRoutines,
              ),
              if (state.routines.isEmpty)
                AppCard(
                  key: _guide.routines,
                  child: AppEmptyState.compact(
                    icon: Icons.fitness_center_rounded,
                    title: l10n.trainingCreateOwnRoutine,
                    message: l10n.trainingNoRoutinesMessage,
                    // Las otras formas de empezar: la plantilla ya está arriba,
                    // en «Hoy toca», y es el único botón destacado.
                    action: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: TokensSpacing.s,
                      runSpacing: TokensSpacing.s,
                      children: [
                        AppSecondaryButton(
                          label: l10n.trainingNewRoutineAi,
                          icon: const Icon(AppIcons.proposal),
                          onPressed: () => _TrainingHomeView.open(
                            context,
                            TrainingPaths.newRoutine(),
                          ),
                        ),
                        AppSecondaryButton(
                          label: l10n.trainingNewRoutineManual,
                          icon: const Icon(Icons.edit_note_rounded),
                          onPressed: () => _TrainingHomeView.open(
                            context,
                            TrainingPaths.newRoutine(
                              mode: TrainingPaths.modeManual,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _RoutinesCarousel(
                  routines: state.routines,
                  nextDay: state.pendingDay,
                  onOpen: (id) => _TrainingHomeView.open(
                    context,
                    TrainingPaths.routine(id),
                  ),
                  onNew: onNewRoutine,
                ),
              if (state.recommendations.isNotEmpty) ...[
                const SizedBox(height: TokensSpacing.l),
                _Recommendations(
                  recommendations: state.recommendations,
                  busyIds: state.busyIds,
                  onApply: (id) =>
                      bloc.add(TrainingHomeEvent.recommendationApplied(id)),
                  onDiscard: (id) =>
                      bloc.add(TrainingHomeEvent.recommendationDiscarded(id)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// «Hoy toca» (ADR 0055): la foto, qué día es, cuánto dura y «Empezar». Nada
/// más: el avance del ciclo y «Saltar este día» están en el detalle de la
/// rutina, que abre el botón del icono.
class _TodayCard extends StatelessWidget {
  const _TodayCard({
    super.key,
    required this.hasRoutines,
    required this.onTemplates,
    required this.pendingDay,
    required this.starting,
    required this.busy,
    required this.onStart,
    required this.onOpenRoutine,
  });

  final PendingDay? pendingDay;
  final bool starting;

  /// Sin ninguna rutina, la tarjeta invita a elegir una plantilla.
  final bool hasRoutines;
  final VoidCallback onTemplates;

  /// Otra acción del avance en curso (cerrar una sesión, repetir ciclo…).
  final bool busy;
  final ValueChanged<PendingDay> onStart;
  final ValueChanged<String> onOpenRoutine;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final day = pendingDay;
    if (day == null) {
      // Sin rutina, lo primero es elegir una; con rutinas pero ninguna en
      // curso, se dice tal cual. La sesión libre está debajo, en los atajos.
      return AppCard(
        padding: const EdgeInsets.all(TokensSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                hasRoutines
                    ? l10n.trainingNoActiveRoutine
                    : l10n.trainingNoRoutinesTitle,
                style: context.textStyles.titleMedium,
              ),
            ),
            const SizedBox(height: TokensSpacing.xs),
            Text(
              hasRoutines
                  ? l10n.trainingNoActiveRoutineHint
                  : l10n.trainingFirstRoutineHint,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (!hasRoutines) ...[
              const SizedBox(height: TokensSpacing.m),
              AppPrimaryButton(
                label: l10n.trainingTemplatesEntry,
                icon: Icons.view_list_rounded,
                onPressed: onTemplates,
              ),
            ],
          ],
        ),
      );
    }
    final date = day.scheduledDate;
    final inProgress = day.dayStatus == ProgressStatus.inProgress;
    final late = day.overdue && date != null && !inProgress;
    // Cuándo toca, en una palabra si es hoy.
    final when =
        inProgress || date == null || DateUtils.isSameDay(date, DateTime.now())
        ? l10n.commonDateToday
        : late
        ? overdueSinceLabel(l10n, date)
        : scheduledDayLabel(l10n, date);
    final figures = [
      if (day.estimatedMinutes > 0)
        l10n.trainingEstimatedMinutes(day.estimatedMinutes),
      if (day.exercises.isNotEmpty)
        l10n.trainingExercisesCount(day.exercises.length),
    ];
    return AppCoverCard(
      layout: AppCoverLayout.bottom,
      imageUrl: day.coverImageUrl,
      padding: const EdgeInsets.all(TokensSpacing.m),
      // Sin toque en toda la tarjeta: lleva sus propios botones.
      footer: Padding(
        padding: const EdgeInsets.only(top: TokensSpacing.m),
        child: Row(
          children: [
            Expanded(
              child: AppPrimaryButton(
                // Un día empezado y sin terminar se retoma, no se empieza.
                label: inProgress
                    ? l10n.trainingContinueDay
                    : l10n.trainingStart,
                icon: Icons.play_arrow_rounded,
                loading: starting,
                onPressed: busy ? null : () => onStart(day),
              ),
            ),
            const SizedBox(width: TokensSpacing.s),
            IconButton.outlined(
              tooltip: l10n.trainingSeeRoutine,
              onPressed: () => onOpenRoutine(day.routineId),
              icon: const Icon(Icons.list_alt_rounded),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // El nombre de la rutina, en gris junto a «Hoy»: da contexto sin
          // competir con lo que toca.
          // Con letra grande o un «Tocaba el miércoles» largo, el nombre baja
          // de línea en vez de cortarse.
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppCoverPill(
                icon: late ? AppIcons.overdue : AppIcons.upNext,
                color: late ? context.palette.warning : context.colors.primary,
                label: when,
              ),
              Text(
                day.routineName,
                style: context.textStyles.labelLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.xs),
          Semantics(
            header: true,
            child: Text(
              dayTitle(l10n, day.dayNumber, day.dayName),
              style: context.textStyles.headlineSmall,
            ),
          ),
          if (figures.isNotEmpty)
            Semantics(
              label: [
                if (day.estimatedMinutes > 0)
                  l10n.trainingEstimatedMinutesSpoken(day.estimatedMinutes),
                if (day.exercises.isNotEmpty)
                  l10n.trainingExercisesCount(day.exercises.length),
              ].join(', '),
              excludeSemantics: true,
              child: Text(
                figures.join(' · '),
                style: context.textStyles.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

/// «Mis rutinas» en carrusel (ADR 0055): foto, estado, nombre y lo que toca.
/// «Nueva rutina» va al final, como una tarjeta más.
class _RoutinesCarousel extends StatelessWidget {
  const _RoutinesCarousel({
    required this.routines,
    required this.nextDay,
    required this.onOpen,
    required this.onNew,
  });

  final List<RoutineSummary> routines;
  final PendingDay? nextDay;
  final ValueChanged<String> onOpen;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final width = context.scaled(TokensSize.routineCardWidth);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final r in routines)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: TokensSpacing.s),
                child: SizedBox(
                  width: width,
                  child: AppCoverCard(
                    layout: AppCoverLayout.bottom,
                    imageUrl: r.coverImageUrl,
                    padding: const EdgeInsets.all(TokensSpacing.sm),
                    onTap: () => onOpen(r.id),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppCoverPill(
                          icon: r.status.icon,
                          label: r.status.label(l10n),
                          color: r.status == RoutineStatus.active
                              ? context.colors.primary
                              : context.colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: TokensSpacing.xs),
                        Text(
                          r.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.titleMedium,
                        ),
                        if (nextDay case final next?
                            when next.routineId == r.id)
                          Text(
                            l10n.trainingRoutineNextUp(
                              dayTitle(l10n, next.dayNumber, next.dayName),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: context.scaled(TokensSize.newRoutineCardWidth),
              child: AppCard(
                onTap: onNew,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      color: context.colors.primary,
                      size: TokensSize.iconL,
                    ),
                    const SizedBox(height: TokensSpacing.xs),
                    Text(
                      l10n.trainingNewRoutine,
                      textAlign: TextAlign.center,
                      style: context.textStyles.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ciclo terminado: repetirlo (avance a cero, desde hoy) o preparar la
/// siguiente rutina con la IA.
class _CycleDoneCard extends StatelessWidget {
  const _CycleDoneCard({
    required this.routine,
    required this.busy,
    required this.onRestart,
    required this.onNextWithAi,
  });

  final RoutineSummary routine;
  final bool busy;
  final VoidCallback onRestart;
  final VoidCallback onNextWithAi;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: context.palette.accent,
                size: TokensSize.iconM,
              ),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                child: Text(
                  l10n.trainingCycleDoneTitle,
                  style: context.textStyles.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.xs),
          Text(
            l10n.trainingCycleDoneMessage(routine.name),
            style: context.textStyles.bodyMedium,
          ),
          const SizedBox(height: TokensSpacing.m),
          AppPrimaryButton(
            label: l10n.trainingRepeatCycle,
            icon: Icons.replay_rounded,
            onPressed: busy ? null : onRestart,
          ),
          const SizedBox(height: TokensSpacing.xs),
          AppSecondaryButton(
            label: l10n.trainingNextWithAi,
            icon: const Icon(AppIcons.proposal),
            onPressed: busy ? null : onNextWithAi,
          ),
        ],
      ),
    );
  }
}

class _Recommendations extends StatefulWidget {
  const _Recommendations({
    required this.recommendations,
    required this.busyIds,
    required this.onApply,
    required this.onDiscard,
  });

  final List<Recommendation> recommendations;
  final Set<String> busyIds;
  final ValueChanged<String> onApply;
  final ValueChanged<String> onDiscard;

  @override
  State<_Recommendations> createState() => _RecommendationsState();
}

class _RecommendationsState extends State<_Recommendations> {
  /// Plegadas de entrada: son ideas, no lo que toca hoy.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final all = widget.recommendations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: l10n.trainingRecommendationsCount(all.length),
          actionLabel: _expanded
              ? l10n.trainingRecommendationsLess
              : l10n.trainingRecommendationsShow,
          onAction: () => setState(() => _expanded = !_expanded),
          actionExpanded: _expanded,
        ),
        if (_expanded)
          for (final r in all)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensSpacing.s),
              child: RecommendationCard(
                recommendation: r,
                busy: widget.busyIds.contains(r.id),
                onApply: () => widget.onApply(r.id),
                onDiscard: () => widget.onDiscard(r.id),
              ),
            ),
      ],
    );
  }
}

/// Dice a la barra de la sesión abierta qué día retoma ya «Continuar» en esta
/// tarjeta, para que no haya dos caminos a la misma sesión (ADR 0039). Al
/// salir de Gimnasio lo borra y la barra vuelve a salir.
class _ContinueTargetSync extends StatefulWidget {
  const _ContinueTargetSync({required this.dayId});

  final String? dayId;

  @override
  State<_ContinueTargetSync> createState() => _ContinueTargetSyncState();
}

class _ContinueTargetSyncState extends State<_ContinueTargetSync> {
  final _target = getIt<ContinueSessionTarget>();

  @override
  void initState() {
    super.initState();
    _publish(widget.dayId);
  }

  @override
  void didUpdateWidget(_ContinueTargetSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dayId != widget.dayId) _publish(widget.dayId);
  }

  /// Tras el fotograma: avisar a la barra durante la construcción la
  /// reconstruiría a mitad de otro build.
  void _publish(String? dayId) => WidgetsBinding.instance.addPostFrameCallback(
    (_) => _target.value = dayId,
  );

  @override
  void dispose() {
    final target = _target;
    WidgetsBinding.instance.addPostFrameCallback((_) => target.value = null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
