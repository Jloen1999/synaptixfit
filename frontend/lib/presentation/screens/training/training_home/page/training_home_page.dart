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
import '../../widgets/exercise_thumbnail.dart';
import '../../widgets/open_session_card.dart';
import '../../widgets/recommendation_card.dart';
import '../../widgets/routine_summary_card.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_effect_handler.dart';
import '../../widgets/training_labels.dart';
import '../../widgets/training_section_bar.dart';
import '../bloc/training_home_bloc.dart';

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
              actions: [
                IconButton(
                  tooltip: l10n.trainingHistoryTitle,
                  onPressed: () => open(context, TrainingPaths.history),
                  icon: const Icon(AppIcons.history),
                ),
              ],
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
              _PendingDayCard(
                key: _guide.start,
                pendingDay: state.pendingDay,
                starting: state.startingSession,
                busy: state.working,
                onSkip: (day) => bloc.add(
                  TrainingHomeEvent.daySkipped(
                    routineId: day.routineId,
                    dayId: day.dayId,
                  ),
                ),
                onStart: (day) => bloc.add(
                  TrainingHomeEvent.sessionStarted(
                    routineId: day.routineId,
                    dayId: day.dayId,
                  ),
                ),
                onFreeSession: () =>
                    bloc.add(const TrainingHomeEvent.sessionStarted()),
                onOpenRoutine: (id) =>
                    _TrainingHomeView.open(context, TrainingPaths.routine(id)),
              ),
              const SizedBox(height: TokensSpacing.m),
              // Tres toques y el porqué de la adaptación de hoy (ADR 0033),
              // plegado en una línea hasta que se abre. Los partidos y otras
              // actividades se apuntan en Correr (ADR 0039).
              const QuickCheckInCard(),
              const SizedBox(height: TokensSpacing.l),
              AppSectionHeader(
                // Sin rutinas, la guía señala la tarjeta con los botones.
                key: state.routines.isEmpty ? null : _guide.routines,
                title: l10n.trainingMyRoutines,
                actionLabel: state.routines.isEmpty
                    ? null
                    : l10n.trainingNewRoutine,
                onAction: state.routines.isEmpty ? null : onNewRoutine,
              ),
              if (state.routines.isEmpty)
                AppCard(
                  key: _guide.routines,
                  child: AppEmptyState.compact(
                    icon: Icons.fitness_center_rounded,
                    title: l10n.trainingNoRoutinesTitle,
                    message: l10n.trainingNoRoutinesMessage,
                    // Las dos formas de empezar, sin pasar por el botón flotante.
                    action: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: TokensSpacing.s,
                      runSpacing: TokensSpacing.s,
                      children: [
                        AppPrimaryButton(
                          label: l10n.trainingNewRoutineAi,
                          icon: AppIcons.proposal,
                          onPressed: () => _TrainingHomeView.open(
                            context,
                            TrainingPaths.newRoutine(),
                          ),
                        ),
                        AppSecondaryButton(
                          label: l10n.trainingTemplatesEntry,
                          icon: const Icon(Icons.view_list_rounded),
                          onPressed: () => _TrainingHomeView.open(
                            context,
                            TrainingPaths.templates,
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
                for (final routine in state.routines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: TokensSpacing.s),
                    child: RoutineSummaryCard(
                      routine: routine,
                      nextDay: state.pendingDay,
                      onTap: () => _TrainingHomeView.open(
                        context,
                        TrainingPaths.routine(routine.id),
                      ),
                    ),
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
              const SizedBox(height: TokensSpacing.l),
              AppSectionHeader(title: l10n.trainingMoreTools),
              _QuickAccess(
                templatesKey: _guide.templates,
                onOpen: (path) => _TrainingHomeView.open(context, path),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PendingDayCard extends StatelessWidget {
  const _PendingDayCard({
    super.key,
    required this.pendingDay,
    required this.starting,
    required this.busy,
    required this.onSkip,
    required this.onStart,
    required this.onFreeSession,
    required this.onOpenRoutine,
  });

  final PendingDay? pendingDay;
  final bool starting;

  /// Otra acción del avance en curso (saltar, cerrar una sesión…).
  final bool busy;
  final ValueChanged<PendingDay> onSkip;
  final ValueChanged<PendingDay> onStart;
  final VoidCallback onFreeSession;
  final ValueChanged<String> onOpenRoutine;

  /// Ejercicios del día que se nombran en la tarjeta (el resto, «y N más»).
  static const _previewCount = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final day = pendingDay;
    if (day == null) {
      return AppCard(
        padding: const EdgeInsets.all(TokensSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.trainingNoPendingDay,
              style: context.textStyles.titleMedium,
            ),
            const SizedBox(height: TokensSpacing.xs),
            Text(
              l10n.trainingNoPendingDayHint,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TokensSpacing.m),
            AppSecondaryButton(
              label: l10n.trainingFreeSession,
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: starting ? null : onFreeSession,
            ),
          ],
        ),
      );
    }
    // Jerarquía: qué día toca (grande), cuándo y si va con retraso, cuánto
    // queda del ciclo y el botón para empezar. La foto del primer ejercicio
    // de fondo dice de un vistazo qué se va a entrenar.
    final whenText = day.scheduledDate != null
        ? scheduledDayLabel(l10n, day.scheduledDate!)
        : weekdayName(l10n, day.dayNumber);
    return AppCoverCard(
      layout: AppCoverLayout.bottom,
      imageUrl: day.coverImageUrl,
      padding: const EdgeInsets.all(TokensSpacing.m),
      // Sin toque en toda la tarjeta: lleva sus propios botones (nada de
      // controles anidados); la rutina se abre con «Ver rutina».
      // Lo que necesita el ancho entero va al pie, sin la foto detrás.
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (day.totalDays > 0) ...[
            const SizedBox(height: TokensSpacing.s),
            AppCycleProgress(
              progress: day.cycleProgress,
              label: l10n.trainingDaysProgress(
                day.completedDays + day.skippedDays,
                day.totalDays,
              ),
            ),
          ],
          const SizedBox(height: TokensSpacing.s),
          Text(
            [
              day.routineName,
              l10n.trainingWeekOfTotal(day.weekNumber, day.totalWeeks),
              l10n.trainingSessionOfWeek(day.sessionOfWeek, day.sessionsInWeek),
            ].join(' · '),
            style: context.textStyles.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          // Los nombres de los primeros ejercicios dicen qué toca hoy mejor
          // que solo las miniaturas.
          if (day.exercises.isNotEmpty) ...[
            const SizedBox(height: TokensSpacing.s),
            for (final e in day.exercises.take(_previewCount))
              Padding(
                padding: const EdgeInsets.only(bottom: TokensSpacing.xs),
                child: Row(
                  children: [
                    ExerciseThumbnail(
                      url: e.thumbnailUrl,
                      size: TokensSize.thumbnailXs,
                    ),
                    const SizedBox(width: TokensSpacing.s),
                    Expanded(
                      child: Text(
                        e.exerciseName,
                        style: context.textStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            if (day.exercises.length > _previewCount)
              Text(
                l10n.trainingRecommendationMoreExercises(
                  day.exercises.length - _previewCount,
                ),
                style: context.textStyles.labelMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
          ],
          const SizedBox(height: TokensSpacing.m),
          AppPrimaryButton(
            // Un día empezado y sin terminar se retoma, no se empieza.
            label: day.dayStatus == ProgressStatus.inProgress
                ? l10n.trainingContinueDay
                : l10n.trainingStart,
            icon: Icons.play_arrow_rounded,
            loading: starting,
            onPressed: busy ? null : () => onStart(day),
          ),
          const SizedBox(height: TokensSpacing.xs),
          // Saltar solo un día que no está en curso: la rutina pasa al
          // siguiente y el calendario retira este entrenamiento.
          OverflowBar(
            alignment: MainAxisAlignment.spaceBetween,
            overflowAlignment: OverflowBarAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.list_alt_rounded),
                label: Text(l10n.trainingSeeRoutine),
                onPressed: () => onOpenRoutine(day.routineId),
              ),
              if (day.dayStatus != ProgressStatus.inProgress)
                TextButton.icon(
                  icon: const Icon(Icons.redo_rounded),
                  label: Text(l10n.trainingSkipDay),
                  // Reversible: sin confirmar, con «Deshacer» en el aviso.
                  onPressed: busy || starting ? null : () => onSkip(day),
                ),
            ],
          ),
        ],
      ),
      // Texto abajo sobre la foto (ADR 0042): el estado en pastilla sólida y
      // tres datos como mucho (qué día, cuándo y cuánto). La rutina y los
      // ejercicios van al pie, a todo el ancho.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCoverPill(
            icon: day.overdue && day.scheduledDate != null
                ? AppIcons.overdue
                : AppIcons.upNext,
            color: day.overdue && day.scheduledDate != null
                ? context.palette.warning
                : context.colors.primary,
            label: day.overdue && day.scheduledDate != null
                ? overdueSinceLabel(l10n, day.scheduledDate!)
                : l10n.trainingNextWorkout,
          ),
          const SizedBox(height: TokensSpacing.xs),
          Text(
            dayTitle(l10n, day.dayNumber, day.dayName),
            style: context.textStyles.headlineSmall,
          ),
          // Cuándo toca, en qué semana va y cuánto dura (lo calcula el
          // servidor).
          Semantics(
            label: [
              whenText,
              if (day.estimatedMinutes > 0)
                l10n.trainingEstimatedMinutesSpoken(day.estimatedMinutes),
            ].join(', '),
            excludeSemantics: true,
            child: Text(
              [
                whenText,
                if (day.estimatedMinutes > 0)
                  l10n.trainingEstimatedMinutes(day.estimatedMinutes),
              ].join(' · '),
              style: context.textStyles.bodyMedium,
            ),
          ),
        ],
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

class _QuickAccess extends StatelessWidget {
  const _QuickAccess({required this.onOpen, this.templatesKey});

  final ValueChanged<String> onOpen;

  /// El acceso a las plantillas lleva la clave de la guía (ADR 0049).
  final GlobalKey? templatesKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final items = [
      (AppIcons.search, l10n.trainingExplorerTitle, TrainingPaths.exercises),
      (
        Icons.view_list_rounded,
        l10n.trainingTemplatesTitle,
        TrainingPaths.templates,
      ),
      (
        Icons.groups_rounded,
        l10n.trainingCommunityTitle,
        TrainingPaths.community,
      ),
      (
        AppIcons.calendar,
        l10n.trainingWeeklyPlanTitle,
        TrainingPaths.weeklyPlan,
      ),
    ];
    return AppTileGrid(
      // Icono y texto en fila: cada acceso necesita más ancho que en Inicio.
      minTileWidth: TokensLayout.minTouchTarget * 3,
      children: [
        for (final (icon, label, path) in items)
          AppCard(
            key: path == TrainingPaths.templates ? templatesKey : null,
            onTap: () => onOpen(path),
            child: Row(
              children: [
                Icon(icon, color: context.colors.secondary),
                const SizedBox(width: TokensSpacing.s),
                Expanded(
                  child: Text(
                    label,
                    style: context.textStyles.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
