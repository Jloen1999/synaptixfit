import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/planner/planner_week.dart';
import '../../../../../domain/models/planner/weekly_planning.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../widgets/planner_visuals.dart';
import '../../widgets/week_overview.dart';
import '../bloc/weekly_load_bloc.dart';

/// Hoja con la carga y el balance de la semana: horas planificadas y reales,
/// estrés, sueño, notas y recálculo.
class WeeklyLoadSheet extends StatelessWidget {
  const WeeklyLoadSheet({super.key, required this.weekStart});

  final DateTime weekStart;

  static Future<void> show(BuildContext context, DateTime weekStart) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => WeeklyLoadSheet(weekStart: weekStart),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<WeeklyLoadBloc>()..add(WeeklyLoadEvent.started(weekStart)),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: _WeeklyLoadView(weekStart: weekStart),
      ),
    );
  }
}

class _WeeklyLoadView extends StatefulWidget {
  const _WeeklyLoadView({required this.weekStart});

  final DateTime weekStart;

  @override
  State<_WeeklyLoadView> createState() => _WeeklyLoadViewState();
}

class _WeeklyLoadViewState extends State<_WeeklyLoadView>
    with ErrorsMessageMixin {
  double _stress = 5;
  double _sleep = 7;
  final _notes = TextEditingController();
  bool _formInitialized = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _fill(WeeklyLoad? load) {
    if (_formInitialized) return;
    _formInitialized = true;
    if (load == null) return;
    _stress = load.stressLevel.clamp(1, 10).toDouble();
    _sleep = load.sleepHours.clamp(0, 14).toDouble();
    _notes.text = load.notes ?? '';
  }

  void _onNotice(BuildContext context, WeeklyLoadNotice notice) {
    final l10n = context.localizations;
    setState(() {
      switch (notice) {
        case WeeklyLoadNoticeSaved():
          _message = l10n.plannerWellbeingSaved;
          _messageIsError = false;
        case WeeklyLoadNoticeSynced(:final xpAwarded, :final account):
          if (account != null) {
            context.read<SessionBloc>().add(
              SessionEvent.accountUpdated(account),
            );
          }
          _message = xpAwarded > 0
              ? l10n.plannerSyncedXp(xpAwarded)
              : l10n.plannerSynced;
          _messageIsError = false;
        case WeeklyLoadNoticeFailure(:final error):
          _message = errorMessage(context, error);
          _messageIsError = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<WeeklyLoadBloc, WeeklyLoadState>(
      listenWhen: (a, b) => a.noticeId != b.noticeId && b.notice != null,
      listener: (context, state) => _onNotice(context, state.notice!),
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.plannerWeeklyLoadTitle,
                    style: context.textStyles.titleLarge,
                  ),
                  Text(
                    l10n.plannerWeekRange(
                      PlannerFormats.dayMonth(widget.weekStart),
                      PlannerFormats.dayMonth(
                        PlannerWeek.dayOf(widget.weekStart, 6),
                      ),
                    ),
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _body(context, state)),
          ],
        );
      },
    );
  }

  Widget _body(BuildContext context, WeeklyLoadState state) {
    final l10n = context.localizations;
    switch (state.status) {
      case WeeklyLoadStatus.loading:
        return AppSkeletonGroup(
          child: ListView(
            padding: const EdgeInsets.all(TokensSpacing.m),
            children: const [
              AppSkeleton(height: 120),
              SizedBox(height: TokensSpacing.m),
              AppSkeleton(height: 200),
            ],
          ),
        );
      case WeeklyLoadStatus.failure:
        return AppErrorView(
          error: state.error!,
          onRetry: () => context.read<WeeklyLoadBloc>().add(
            WeeklyLoadEvent.started(widget.weekStart),
          ),
        );
      case WeeklyLoadStatus.ready:
        _fill(state.load);
        final balance = state.balance;
        final load = state.load;
        return ListView(
          padding: const EdgeInsets.all(TokensSpacing.m),
          children: [
            if (balance != null) ...[
              Row(
                children: [
                  Expanded(
                    child: AppMetricTile(
                      icon: Icons.menu_book_rounded,
                      color: context.palette.study,
                      value: l10n.plannerHoursProgress(
                        PlannerFormats.hours(balance.actualStudyHours),
                        PlannerFormats.hours(balance.plannedStudyHours),
                      ),
                      label: l10n.plannerStudyHours,
                    ),
                  ),
                  const SizedBox(width: TokensSpacing.s),
                  Expanded(
                    child: AppMetricTile(
                      icon: Icons.fitness_center_rounded,
                      color: context.colors.secondary,
                      value: l10n.plannerHoursProgress(
                        PlannerFormats.hours(balance.actualSportHours),
                        PlannerFormats.hours(balance.plannedSportHours),
                      ),
                      label: l10n.plannerSportHours,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TokensSpacing.s),
              Align(
                alignment: Alignment.centerLeft,
                child: BalanceStateChip(balance: balance),
              ),
              const SizedBox(height: TokensSpacing.m),
            ],
            AppCard(
              child: load == null
                  ? Text(l10n.plannerNoLoadYet)
                  : Wrap(
                      spacing: TokensSpacing.l,
                      runSpacing: TokensSpacing.s,
                      children: [
                        _Stat(
                          l10n.plannerPlannedHours,
                          '${load.plannedHours} h',
                        ),
                        _Stat(l10n.plannerActualHours, '${load.actualHours} h'),
                        _Stat(l10n.plannerExamsCount, '${load.exams}'),
                        _Stat(
                          l10n.plannerDeliveriesCount,
                          '${load.deliveries}',
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: TokensSpacing.s),
            Align(
              alignment: Alignment.centerLeft,
              child: AppSecondaryButton(
                label: l10n.plannerSync,
                icon: state.syncing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded),
                onPressed: state.syncing
                    ? null
                    : () => context.read<WeeklyLoadBloc>().add(
                        const WeeklyLoadEvent.syncRequested(),
                      ),
              ),
            ),
            const SizedBox(height: TokensSpacing.l),
            Text(l10n.plannerStressLevel, style: context.textStyles.titleSmall),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _stress,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: l10n.plannerStressValue(_stress.round()),
                    semanticFormatterCallback: (v) =>
                        l10n.plannerStressValue(v.round()),
                    onChanged: (v) => setState(() => _stress = v),
                  ),
                ),
                Text(l10n.plannerStressValue(_stress.round())),
              ],
            ),
            Text(l10n.plannerSleepHours, style: context.textStyles.titleSmall),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _sleep,
                    max: 14,
                    divisions: 28,
                    label: l10n.plannerSleepValue(PlannerFormats.hours(_sleep)),
                    semanticFormatterCallback: (v) =>
                        l10n.plannerSleepValue(PlannerFormats.hours(v)),
                    onChanged: (v) => setState(() => _sleep = v),
                  ),
                ),
                Text(l10n.plannerSleepValue(PlannerFormats.hours(_sleep))),
              ],
            ),
            const SizedBox(height: TokensSpacing.s),
            AppTextField(
              label: l10n.plannerNotes,
              controller: _notes,
              icon: Icons.edit_note_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: TokensSpacing.m),
            if (_message != null) ...[
              AppInlineMessage(
                message: _message!,
                tone: _messageIsError
                    ? AppMessageTone.error
                    : AppMessageTone.warning,
              ),
              const SizedBox(height: TokensSpacing.s),
            ],
            AppPrimaryButton(
              label: l10n.commonSave,
              loading: state.saving,
              onPressed: () => context.read<WeeklyLoadBloc>().add(
                WeeklyLoadEvent.wellbeingSaved(
                  stressLevel: _stress.round(),
                  sleepHours: _sleep,
                  notes: _notes.text.trim(),
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: context.textStyles.titleLarge),
        Text(
          label,
          style: context.textStyles.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
