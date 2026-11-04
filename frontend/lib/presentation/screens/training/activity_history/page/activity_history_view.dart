import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/sport_activity.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../l10n/gen_l10n/app_localizations.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_routes.dart';
import '../bloc/activity_history_bloc.dart';

/// Pestaña «Actividades y partidos» del historial: deporte hecho fuera de las
/// rutinas, con su duración, distancia, ritmo (o velocidad) y esfuerzo. El
/// ritmo lo calcula el servidor; aquí solo se escribe.
class ActivityHistoryView extends StatelessWidget {
  const ActivityHistoryView({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<ActivityHistoryBloc>()..add(const ActivityHistoryEvent.started()),
    child: const _ActivityList(),
  );
}

IconData activityKindIcon(ActivityKind? kind) => switch (kind) {
  ActivityKind.run => Icons.directions_run_rounded,
  ActivityKind.walk => Icons.directions_walk_rounded,
  ActivityKind.bike => Icons.directions_bike_rounded,
  ActivityKind.swim => Icons.pool_rounded,
  ActivityKind.match => Icons.sports_soccer_rounded,
  ActivityKind.other || null => Icons.sports_rounded,
};

String activityKindLabel(AppLocalizations l10n, ActivityKind kind) =>
    switch (kind) {
      ActivityKind.run => l10n.trainingActivityKindRun,
      ActivityKind.walk => l10n.trainingActivityKindWalk,
      ActivityKind.bike => l10n.trainingActivityKindBike,
      ActivityKind.swim => l10n.trainingActivityKindSwim,
      ActivityKind.match => l10n.trainingActivityKindMatch,
      ActivityKind.other => l10n.trainingActivityKindOther,
    };

class _ActivityList extends StatelessWidget {
  const _ActivityList();

  void _add(BuildContext context) =>
      context.push<void>(TrainingPaths.pastActivity);

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<ActivityHistoryBloc, ActivityHistoryState>(
      builder: (context, state) {
        if (state.loading && state.items.isEmpty) {
          return const AppSkeletonList(
            count: 5,
            height: TokensSize.guideSkeleton,
          );
        }
        if (state.error case final error? when state.items.isEmpty) {
          return AppErrorView(
            error: error,
            onRetry: () => context.read<ActivityHistoryBloc>().add(
              const ActivityHistoryEvent.started(),
            ),
          );
        }
        if (state.items.isEmpty) {
          return AppEmptyState(
            icon: Icons.directions_run_rounded,
            title: l10n.trainingActivitiesEmptyTitle,
            message: l10n.trainingActivitiesEmptyMessage,
            action: AppPrimaryButton(
              label: l10n.trainingActivitiesAdd,
              icon: Icons.add_rounded,
              onPressed: () => _add(context),
            ),
          );
        }
        return AppContentWidth.reading(
          child: ListView(
            padding: const EdgeInsets.all(TokensSpacing.m),
            children: [
              AppSecondaryButton(
                label: l10n.trainingActivitiesAdd,
                icon: const Icon(Icons.add_rounded),
                onPressed: () => _add(context),
              ),
              const SizedBox(height: TokensSpacing.m),
              for (final activity in state.items) ...[
                _ActivityTile(activity: activity),
                const SizedBox(height: TokensSpacing.s),
              ],
              if (state.hasMore)
                AppSecondaryButton(
                  label: l10n.trainingActivitiesMore,
                  loading: state.loadingMore,
                  onPressed: () => context.read<ActivityHistoryBloc>().add(
                    const ActivityHistoryEvent.moreRequested(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final SportActivity activity;

  /// «5:00» para el ritmo, con su lectura hablada aparte.
  static String _clock(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final number = NumberFormat.decimalPatternDigits(
      locale: l10n.localeName,
      decimalDigits: 1,
    );
    final kind = activity.kind;
    final title =
        activity.title ??
        (kind == null
            ? l10n.trainingActivityKindOther
            : activityKindLabel(l10n, kind));
    final pace = activity.paceSecondsPerKm;
    final figures = <(String, String?)>[
      (l10n.trainingActivityMinutes(activity.minutes), null),
      if (activity.distanceMeters case final m?)
        (l10n.trainingActivityDistance(number.format(m / 1000)), null),
      if (kind == ActivityKind.bike && activity.speedKmh != null)
        (l10n.trainingActivitySpeed(number.format(activity.speedKmh)), null)
      else if (kind == ActivityKind.swim && pace != null)
        (
          l10n.trainingActivityPacePer100(_clock((pace / 10).round())),
          l10n.trainingActivityPacePer100(
            l10n.trainingActivityPaceSpoken(
              (pace / 10).round() ~/ 60,
              (pace / 10).round() % 60,
            ),
          ),
        )
      else if (pace != null)
        (
          l10n.trainingActivityPace(_clock(pace)),
          l10n.trainingActivityPace(
            l10n.trainingActivityPaceSpoken(pace ~/ 60, pace % 60),
          ),
        ),
      if (activity.effort case final e?) (l10n.trainingActivityEffort(e), null),
    ];
    final date = toBeginningOfSentenceCase(
      DateFormat.MMMEd(l10n.localeName).add_Hm().format(activity.start),
    );
    return AppCard(
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: context.palette.accentContainer,
              child: Icon(
                activityKindIcon(kind),
                color: context.palette.accent,
              ),
            ),
            const SizedBox(width: TokensSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.textStyles.titleSmall),
                  Text(
                    date,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.xs),
                  Wrap(
                    spacing: TokensSpacing.s,
                    runSpacing: TokensSpacing.xs,
                    children: [
                      for (final (text, spoken) in figures)
                        AppPill(label: text, semanticLabel: spoken),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
