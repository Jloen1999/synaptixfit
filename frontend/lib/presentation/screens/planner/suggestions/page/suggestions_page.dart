import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/planner/planner_ai.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../planner_routes.dart';
import '../../widgets/planner_focus.dart';
import '../../widgets/planner_visuals.dart';
import '../bloc/suggestions_bloc.dart';

/// Sugerencias de planificación con IA (`/planner/suggestions`).
class SuggestionsPage extends StatelessWidget {
  const SuggestionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SuggestionsBloc>(),
      child: const _SuggestionsView(),
    );
  }
}

class _SuggestionsView extends StatelessWidget with ErrorsMessageMixin {
  const _SuggestionsView();

  void _onNotice(BuildContext context, SuggestionsNotice notice) {
    final l10n = context.localizations;
    switch (notice) {
      case SuggestionsNoticeAccepted(
        :final created,
        :final failed,
        :final firstError,
      ):
        if (failed == 0) {
          context.showSnack(l10n.plannerAccepted(created));
        } else if (created == 0 && firstError != null) {
          context.showSnack(errorMessage(context, firstError));
        } else {
          context.showSnack(l10n.plannerAcceptedPartial(created, failed));
        }
      case SuggestionsNoticeFailure(:final error):
        context.showSnack(errorMessage(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<SuggestionsBloc, SuggestionsState>(
      listenWhen: (a, b) => a.noticeId != b.noticeId && b.notice != null,
      listener: (context, state) => _onNotice(context, state.notice!),
      builder: (context, state) {
        final bloc = context.read<SuggestionsBloc>();
        final suggestion = state.suggestion;
        final busy =
            state.status == SuggestionsStatus.generating ||
            state.status == SuggestionsStatus.accepting;
        return Scaffold(
          appBar: AppPageBar.reading(
            title: Text(l10n.plannerSuggestionsTitle),
            actions: [
              IconButton(
                tooltip: l10n.plannerOpenCalendar,
                onPressed: () => _openCalendar(context, state.weekStart),
                icon: const Icon(Icons.calendar_month_rounded),
              ),
            ],
          ),
          bottomNavigationBar: suggestion == null || suggestion.blocks.isEmpty
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(TokensSpacing.m),
                    child: AppPrimaryButton(
                      label: l10n.plannerAcceptSelected(state.selected.length),
                      icon: Icons.playlist_add_check_rounded,
                      loading: state.status == SuggestionsStatus.accepting,
                      onPressed: state.selected.isEmpty || busy
                          ? null
                          : () => bloc.add(
                              const SuggestionsEvent.acceptRequested(),
                            ),
                    ),
                  ),
                ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: TokensLayout.readingMaxWidth,
              ),
              child: ListView(
                padding: const EdgeInsets.all(TokensSpacing.m),
                children: [
                  _GoalsCard(state: state, busy: busy),
                  const SizedBox(height: TokensSpacing.l),
                  if (state.status == SuggestionsStatus.generating)
                    AppSkeletonGroup(
                      child: Column(
                        children: [
                          for (var i = 0; i < 4; i++) ...[
                            const AppSkeleton(height: 64),
                            const SizedBox(height: TokensSpacing.s),
                          ],
                        ],
                      ),
                    )
                  else if (state.error != null)
                    AppErrorView(
                      error: state.error!,
                      onRetry: () =>
                          bloc.add(const SuggestionsEvent.generateRequested()),
                    )
                  else if (suggestion != null)
                    ..._proposal(context, state, suggestion),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _proposal(
    BuildContext context,
    SuggestionsState state,
    WeekSuggestion suggestion,
  ) {
    final l10n = context.localizations;
    final bloc = context.read<SuggestionsBloc>();
    if (suggestion.blocks.isEmpty) {
      return [
        AppEmptyState(
          icon: Icons.event_available_rounded,
          title: l10n.plannerNoSuggestionsTitle,
          message: l10n.plannerNoSuggestionsMessage,
          action: AppSecondaryButton(
            label: l10n.plannerOpenCalendar,
            onPressed: () => _openCalendar(context, state.weekStart),
          ),
        ),
      ];
    }
    final selectable = suggestion.blocks.length - state.expired.length;
    final allSelected = selectable > 0 && state.selected.length == selectable;
    return [
      Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: context.colors.tertiary,
            size: 20,
          ),
          const SizedBox(width: TokensSpacing.s),
          Expanded(
            child: Text(
              l10n.plannerSourceAi,
              style: context.textStyles.titleSmall,
            ),
          ),
          TextButton(
            onPressed: selectable == 0
                ? null
                : () => bloc.add(SuggestionsEvent.allToggled(!allSelected)),
            child: Text(
              allSelected ? l10n.plannerSelectNone : l10n.plannerSelectAll,
            ),
          ),
        ],
      ),
      const SizedBox(height: TokensSpacing.s),
      for (var i = 0; i < suggestion.blocks.length; i++) ...[
        _SuggestedBlockTile(
          block: suggestion.blocks[i],
          selected: state.selected.contains(i),
          expired: state.expired.contains(i),
          onChanged: () => bloc.add(SuggestionsEvent.blockToggled(i)),
        ),
        const SizedBox(height: TokensSpacing.s),
      ],
    ];
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({required this.state, required this.busy});

  final SuggestionsState state;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<SuggestionsBloc>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.plannerSuggestionsIntro,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TokensSpacing.m),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 0, label: Text(l10n.plannerThisWeek)),
              ButtonSegment(value: 1, label: Text(l10n.plannerNextWeekShort)),
            ],
            selected: {state.weekOffset},
            onSelectionChanged: busy
                ? null
                : (s) => bloc.add(SuggestionsEvent.weekOffsetChanged(s.first)),
          ),
          const SizedBox(height: TokensSpacing.m),
          if (context.usageFocus.includesAcademic)
            _SliderRow(
              icon: Icons.menu_book_rounded,
              color: context.palette.study,
              label: l10n.plannerStudyHoursGoal,
              valueText: l10n.plannerHoursValue(
                PlannerFormats.hours(state.studyHours),
              ),
              slider: Slider(
                value: state.studyHours.clamp(0, 40),
                max: 40,
                divisions: 80,
                label: l10n.plannerHoursValue(
                  PlannerFormats.hours(state.studyHours),
                ),
                semanticFormatterCallback: (v) =>
                    l10n.plannerHoursValue(PlannerFormats.hours(v)),
                onChanged: busy
                    ? null
                    : (v) => bloc.add(SuggestionsEvent.studyHoursChanged(v)),
              ),
            ),
          if (context.usageFocus.includesFitness)
            _SliderRow(
              icon: Icons.fitness_center_rounded,
              color: context.colors.secondary,
              label: l10n.plannerSportSessionsGoal,
              valueText: l10n.plannerSessionsValue(state.sportSessions),
              slider: Slider(
                value: state.sportSessions.toDouble(),
                max: 7,
                divisions: 7,
                label: l10n.plannerSessionsValue(state.sportSessions),
                semanticFormatterCallback: (v) =>
                    l10n.plannerSessionsValue(v.round()),
                onChanged: busy
                    ? null
                    : (v) => bloc.add(
                        SuggestionsEvent.sportSessionsChanged(v.round()),
                      ),
              ),
            ),
          const SizedBox(height: TokensSpacing.s),
          AppPrimaryButton(
            label: state.suggestion == null
                ? l10n.plannerGenerate
                : l10n.plannerRegenerate,
            icon: Icons.lightbulb_outline_rounded,
            loading: state.status == SuggestionsStatus.generating,
            onPressed: busy
                ? null
                : () => bloc.add(const SuggestionsEvent.generateRequested()),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.valueText,
    required this.slider,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String valueText;
  final Widget slider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: TokensSpacing.s),
            Expanded(child: Text(label, style: context.textStyles.labelLarge)),
            Text(
              valueText,
              style: context.textStyles.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        slider,
      ],
    );
  }
}

