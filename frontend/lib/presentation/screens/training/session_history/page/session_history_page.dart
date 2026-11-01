import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../widgets/personal_record_row.dart';
import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/models/training/session.dart';
import '../../../../../domain/models/training/session_history.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_routes.dart';
import '../../widgets/open_session_card.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_effect_handler.dart';
import '../../widgets/training_labels.dart';
import '../../session_detail/page/session_detail_page.dart';
import '../bloc/session_history_bloc.dart';

/// Historial de entrenamiento: tus récords arriba, las sesiones sin terminar y
/// cada sesión agrupada por semana con el nombre del día que entrenaste y los
/// récords que batiste en ella.
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
            HistoryStatus.ready
                when state.items.isEmpty && state.open.isEmpty =>
              AppEmptyState(
                icon: Icons.history_rounded,
                title: l10n.trainingNoSessionsTitle,
                message: l10n.trainingNoSessionsMessage,
              ),
            HistoryStatus.ready => _HistoryList(state: state),
          },
        );
      },
    );
  }
}

/// Filas del historial: récords, «Sin terminar», cabecera de semana o sesión.
sealed class _Row {
  const _Row();
}

class _RecordsRow extends _Row {
  const _RecordsRow();
}

class _HeaderRow extends _Row {
  const _HeaderRow(this.title);
  final String title;
}

class _OpenRow extends _Row {
  const _OpenRow(this.open);
  final OpenSession open;
}

class _SessionRow extends _Row {
  const _SessionRow(this.entry);
  final SessionHistoryEntry entry;
}

class _LoadingRow extends _Row {
  const _LoadingRow();
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.state});

  final SessionHistoryState state;

  /// Lunes de la semana de [date] (las sesiones se agrupan por semana real).
  static DateTime _monday(DateTime date) {
    final day = DateUtils.dateOnly(date);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  List<_Row> _rows(BuildContext context) {
    final l10n = context.localizations;
    final rows = <_Row>[if (state.records.isNotEmpty) const _RecordsRow()];
    if (state.open.isNotEmpty) {
      rows.add(_HeaderRow(l10n.trainingUnfinishedTitle));
      rows.addAll(state.open.map(_OpenRow.new));
    }
    DateTime? week;
    for (final entry in state.items) {
      final monday = _monday(
        entry.session.completedAt ?? entry.session.startedAt,
      );
      if (week != monday) {
        week = monday;
        rows.add(
          _HeaderRow(
            l10n.trainingHistoryWeekOf(
              DateFormat.MMMd(l10n.localeName).format(monday),
            ),
          ),
        );
      }
      rows.add(_SessionRow(entry));
    }
    if (state.loadingMore) rows.add(const _LoadingRow());
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SessionHistoryBloc>();
    final rows = _rows(context);
    return RefreshIndicator(
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
          itemCount: rows.length,
          separatorBuilder: (_, _) => const SizedBox(height: TokensSpacing.s),
          itemBuilder: (context, i) => TrainingContent(
            child: switch (rows[i]) {
              _RecordsRow() => _RecordsStrip(records: state.records),
              _HeaderRow(:final title) => AppSectionHeader(title: title),
              _OpenRow(:final open) => OpenSessionCard(
                open: open,
                busy: state.busyIds.contains(open.session.id),
                onDiscard: () => bloc.add(
                  SessionHistoryEvent.staleDiscarded(open.session.id),
                ),
                onFinish: (figures) => bloc.add(
                  SessionHistoryEvent.staleFinished(
                    open.session.id,
                    minutes: figures.minutes,
                    rpe: figures.rpe,
                  ),
                ),
                onContinue: () =>
                    context.push(TrainingPaths.session(open.session.id)),
              ),
              _SessionRow(:final entry) => _SessionCard(
                entry: entry,
                busy: state.busyIds.contains(entry.session.id),
              ),
              _LoadingRow() => const AppLoadingView(),
            },
          ),
        ),
      ),
    );
  }
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
                        recordValueLabel(context, r),
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
    final bloc = context.read<SessionHistoryBloc>();
    final done = s.completedAt ?? s.startedAt;
    final date = DateFormat.MMMEd(l10n.localeName).add_Hm().format(done);
    // Nombre del día entrenado; si no tiene, el día de la semana; si es libre,
    // el tipo de sesión.
    final title = entry.dayNumber != null
        ? dayTitle(l10n, entry.dayNumber!, entry.dayName)
        : (entry.dayName ??
              switch (s.type) {
                SessionType.free => l10n.trainingSessionFree,
                SessionType.routine => l10n.trainingSessionRoutine,
                SessionType.weekly => l10n.trainingSessionWeekly,
              });
    final subtitle = [?entry.routineName, date].join(' · ');
    // Una sesión terminada se abre en su detalle de solo lectura (no en la
    // sesión en vivo); lo que se pida allí lo hace este historial al volver.
    Future<void> openDetail() async {
      final action = await context.push<SessionDetailAction>(
        TrainingPaths.sessionDetail(s.id),
        extra: entry,
      );
      switch (action) {
        case SessionDetailCorrect(:final minutes, :final rpe):
          bloc.add(
            SessionHistoryEvent.correctRequested(
              s.id,
              minutes: minutes,
              rpe: rpe,
            ),
          );
        case SessionDetailUnmark():
          bloc.add(SessionHistoryEvent.unmarkRequested(s.id));
        case SessionDetailDelete():
          bloc.add(SessionHistoryEvent.deleteRequested(s.id));
        case null:
          break;
      }
    }

    return AppCard(
      onTap: openDetail,
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
                        semanticsLabel: l10n.commonLoading,
                      ),
                    ),
                  ),
                )
              else
                // Corregir, desmarcar y eliminar están en el detalle (sin
                // menú de tres puntos dentro de una tarjeta pulsable).
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.colors.onSurfaceVariant,
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
            PersonalRecordRow(
              record: r,
              style: context.textStyles.labelMedium?.copyWith(
                color: context.palette.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
