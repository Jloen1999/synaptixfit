import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/analytics_period.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/progress/analytics_report.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../progress_routes.dart';
import '../../widgets/analytics_summary.dart';
import '../../widgets/correlation_card.dart';
import '../../widgets/insight_card.dart';
import '../../widgets/insight_texts.dart';
import '../../widgets/progress_labels.dart';
import '../../widgets/rpe_trend_card.dart';
import '../../widgets/volume_chart_card.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../bloc/analytics_bloc.dart';

/// Analítica de entrenamiento: periodo, resumen, gráficas e interpretación.
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<AnalyticsBloc>()..add(const AnalyticsEvent.started()),
      child: const _AnalyticsView(),
    );
  }
}

class _AnalyticsView extends StatelessWidget with ErrorsMessageMixin {
  const _AnalyticsView();

  Future<void> _refresh(BuildContext context) {
    final bloc = context.read<AnalyticsBloc>()
      ..add(const AnalyticsEvent.started());
    return bloc.stream.firstWhere((s) => s.status != AnalyticsStatus.loading);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<AnalyticsBloc, AnalyticsState>(
      listenWhen: (previous, current) =>
          current.correlationError != null &&
          previous.correlationError != current.correlationError,
      listener: (context, state) =>
          context.showSnack(errorMessage(context, state.correlationError!)),
      builder: (context, state) {
        final report = state.report;
        final loading = state.status == AnalyticsStatus.loading;
        return Scaffold(
          appBar: AppPageBar(
            title: Text(l10n.progressAnalyticsTitle),
            bottom: loading && report != null
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(4),
                    child: LinearProgressIndicator(),
                  )
                : null,
          ),
          body: RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(TokensSpacing.m),
              children: [
                _Centered(child: _PeriodSelector(period: state.period)),
                const SizedBox(height: TokensSpacing.m),
                ..._body(context, state, report).map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: TokensSpacing.m),
                    child: _Centered(child: w),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _body(
    BuildContext context,
    AnalyticsState state,
    AnalyticsReport? report,
  ) {
    final l10n = context.localizations;
    if (state.status == AnalyticsStatus.failure) {
      return [
        AppErrorView(
          error: state.error ?? const AppError.unknown(),
          onRetry: () =>
              context.read<AnalyticsBloc>().add(const AnalyticsEvent.started()),
        ),
      ];
    }
    if (report == null) {
      return const [
        AppSkeletonGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSkeleton(height: 180),
              AppSkeleton(height: 260),
              AppSkeleton(height: 260),
            ],
          ),
        ),
      ];
    }
    if (!report.weekly.hasData && !report.correlation.sufficientData) {
      return [
        AppEmptyState(
          icon: Icons.insights_outlined,
          title: l10n.progressAnalyticsEmptyTitle,
          message: l10n.progressAnalyticsEmptyMessage,
          action: AppPrimaryButton(
            label: l10n.progressAnalyticsEmptyAction,
            icon: Icons.fitness_center_rounded,
            onPressed: () => context.go(ProgressExternalPaths.training),
          ),
        ),
      ];
    }
    final insights = [
      for (final insight in report.insights)
        if (InsightTexts.build(l10n, insight) case final text?)
          InsightCard(insight: insight, text: text),
    ];
    return [
      AppSectionHeader(title: l10n.progressAnalyticsSummaryTitle),
      AnalyticsSummary(weekly: report.weekly),
      VolumeChartCard(volume: report.volume),
      RpeTrendCard(trend: report.rpeTrend),
      // La relación estudio-entrenamiento solo tiene sentido con ambos ámbitos.
      if (context.select(
        (SessionBloc bloc) => bloc.account?.usageFocus.includesAcademic ?? true,
      ))
        CorrelationCard(
          correlation: report.correlation,
          metric: state.metric,
          loading: state.correlationLoading,
          onMetricChanged: (metric) => context.read<AnalyticsBloc>().add(
            AnalyticsEvent.metricChanged(metric),
          ),
        ),
      if (insights.isNotEmpty) ...[
        AppSectionHeader(title: l10n.progressInsightsTitle),
        ...insights,
      ],
    ];
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.period});

  final AnalyticsPeriod period;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<AnalyticsPeriod>(
          showSelectedIcon: false,
          segments: [
            for (final p in AnalyticsPeriod.values)
              ButtonSegment(
                value: p,
                label: Text(l10n.analyticsPeriod(p)),
                tooltip: l10n.progressAnalyticsLastWeeks(p.weeks),
              ),
          ],
          selected: {period},
          onSelectionChanged: (s) => context.read<AnalyticsBloc>().add(
            AnalyticsEvent.periodChanged(s.first),
          ),
        ),
        const SizedBox(height: TokensSpacing.xs),
        Text(
          l10n.progressAnalyticsLastWeeks(period.weeks),
          textAlign: TextAlign.center,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: TokensLayout.contentMaxWidth),
      child: child,
    ),
  );
}