class _SuggestedBlockTile extends StatelessWidget {
  const _SuggestedBlockTile({
    required this.block,
    required this.selected,
    required this.expired,
    required this.onChanged,
  });

  final SuggestedBlock block;
  final bool selected;
  final bool expired;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final color = block.type.color(context);
    final title =
        block.subjectName ??
        block.routineName ??
        block.topic ??
        block.type.label(context);
    // Una sola parada de foco: la tarjeta entera es la casilla.
    return MergeSemantics(
      child: AppCard(
        onTap: expired ? null : onChanged,
        padding: const EdgeInsets.symmetric(
          horizontal: TokensSpacing.s,
          vertical: TokensSpacing.xs,
        ),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: expired ? null : (_) => onChanged(),
            ),
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(TokensRadius.pill),
              ),
            ),
            const SizedBox(width: TokensSpacing.s),
            Icon(block.type.icon, color: color, size: 20),
            const SizedBox(width: TokensSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.textStyles.titleSmall),
                  Text(
                    [
                      block.type.label(context),
                      '${PlannerFormats.dayShort(block.start)} ${l10n.plannerTimeRange(PlannerFormats.time(block.start), PlannerFormats.time(block.end))}',
                      if (block.topic != null && block.topic != title)
                        block.topic!,
                    ].join(' · '),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  if (expired)
                    Text(
                      l10n.plannerSuggestionExpired,
                      style: context.textStyles.labelSmall?.copyWith(
                        color: context.colors.error,
                      ),
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

/// Vuelve al calendario. Se llega aquí desde él, así que basta con volver (y
/// el calendario se refresca); `go` destruiría las pestañas de la app.
void _openCalendar(BuildContext context, DateTime week) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.pushReplacement(PlannerPaths.week(week));
  }
}
