import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/models/training/session_history.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_routes.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_dialogs.dart';
import '../../widgets/training_effect_handler.dart';
import '../bloc/session_history_bloc.dart';

/// Historial de entrenamiento: tus récords arriba y cada sesión con el nombre
/// del día que entrenaste y los récords que batiste en ella.
class SessionHistoryPage extends StatelessWidget {
  const SessionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<SessionHistoryBloc>()..add(const SessionHistoryEvent.started()),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<SessionHistoryBloc, SessionHistoryState>(
      listenWhen: (p, c) => c.effect != null && p.effect != c.effect,
      listener: (context, state) =>
          const TrainingEffectHandler().handle(context, state.effect!),
      builder: (context, state) {
        final bloc = context.read<SessionHistoryBloc>();
        return Scaffold(
          appBar: AppPageBar(title: Text(l10n.trainingHistoryTitle)),
          body: switch (state.status) {
            HistoryStatus.loading => const AppSkeletonList(
              count: 6,
              height: 88,
            ),
            HistoryStatus.failure => AppErrorView(
              error: state.error!,
              onRetry: () => bloc.add(const SessionHistoryEvent.started()),
            ),
            HistoryStatus.ready when state.items.isEmpty => AppEmptyState(
              icon: Icons.history_rounded,
              title: l10n.trainingNoSessionsTitle,
              message: l10n.trainingNoSessionsMessage,
            ),
            HistoryStatus.ready => RefreshIndicator(
              onRefresh: () async {
                bloc.add(const SessionHistoryEvent.refreshed());
                await bloc.stream.firstWhere((s) => !s.refreshing);
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
                    bloc.add(const SessionHistoryEvent.moreRequested());
                  }
                  return false;
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(TokensSpacing.m),
                  // La primera fila son tus récords (si los hay).
                  itemCount:
                      state.items.length + 1 + (state.loadingMore ? 1 : 0),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: TokensSpacing.s),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return state.records.isEmpty
                          ? const SizedBox.shrink()
                          : TrainingContent(
                              child: _RecordsStrip(records: state.records),
                            );
                    }
                    final index = i - 1;
                    if (index >= state.items.length) {
                      return const AppLoadingView();
                    }
                    final entry = state.items[index];
                    return TrainingContent(
                      child: _SessionCard(
                        entry: entry,
                        busy: state.busyIds.contains(entry.session.id),
                      ),
                    );
                  },
                ),
              ),
            ),
          },
        );
      },
    );
  }
}

/// Texto de una marca: «62,5 kg × 5» o «8 reps».
String _recordValue(BuildContext context, PersonalRecord r) {
  final l10n = context.localizations;
  return r.kind == PersonalRecordKind.weight && r.weightKg != null
      ? l10n.trainingRecordWeight(
          NumberFormat('0.#', 'es').format(r.weightKg),
          r.reps,
        )
      : l10n.trainingRecordReps(r.reps);
}

/// Tus mejores marcas, en una tira horizontal (las más recientes primero).
class _RecordsStrip extends StatelessWidget {
  const _RecordsStrip({required this.records});

  final List<PersonalRecord> records;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: l10n.trainingRecordsTitle),
        SizedBox(
          height: context.scaled(TokensSize.recordCardHeight),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: records.length,
            separatorBuilder: (_, _) => const SizedBox(width: TokensSpacing.s),
            itemBuilder: (context, i) {
              final r = records[i];
              return SizedBox(
                width: context.scaled(TokensSize.recordCardWidth),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _recordValue(context, r),
                        style: context.textStyles.titleMedium?.copyWith(
                          color: context.palette.accent,
                        ),
                      ),
                      Text(
                        r.exerciseName ?? l10n.trainingRecordUnnamed,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: TokensSpacing.s),
        AppSectionHeader(title: l10n.trainingSessionsTitle),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.entry, required this.busy});

  final SessionHistoryEntry entry;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final s = entry.session;
    final date = DateFormat.MMMEd('es').add_Hm().format(s.startedAt);
    // Nombre del día entrenado; si no tiene, «Día N»; si es libre, el tipo.
    final title =
        entry.dayName ??
        (entry.dayNumber != null
            ? l10n.trainingDayNumber(entry.dayNumber!)
            : switch (s.type) {
                SessionType.free => l10n.trainingSessionFree,
                SessionType.routine => l10n.trainingSessionRoutine,
                SessionType.weekly => l10n.trainingSessionWeekly,
              });
    final subtitle = [?entry.routineName, date].join(' · ');

    Future<void> unmark() async {
      final bloc = context.read<SessionHistoryBloc>();
      final ok = await showConfirmDialog(
        context,
        title: l10n.trainingUnmarkTitle,
        message: l10n.trainingUnmarkMessage(s.xpAwarded),
        confirmLabel: l10n.trainingUnmark,
      );
      if (ok) bloc.add(SessionHistoryEvent.unmarkRequested(s.id));
    }

    return AppCard(
      onTap: () => context.push(TrainingPaths.session(s.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textStyles.titleSmall),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                SizedBox.square(
                  dimension: TokensLayout.minTouchTarget,
                  child: Center(
                    child: SizedBox.square(
                      dimension: TokensSize.iconM,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: l10n.trainingUnmark,
                      ),
                    ),
                  ),
                )
              else
                // Desmarcar es poco frecuente: va en el menú, no a la vista.
                PopupMenuButton<void>(
                  tooltip: l10n.trainingMoreOptions,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      onTap: unmark,
                      child: Text(l10n.trainingUnmark),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          Wrap(
            spacing: TokensSpacing.xs,
            runSpacing: TokensSpacing.xs,
            children: [
              AppPill(
                icon: Icons.timer_outlined,
                label: l10n.trainingMinutes(s.durationMinutes),
              ),
              if (s.rpe != null)
                AppPill(
                  icon: Icons.speed_rounded,
                  label: l10n.trainingRpeValue(s.rpe!),
                ),
              if (s.xpAwarded > 0)
                AppPill(
                  icon: Icons.star_rounded,
                  color: context.palette.accent,
                  label: l10n.trainingXpGained(s.xpAwarded),
                ),
            ],
          ),
          for (final r in entry.records) ...[
            const SizedBox(height: TokensSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  size: TokensSize.iconS,
                  color: context.palette.accent,
                ),
                const SizedBox(width: TokensSpacing.xs),
                Expanded(
                  child: Text(
                    r.exerciseName == null
                        ? l10n.trainingRecordBrokenUnnamed(
                            _recordValue(context, r),
                          )
                        : l10n.trainingRecordBroken(
                            r.exerciseName!,
                            _recordValue(context, r),
                          ),
                    style: context.textStyles.labelMedium?.copyWith(
                      color: context.palette.accent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
