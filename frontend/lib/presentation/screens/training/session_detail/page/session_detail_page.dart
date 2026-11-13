import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/models/training/session.dart';
import '../../../../../domain/models/training/session_history.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/exercise_thumbnail.dart';
import '../../widgets/personal_record_row.dart';
import '../../widgets/set_fields.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_dialogs.dart';
import '../../widgets/training_labels.dart';
import '../bloc/session_detail_bloc.dart';

/// Lo que se pidió hacer con la sesión desde su detalle; lo ejecuta el
/// historial al volver (así su lista y los récords se ponen al día).
sealed class SessionDetailAction {
  const SessionDetailAction();
}

/// Corregir esfuerzo y duración.
final class SessionDetailCorrect extends SessionDetailAction {
  const SessionDetailCorrect({required this.minutes, required this.rpe});

  final int minutes;
  final int rpe;
}

/// «Reabrir y seguir» (solo la terminada hoy): vuelve a abrirla con sus
/// series para seguir o corregir; el servidor la desmarca.
final class SessionDetailUnmark extends SessionDetailAction {
  const SessionDetailUnmark();
}

/// Eliminar: la borra para siempre con sus series.
final class SessionDetailDelete extends SessionDetailAction {
  const SessionDetailDelete();
}

/// Detalle de solo lectura de una sesión terminada (tocarla en el historial
/// ya no reabre la sesión en vivo): cifras, récords y series por ejercicio, con
/// «Corregir» (o «Reabrir y seguir» si es de hoy) y «Eliminar». Son dos cosas
/// distintas y la etiqueta lo dice: reabrir conserva las series y vuelve a la
/// sesión; eliminar la borra para siempre.
class SessionDetailPage extends StatelessWidget {
  const SessionDetailPage({super.key, required this.sessionId, this.entry});

