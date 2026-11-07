import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/run.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../progress/widgets/achievement_share.dart';
import '../../training_routes.dart';
import '../../widgets/run_labels.dart';
import '../../widgets/run_map.dart';
import '../../widgets/training_section_bar.dart';
import '../bloc/run_detail_bloc.dart';

/// Detalle de una carrera (ADR 0037): tipo, fecha, hora y origen; distancia,
/// ritmo medio (explicado), tiempo en movimiento, desnivel y «¿Cuánto te ha
/// costado?»; el mapa de la ruta con salida y llegada; el análisis por
/// kilómetro y borrar con «Deshacer». Compartir manda solo las cifras.
class RunDetailPage extends StatelessWidget {
  const RunDetailPage({super.key, required this.blockId});

  final String blockId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<RunDetailBloc>()..add(RunDetailEvent.started(blockId)),
    child: const _DetailView(),
  );
}

class _DetailView extends StatelessWidget with ErrorsMessageMixin {
  const _DetailView();

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(TrainingPaths.section(TrainingSection.run));
    }
  }

  void _delete(BuildContext context) {
    final bloc = context.read<RunDetailBloc>()
      ..add(const RunDetailEvent.deleteRequested());
    context.showUndoSnack(
      context.localizations.runDeleted,
      onUndo: () {
        if (!bloc.isClosed) bloc.add(const RunDetailEvent.deleteUndone());
      },
      onCommit: () {
        if (!bloc.isClosed) bloc.add(const RunDetailEvent.deleteCommitted());
      },
    );
  }

  void _share(BuildContext context, RunDetail run) {
    final l10n = context.localizations;
    final title = l10n.runShareTitle(
      RunLabels.kindName(l10n, run.kind),
      RunLabels.km(l10n, run.distanceMeters),
    );
    final detail = l10n.runShareDetail(
      RunLabels.clock(run.movingSeconds),
      RunLabels.pace(run.paceSecondsPerKm),
      run.elevationGainMeters,
    );
    final bloc = context.read<RunDetailBloc>();
    showAchievementShareDialog(
      context,
      card: AchievementShareCard(
        emblem: Icon(
          RunLabels.kindIcon(run.kind),
          color: context.colors.primary,
          size: TokensSize.medallion,
        ),
        title: title,
        detail: detail,
        accent: context.colors.primary,
      ),
      onShare: (png) =>
          bloc.add(RunDetailEvent.shared(png, '$title · $detail')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<RunDetailBloc, RunDetailState>(
      listenWhen: (p, c) =>
          (c.deleted && !p.deleted) ||
          (c.actionError != null && p.actionError != c.actionError),
      listener: (context, state) {
        if (state.actionError case final error?) {
          context.showSnack(errorMessage(context, error));
        }
        if (state.deleted) _close(context);
      },
      builder: (context, state) {
        final run = state.run;
        return Scaffold(
          appBar: AppPageBar.reading(
            title: Text(
              run == null
                  ? l10n.runKindRun
                  : run.title ?? RunLabels.kindName(l10n, run.kind),
            ),
            actions: [
              if (run != null && !state.pendingDelete) ...[
                IconButton(
                  tooltip: l10n.runShare,
                  onPressed: () => _share(context, run),
                  icon: const Icon(Icons.ios_share_rounded),
                ),
                IconButton(
                  tooltip: l10n.runDelete,
                  onPressed: () => _delete(context),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ],
          ),
          body: switch (state) {
            RunDetailState(loading: true) => const AppLoadingView(),
            RunDetailState(:final error?) => AppErrorView(
              error: error,
              onRetry: () => context.read<RunDetailBloc>().add(
                RunDetailEvent.started(state.blockId!),
              ),
            ),
            RunDetailState(pendingDelete: true) => AppEmptyState(
              icon: Icons.delete_outline_rounded,
              title: l10n.runDeleted,
              message: l10n.runDeletedHint,
              action: AppSecondaryButton(
                label: l10n.runUndo,
                icon: const Icon(Icons.undo_rounded),
                onPressed: () => context.read<RunDetailBloc>().add(
                  const RunDetailEvent.deleteUndone(),
                ),
              ),
            ),
            RunDetailState(run: final run?) => _Content(run: run),
            _ => const AppLoadingView(),
          },
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.run});

  final RunDetail run;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final when = toBeginningOfSentenceCase(
      DateFormat.yMMMEd(l10n.localeName).add_Hm().format(run.startedAt),
    );
    return AppContentWidth.reading(
      child: ListView(
        padding: const EdgeInsets.all(TokensSpacing.m),
        children: [
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.xs,
            children: [
              AppPill(
                icon: RunLabels.kindIcon(run.kind),
                label: RunLabels.kindName(l10n, run.kind),
              ),
              AppPill(icon: Icons.event_rounded, label: when),
              AppPill(icon: Icons.gps_fixed_rounded, label: l10n.runSourceGps),
            ],
          ),
          const SizedBox(height: TokensSpacing.m),
          AppTileGrid(
            children: [
              AppMetricTile(
                icon: Icons.straighten_rounded,
                color: context.colors.primary,
                value: RunLabels.km(l10n, run.distanceMeters),
                label: l10n.runDistance,
              ),
              AppMetricTile(
                icon: Icons.speed_rounded,
                color: context.colors.primary,
                value: RunLabels.pace(run.paceSecondsPerKm),
                label: l10n.runPaceUnit,
                detail: l10n.runPaceExplain,
              ),
              AppMetricTile(
                icon: Icons.timer_outlined,
                color: context.colors.primary,
                value: RunLabels.clock(run.movingSeconds),
                label: l10n.runMovingTime,
                detail: l10n.runMovingTimeExplain,
              ),
              AppMetricTile(
                icon: Icons.terrain_rounded,
                color: context.colors.primary,
                value: l10n.runMeters(run.elevationGainMeters),
                label: l10n.runElevation,
                detail: l10n.runElevationExplain,
              ),
              if (run.kcal case final kcal?)
                AppMetricTile(
                  icon: Icons.local_fire_department_rounded,
                  color: context.colors.primary,
                  value: l10n.runKcal(kcal),
                  label: l10n.runKcalLabel,
                ),
              AppMetricTile(
                icon: Icons.favorite_border_rounded,
                color: context.colors.primary,
                value: l10n.runEffortValue(run.effort),
                label: l10n.runEffortQuestion,
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.l),
          AppSectionHeader(title: l10n.runRouteTitle),
          const SizedBox(height: TokensSpacing.s),
          RunMap(
            route: run.route,
            semanticLabel: l10n.runRouteSpoken(
              RunLabels.km(l10n, run.distanceMeters),
            ),
          ),
          const SizedBox(height: TokensSpacing.xs),
          Text(
            l10n.runRoutePrivate,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (run.splits.isNotEmpty) ...[
            const SizedBox(height: TokensSpacing.l),
            AppSectionHeader(title: l10n.runSplitsTitle),
            const SizedBox(height: TokensSpacing.xs),
            Text(
              l10n.runSplitsExplain,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TokensSpacing.s),
            _Splits(splits: run.splits),
          ],
        ],
      ),
    );
  }
}

/// Barras por kilómetro: más larga = más rápido. El más rápido, destacado.
class _Splits extends StatelessWidget {
  const _Splits({required this.splits});

  final List<RunSplit> splits;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final paces = splits.map((s) => s.paceSecondsPerKm).where((p) => p > 0);
    final fastest = paces.isEmpty ? 0 : paces.reduce(math.min);
    final slowest = paces.isEmpty ? 0 : paces.reduce(math.max);
    return Column(
      children: [
        for (final s in splits)
          Semantics(
            label: l10n.runSplitSpoken(
              s.number,
              RunLabels.paceSpoken(l10n, s.paceSecondsPerKm),
            ),
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.only(bottom: TokensSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: TokensSize.listTileMin,
                      child: Text(
                        s.distanceMeters < 1000
                            ? RunLabels.km(l10n, s.distanceMeters)
                            : l10n.runSplitKm(s.number),
                        style: context.textStyles.labelLarge,
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          // El más lento ocupa un tercio; el más rápido, todo.
                          final share = slowest == fastest
                              ? 1.0
                              : 1 -
                                    (s.paceSecondsPerKm - fastest) /
                                        (slowest - fastest) *
                                        2 /
                                        3;
                          return Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Container(
                              width: box.maxWidth * share,
                              height: TokensSize.progressBar * 2,
                              decoration: BoxDecoration(
                                color: s.paceSecondsPerKm == fastest
                                    ? context.colors.primary
                                    : context.colors.secondaryContainer,
                                borderRadius: BorderRadius.circular(
                                  TokensRadius.s,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: TokensSpacing.s),
                    Text(
                      RunLabels.pace(s.paceSecondsPerKm),
                      style: context.textStyles.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
