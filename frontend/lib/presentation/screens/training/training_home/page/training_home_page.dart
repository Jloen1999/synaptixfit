import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/models/training/recommendation.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/models/training/wellbeing.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_routes.dart';
import '../../widgets/exercise_thumbnail.dart';
import '../../widgets/open_session_card.dart';
import '../../widgets/recommendation_card.dart';
import '../../widgets/routine_summary_card.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_effect_handler.dart';
import '../../widgets/training_labels.dart';
import '../bloc/training_home_bloc.dart';

/// Pestaña Rutinas.
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

class _TrainingHomeView extends StatelessWidget {
  const _TrainingHomeView();

  /// Abre una pantalla y recarga al volver (los datos pueden haber cambiado).
  static Future<void> open(BuildContext context, String location) async {
    final bloc = context.read<TrainingHomeBloc>();
    await context.push(location);
    if (!bloc.isClosed) bloc.add(const TrainingHomeEvent.refreshed());
  }

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
                  Icons.auto_awesome_rounded,
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
      await open(context, TrainingPaths.newRoutine(mode: mode));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<TrainingHomeBloc, TrainingHomeState>(
      listenWhen: (p, c) => c.effect != null && p.effect != c.effect,
      listener: (context, state) =>
          const TrainingEffectHandler().handle(context, state.effect!),
      builder: (context, state) {
        return Scaffold(
          appBar: AppPageBar(
            title: Text(l10n.tabTraining),
            actions: [
              IconButton(
                tooltip: l10n.trainingPastActivityTitle,
                onPressed: () => open(context, TrainingPaths.pastActivity),
                icon: const Icon(Icons.add_task_rounded),
              ),
              IconButton(
                tooltip: l10n.trainingHistoryTitle,
                onPressed: () => open(context, TrainingPaths.history),
                icon: const Icon(Icons.history_rounded),
              ),
            ],
          ),
          floatingActionButton: state.status == HomeStatus.ready
              ? FloatingActionButton.extended(
                  onPressed: () => _newRoutine(context),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.trainingNewRoutine),
                )
              : null,
          body: switch (state.status) {
            HomeStatus.loading => const AppSkeletonList(height: 120),
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
              child: _HomeContent(state: state),
            ),
          },
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.state});

  final TrainingHomeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<TrainingHomeBloc>();
    // Ciclo terminado: no queda día que hacer y no hay otra rutina en curso.
    final finished = state.pendingDay == null &&
            !state.routines.any((r) => r.status == RoutineStatus.active)
        ? state.routines
              .where((r) => r.status == RoutineStatus.completed)
              .firstOrNull
        : null;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        TokensSpacing.s,
        TokensSpacing.m,
        TokensSpacing.xxl * 2,
      ),
      children: [
        TrainingContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              _CheckInCard(
                checkIn: state.todayCheckIn,
                onOpen: () =>
                    _TrainingHomeView.open(context, TrainingPaths.checkIn),
              ),
              const SizedBox(height: TokensSpacing.l),
              AppSectionHeader(title: l10n.trainingMyRoutines),
              if (state.routines.isEmpty)
                AppCard(
                  child: AppEmptyState.compact(
                    icon: Icons.fitness_center_rounded,
                    title: l10n.trainingNoRoutinesTitle,
                    message: l10n.trainingNoRoutinesMessage,
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
    return AppCoverCard(
      imageUrl: day.coverImageUrl,
      // Sin toque en toda la tarjeta: lleva sus propios botones (nada de
      // controles anidados); la rutina se abre con «Ver rutina».
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                color: context.colors.primary,
                size: TokensSize.iconS,
              ),
              const SizedBox(width: TokensSpacing.xs),
              // Expanded: con el texto al 200 % la etiqueta se parte en vez
              // de desbordar la fila.
              Expanded(
                child: Text(
                  l10n.trainingNextWorkout,
                  style: context.textStyles.labelLarge?.copyWith(
                    color: context.colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          Text(
            dayTitle(l10n, day.dayNumber, day.dayName),
            style: context.textStyles.headlineSmall,
          ),
          // Cuándo toca, en qué semana va y qué sesión de la semana es.
          Text(
            [
              nextDayHeadline(
                l10n,
                date: day.scheduledDate,
                weekNumber: day.weekNumber,
                totalWeeks: day.totalWeeks,
                dayNumber: day.dayNumber,
              ),
              l10n.trainingSessionOfWeek(day.sessionOfWeek, day.sessionsInWeek),
            ].join(' · '),
            style: context.textStyles.bodyMedium,
          ),
          Text(
            day.routineName,
            style: context.textStyles.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          Wrap(
            spacing: TokensSpacing.xs,
            runSpacing: TokensSpacing.xs,
            children: [
              if (day.overdue && day.scheduledDate != null)
                AppCoverPill(
                  icon: Icons.schedule_rounded,
                  color: context.palette.warning,
                  label: overdueSinceLabel(l10n, day.scheduledDate!),
                ),
              AppCoverPill(
                icon: Icons.fitness_center_rounded,
                label: l10n.trainingExercisesCount(day.exercises.length),
              ),
            ],
          ),
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
                onPressed: busy || starting
                    ? null
                    : () async {
                        final ok = await showConfirmDialog(
                          context,
                          title: l10n.trainingSkipDayTitle,
                          message: l10n.trainingSkipDayMessage,
                          confirmLabel: l10n.trainingSkipDay,
                          destructive: false,
                        );
                        if (ok) onSkip(day);
                      },
              ),
            ],
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
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: busy ? null : onNextWithAi,
          ),
        ],
      ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  const _CheckInCard({required this.checkIn, required this.onOpen});

  final CheckIn? checkIn;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final c = checkIn;
    if (c == null) {
      return AppCard(
        onTap: onOpen,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: context.palette.accentContainer,
              child: Icon(Icons.mood_rounded, color: context.palette.accent),
            ),
            const SizedBox(width: TokensSpacing.m),
            // Solo la pregunta: el porqué se explica dentro del check-in.
            Expanded(
              child: Text(
                l10n.trainingCheckInCtaTitle,
                style: context.textStyles.titleSmall,
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      );
    }
    final fatigueColor = c.requiresAdaptation
        ? context.palette.warning
        : context.palette.success;
    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.trainingCheckInToday,
                  style: context.textStyles.titleSmall,
                ),
              ),
              Text(
                l10n.trainingFatigueScore(c.fatigueScore),
                style: context.textStyles.labelLarge?.copyWith(
                  color: fatigueColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          ClipRRect(
            borderRadius: BorderRadius.circular(TokensRadius.pill),
            child: LinearProgressIndicator(
              value: c.fatigueScore / 100,
              color: fatigueColor,
              backgroundColor: context.colors.surfaceContainer,
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          Row(
            children: [
              Icon(
                c.requiresAdaptation
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                size: TokensSize.iconXs,
                color: fatigueColor,
              ),
              const SizedBox(width: TokensSpacing.xs),
              Expanded(
                child: Text(
                  c.requiresAdaptation
                      ? l10n.trainingFatigueAdapt
                      : l10n.trainingFatigueOk,
                  style: context.textStyles.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sugerencias del servidor plegadas: se ve la primera y el resto bajo
/// demanda, para que no tapen las rutinas (pueden ser muchas a la vez).
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
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final all = widget.recommendations;
    final visible = _expanded ? all : all.take(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: l10n.trainingRecommendationsCount(all.length),
          actionLabel: all.length > 1
              ? (_expanded
                    ? l10n.trainingRecommendationsLess
                    : l10n.trainingRecommendationsAll)
              : null,
          onAction: all.length > 1
              ? () => setState(() => _expanded = !_expanded)
              : null,
          actionExpanded: all.length > 1 ? _expanded : null,
        ),
        for (final r in visible)
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
  const _QuickAccess({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final items = [
      (
        Icons.search_rounded,
        l10n.trainingExplorerTitle,
        TrainingPaths.exercises,
      ),
      (
        Icons.groups_rounded,
        l10n.trainingCommunityTitle,
        TrainingPaths.community,
      ),
      (
        Icons.calendar_month_rounded,
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