  final String sessionId;
  final SessionHistoryEntry? entry;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<SessionDetailBloc>()
            ..add(SessionDetailEvent.started(sessionId, entry: entry)),
      child: _DetailView(sessionId: sessionId),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.sessionId});

  final String sessionId;

  static String _title(BuildContext context, SessionHistoryEntry? e) {
    final l10n = context.localizations;
    if (e == null) return l10n.trainingSessionDetailTitle;
    if (e.dayNumber != null) return dayTitle(l10n, e.dayNumber!, e.dayName);
    return e.dayName ??
        switch (e.session.type) {
          SessionType.free => l10n.trainingSessionFree,
          SessionType.routine => l10n.trainingSessionRoutine,
          SessionType.weekly => l10n.trainingSessionWeekly,
        };
  }

  Future<void> _correct(BuildContext context, SessionHistoryEntry e) async {
    final l10n = context.localizations;
    final navigator = Navigator.of(context);
    final figures = await showSessionFiguresDialog(
      context,
      confirmLabel: l10n.commonSave,
      subtitle: _title(context, e),
      initialMinutes: e.session.durationMinutes,
      initialRpe: e.session.rpe ?? 6,
    );
    if (figures == null) return;
    navigator.pop(
      SessionDetailCorrect(minutes: figures.minutes, rpe: figures.rpe),
    );
  }

  /// Reabrir no pierde nada (terminarla otra vez la vuelve a contar): no
  /// pregunta.
  void _reopen(BuildContext context) =>
      Navigator.of(context).pop(const SessionDetailUnmark());

  Future<void> _delete(BuildContext context, SessionHistoryEntry e) async {
    final l10n = context.localizations;
    final navigator = Navigator.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.trainingDeleteSessionTitle,
      message: l10n.trainingDeleteSessionMessage,
      confirmLabel: l10n.trainingDeleteSession,
    );
    if (ok) navigator.pop(const SessionDetailDelete());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<SessionDetailBloc, SessionDetailState>(
      builder: (context, state) {
        final entry = state.entry;
        final session = entry?.session;
        final date = session == null
            ? null
            : DateFormat.MMMEd(
                l10n.localeName,
              ).add_Hm().format(session.completedAt ?? session.startedAt);
        return Scaffold(
          appBar: AppPageBar(
            title: Text(
              _title(context, entry),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: switch (state.status) {
            SessionDetailStatus.loading => const AppSkeletonList(
              height: TokensSize.skeletonCard,
            ),
            SessionDetailStatus.failure => AppErrorView(
              error: state.error!,
              onRetry: () => context.read<SessionDetailBloc>().add(
                SessionDetailEvent.started(sessionId),
              ),
            ),
            SessionDetailStatus.ready => _Content(state: state, date: date),
          },
          bottomNavigationBar:
              state.status == SessionDetailStatus.ready &&
                  entry != null &&
                  entry.session.isCompleted
              ? SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(TokensSpacing.m),
                    child: TrainingContent(
                      // Uno al lado del otro; si no caben (letra grande o
                      // 320 dp), uno debajo del otro.
                      child: OverflowBar(
                        spacing: TokensSpacing.s,
                        overflowSpacing: TokensSpacing.s,
                        alignment: MainAxisAlignment.end,
                        overflowAlignment: OverflowBarAlignment.end,
                        children: [
                          entry.unmarkable
                              ? AppSecondaryButton(
                                  label: l10n.trainingReopenSession,
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  onPressed: () => _reopen(context),
                                )
                              : AppSecondaryButton(
                                  label: l10n.trainingCorrectSession,
                                  icon: const Icon(AppIcons.edit),
                                  onPressed: () => _correct(context, entry),
                                ),
                          // Eliminar borra para siempre: en tono de error.
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.colors.error,
                            ),
                            onPressed: () => _delete(context, entry),
                            icon: const Icon(AppIcons.delete),
                            label: Text(l10n.trainingDeleteSession),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state, required this.date});

  final SessionDetailState state;

  /// Cuándo se hizo («lun, 2 nov 18:30»).
  final String? date;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final entry = state.entry!;
    final session = entry.session;
    final h = state.highlights;
    // Series agrupadas por ejercicio, en el orden de la rutina (las libres o
    // de ejercicios que ya no están, al final).
    final groups = <String?, List<SessionSet>>{};
    for (final s in session.sets) {
      groups.putIfAbsent(s.plannedExerciseId, () => []).add(s);
    }
    final keys = groups.keys.toList()
      ..sort((a, b) {
        final oa = state.exercises[a]?.order ?? 1 << 20;
        final ob = state.exercises[b]?.order ?? 1 << 20;
        return oa.compareTo(ob);
      });
    final records = h?.records.isNotEmpty == true ? h!.records : entry.records;
    final number = NumberFormat.decimalPattern(l10n.localeName);
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        TrainingContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (date != null) ...[
                Text(
                  [?entry.routineName, date].join(' · '),
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: TokensSpacing.m),
              ],
              AppTileGrid(
                minTileWidth: TokensLayout.minTouchTarget * 2,
                children: [
                  AppMetricTile(
                    icon: Icons.timer_outlined,
                    color: context.colors.primary,
                    value: l10n.trainingMinutes(session.durationMinutes),
                    label: l10n.trainingSessionDetailDuration,
                  ),
                  if (session.rpe != null)
                    AppMetricTile(
                      icon: Icons.speed_rounded,
                      color: context.colors.tertiary,
                      value: l10n.trainingRpeShort(session.rpe!),
                      label: l10n.trainingSessionDetailEffort,
                    ),
                  AppMetricTile(
                    icon: Icons.repeat_rounded,
                    color: context.palette.sessions,
                    value:
                        '${h?.completedSets ?? session.sets.where((s) => s.completed).length}',
                    label: l10n.trainingSessionDetailSets,
                  ),
                  if ((h?.volumeKg ?? 0) > 0)
                    AppMetricTile(
                      icon: Icons.fitness_center_rounded,
                      color: context.palette.accent,
                      value: l10n.trainingChipWeight(
                        number.format(h!.volumeKg.round()),
                      ),
                      label: l10n.trainingSessionDetailVolume,
                    ),
                  if ((session.calories ?? 0) > 0)
                    AppMetricTile(
                      icon: Icons.local_fire_department_rounded,
                      color: context.palette.calories,
                      value: l10n.trainingChipKcal(session.calories!.round()),
                      label: l10n.trainingSessionDetailCalories,
                    ),
                ],
              ),
              if (records.isNotEmpty) ...[
                const SizedBox(height: TokensSpacing.l),
                AppSectionHeader(
                  title: l10n.trainingNewRecords(records.length),
                ),
                for (final r in records)
                  Padding(
                    padding: const EdgeInsets.only(bottom: TokensSpacing.xs),
                    child: PersonalRecordRow(record: r),
                  ),
              ],
              const SizedBox(height: TokensSpacing.l),
              AppSectionHeader(title: l10n.trainingSessionDetailExercises),
              if (groups.isEmpty)
                AppCard(
                  child: AppEmptyState.compact(
                    icon: Icons.fitness_center_rounded,
                    title: l10n.trainingSessionDetailNoSets,
                  ),
                ),
              for (final key in keys)
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensSpacing.s),
                  child: _ExerciseSets(
                    exercise: state.exercises[key],
                    // Serie de un hueco que ya no está en la rutina, pero que
                    // sí sabe qué ejercicio fue.
                    removed:
                        key != null && state.exercises[key] == null ||
                        key == null &&
                            groups[key]!.any((s) => s.exerciseId != null),
                    sets: [...groups[key]!]
                      ..sort((a, b) => a.setNumber.compareTo(b.setNumber)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Un ejercicio con sus series hechas, en solo lectura.
class _ExerciseSets extends StatelessWidget {
  const _ExerciseSets({
    required this.exercise,
    required this.sets,
    required this.removed,
  });

  /// Nulo en series libres o de un ejercicio que ya no está en la rutina.
  final PlannedExercise? exercise;
  final List<SessionSet> sets;

  /// El ejercicio se quitó o se sustituyó en la rutina después.
  final bool removed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final e = exercise;
    final fields = e == null ? null : SetFields.of(e);
    String value(SessionSet s) {
      final parts = [
        if (s.repsDone != null && (fields == null || fields.has(SetField.reps)))
          l10n.trainingSetReps(s.repsDone!),
        if (s.durationSeconds != null)
          fields != null && fields.isHold
              ? l10n.trainingSecondsUnit('${s.durationSeconds}')
              : formatClock(s.durationSeconds!),
        if (s.distanceMeters != null)
          l10n.trainingChipDistanceM(s.distanceMeters!),
        if (s.weightKg != null && s.weightKg! > 0)
          l10n.trainingChipWeight(formatNumber(s.weightKg!)),
        if (s.failedReps > 0) l10n.trainingSetFailed(s.failedReps),
      ];
      return parts.isEmpty ? '–' : parts.join(' · ');
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExerciseThumbnail(
                url: e?.thumbnailUrl,
                size: TokensSize.thumbnailS,
              ),
              const SizedBox(width: TokensSpacing.m),
              Expanded(
                child: Text(
                  e?.exerciseName ??
                      (removed
                          ? l10n.trainingExerciseNoLongerInRoutine
                          : l10n.trainingFreeSets),
                  style: context.textStyles.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          for (final s in sets)
            // Una sola frase por serie para el lector.
            MergeSemantics(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: TokensLayout.minTouchTarget,
                ),
                child: Row(
                  children: [
                    Icon(
                      s.completed
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: s.completed
                          ? context.palette.success
                          : context.palette.warning,
                      semanticLabel: s.completed
                          ? null
                          : l10n.trainingSetNotCompleted,
                    ),
                    const SizedBox(width: TokensSpacing.s),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: context.scaled(
                          TokensLayout.minTouchTarget + TokensSpacing.m,
                        ),
                      ),
                      child: Text(
                        l10n.trainingSetNumber(s.setNumber),
                        style: context.textStyles.labelLarge,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value(s),
                        style: context.textStyles.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
