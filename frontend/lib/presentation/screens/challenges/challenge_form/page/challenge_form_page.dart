import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/challenges/challenge.dart';
import '../../../../../domain/models/challenges/challenge_draft_validator.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../challenges_routes.dart';
import '../../link_picker/page/link_picker_sheet.dart';
import '../../widgets/challenge_content_width.dart';
import '../../widgets/challenge_feedback.dart';
import '../../widgets/challenge_labels.dart';
import '../../widgets/challenge_focus.dart';
import '../../widgets/challenge_selectors.dart';
import '../bloc/challenge_form_bloc.dart';
import 'milestone_editor_sheet.dart';

/// «Nuevo reto» completo (`/challenges/new`) o edición de las tareas de un
/// reto (`/challenges/:challengeId/milestones`). Al guardar hace `pop` con el id.
class ChallengeFormPage extends StatelessWidget {
  const ChallengeFormPage({
    super.key,
    this.args = const ChallengeFormArgs(),
    this.editChallengeId,
  });

  final ChallengeFormArgs args;
  final String? editChallengeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChallengeFormBloc>()
        ..add(
          ChallengeFormEvent.started(
            challengeId: editChallengeId,
            title: args.title,
            subjectId: args.subjectId,
            subjectName: args.subjectName,
            type:
                args.type ??
                (editChallengeId == null ? context.defaultChallengeType : null),
            difficulty: args.difficulty,
            endAt: args.endAt,
            sessionTarget: args.sessionTarget,
          ),
        ),
      child: _FormView(
        initialTitle: args.title ?? '',
        initialSessionTarget: args.sessionTarget,
      ),
    );
  }
}

class _FormView extends StatefulWidget {
  const _FormView({required this.initialTitle, this.initialSessionTarget});

  final String initialTitle;
  final int? initialSessionTarget;

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> with ErrorsMessageMixin {
  late final TextEditingController _title = TextEditingController(
    text: widget.initialTitle,
  );
  final _goal = TextEditingController();
  late final TextEditingController _sessionTarget = TextEditingController(
    text: widget.initialSessionTarget?.toString() ?? '',
  );

  ChallengeFormBloc get _bloc => context.read<ChallengeFormBloc>();

  @override
  void dispose() {
    _title.dispose();
    _goal.dispose();
    _sessionTarget.dispose();
    super.dispose();
  }

  void _onEffect(BuildContext context, ChallengeFormState state) {
    final l10n = context.localizations;
    switch (state.effect!) {
      case ChallengeFormSaved(
        :final challengeId,
        :final xpDelta,
        :final account,
      ):
        if (account != null) {
          context.read<SessionBloc>().add(SessionEvent.accountUpdated(account));
        }
        final editing = state.mode == ChallengeFormMode.editMilestones;
        context.showSnack(
          challengeFeedbackMessage(
            context,
            base: editing
                ? l10n.challengesFormTasksSaved
                : l10n.challengesCreated,
            xpDelta: xpDelta,
          ),
        );
        if (context.canPop()) {
          context.pop(challengeId);
        } else {
          context.go(ChallengesPaths.detail(challengeId));
        }
      case ChallengeFormSaveFailed(:final error):
        context.showSnack(errorMessage(context, error));
    }
  }

  Future<void> _editMilestone(MilestoneFormItem? item) async {
    final state = _bloc.state;
    final isNew = item == null;
    final result = await showMilestoneEditorSheet(
      context,
      initial:
          item ?? MilestoneFormItem(key: _bloc.newMilestoneKey(), title: ''),
      allItems: state.milestones,
      manualWeights: state.manualWeights,
      isNew: isNew,
      subjectId: state.subjectId,
    );
    if (result != null && mounted) {
      _bloc.add(ChallengeFormEvent.milestoneSaved(result));
    }
  }

  Future<void> _pickLink() async {
    final option = await showLinkPickerSheet(
      context,
      subjectId: _bloc.state.subjectId,
    );
    if (option == null || !mounted) return;
    _bloc.add(
      ChallengeFormEvent.linkChanged(
        link: ChallengeLink(type: option.type, entityId: option.id),
        label: challengeLinkOptionLabel(context, option),
      ),
    );
  }

  Future<void> _pickStart(ChallengeFormState state) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.startAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null && mounted) {
      _bloc.add(ChallengeFormEvent.startChanged(picked));
    }
  }

  Future<void> _pickEnd(ChallengeFormState state) async {
    final picked = await pickChallengeEndDate(
      context,
      initial: state.endAt ?? DateTime.now(),
    );
    if (picked != null && mounted) {
      _bloc.add(ChallengeFormEvent.endChanged(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<ChallengeFormBloc, ChallengeFormState>(
      listenWhen: (_, s) => s.effect != null,
      listener: _onEffect,
      builder: (context, state) {
        final editing = state.mode == ChallengeFormMode.editMilestones;
        final saving = state.status == ChallengeFormStatus.saving;
        return Scaffold(
          appBar: AppPageBar(
            title: Text(
              editing
                  ? l10n.challengesFormEditTasksTitle
                  : l10n.challengesFormTitle,
            ),
          ),
          bottomNavigationBar:
              state.status == ChallengeFormStatus.ready || saving
              ? SafeArea(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      border: Border(
                        top: BorderSide(color: context.colors.outlineVariant),
                      ),
                    ),
                    padding: const EdgeInsets.all(TokensSpacing.m),
                    child: ChallengeContentWidth(
                      child: AppPrimaryButton(
                        label: editing
                            ? l10n.challengesFormSaveTasks
                            : l10n.challengesFormSave,
                        loading: saving,
                        onPressed: () =>
                            _bloc.add(const ChallengeFormEvent.submitted()),
                      ),
                    ),
                  ),
                )
              : null,
          body: switch (state.status) {
            ChallengeFormStatus.loading => const AppLoadingView(),
            ChallengeFormStatus.failure => AppErrorView(
              error: state.error!,
              onRetry: () => _bloc.add(
                ChallengeFormEvent.started(challengeId: state.challengeId),
              ),
            ),
            _ => ListView(
              padding: const EdgeInsets.all(TokensSpacing.m),
              children: [
                ChallengeContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (editing)
                        Text(state.title, style: context.textStyles.titleLarge)
                      else
                        ..._detailsSections(context, state, saving),
                      const SizedBox(height: TokensSpacing.l),
                      _TasksSection(
                        state: state,
                        enabled: !saving,
                        onAdd: () => _editMilestone(null),
                        onEdit: _editMilestone,
                      ),
                      if (state.issue case final issue?) ...[
                        const SizedBox(height: TokensSpacing.m),
                        _IssueBanner(
                          text: issue.text(context, weightSum: state.weightSum),
                        ),
                      ],
                      const SizedBox(height: TokensSpacing.xl),
                    ],
                  ),
                ),
              ],
            ),
          },
        );
      },
    );
  }

  List<Widget> _detailsSections(
    BuildContext context,
    ChallengeFormState state,
    bool saving,
  ) {
    final l10n = context.localizations;
    final link = state.link;
    return [
      _Section(
        title: l10n.challengesFormSectionDetails,
        children: [
          TextField(
            controller: _title,
            enabled: !saving,
            maxLength: ChallengeDraftValidator.titleMax,
            textInputAction: TextInputAction.next,
            onChanged: (v) => _bloc.add(ChallengeFormEvent.titleChanged(v)),
            decoration: InputDecoration(
              labelText: l10n.challengesFieldTitle,
              hintText: l10n.challengesFieldTitleHint,
              prefixIcon: const Icon(Icons.flag_outlined),
              errorText: state.issue == ChallengeDraftIssue.titleTooShort
                  ? l10n.challengesValidationTitle
                  : null,
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          TextField(
            controller: _goal,
            enabled: !saving,
            maxLines: 3,
            minLines: 1,
            maxLength: 500,
            inputFormatters: [LengthLimitingTextInputFormatter(500)],
            onChanged: (v) => _bloc.add(ChallengeFormEvent.goalChanged(v)),
            decoration: InputDecoration(
              labelText: l10n.challengesFieldGoal,
              hintText: l10n.challengesFieldGoalHint,
              prefixIcon: const Icon(Icons.track_changes_rounded),
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          ChallengeTypeField(
            label: l10n.challengesFieldType,
            value: state.type,
            onChanged: saving
                ? null
                : (t) => _bloc.add(ChallengeFormEvent.typeChanged(t)),
          ),
          if (state.showsSessionTarget) ...[
            const SizedBox(height: TokensSpacing.m),
            TextField(
              controller: _sessionTarget,
              enabled: !saving,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              onChanged: (v) => _bloc.add(
                ChallengeFormEvent.sessionTargetChanged(int.tryParse(v)),
              ),
              decoration: InputDecoration(
                labelText: l10n.challengesFieldSessionTarget,
                hintText: l10n.challengesFieldSessionTargetHint,
                helperText: l10n.challengesFieldSessionTargetHelper,
                helperMaxLines: 3,
                prefixIcon: const Icon(Icons.fitness_center_rounded),
                errorText:
                    state.issue == ChallengeDraftIssue.sessionTargetInvalid
                    ? l10n.challengesIssueSessionTarget
                    : null,
              ),
            ),
          ],
          const SizedBox(height: TokensSpacing.m),
          Text(
            l10n.challengesEffortLabel,
            style: context.textStyles.labelLarge,
          ),
          const SizedBox(height: TokensSpacing.s),
          EffortSelector(
            value: state.difficulty,
            onChanged: saving
                ? null
                : (d) => _bloc.add(ChallengeFormEvent.difficultyChanged(d)),
          ),
          const SizedBox(height: TokensSpacing.m),
          ChallengeSubjectDropdown(
            key: ValueKey(state.subjects.length),
            subjects: state.subjects,
            value: state.subjectId,
            fallbackName: state.subjectName,
            onChanged: saving
                ? null
                : (id) => _bloc.add(ChallengeFormEvent.subjectChanged(id)),
          ),
        ],
      ),
      const SizedBox(height: TokensSpacing.l),
      _Section(
        title: l10n.challengesFormSectionDates,
        children: [
          ChallengeDateField(
            label: l10n.challengesFieldStartDate,
            icon: Icons.play_circle_outline_rounded,
            text: state.startAt == null
                ? l10n.challengesFieldStartNow
                : ChallengeFormats.longDate(state.startAt!),
            onTap: saving ? null : () => _pickStart(state),
            onClear: state.startAt == null || saving
                ? null
                : () => _bloc.add(const ChallengeFormEvent.startChanged(null)),
          ),
          const SizedBox(height: TokensSpacing.m),
          ChallengeDateField(
            label: l10n.challengesFieldEndDate,
            text: state.endAt == null
                ? ''
                : ChallengeFormats.longDate(state.endAt!),
            onTap: saving ? null : () => _pickEnd(state),
          ),
        ],
      ),
      const SizedBox(height: TokensSpacing.l),
      _Section(
        title: l10n.challengesFormSectionVisibility,
        children: [
          ChallengeVisibilitySelector(
            value: state.visibility,
            onChanged: saving
                ? null
                : (v) => _bloc.add(ChallengeFormEvent.visibilityChanged(v)),
          ),
        ],
      ),
      const SizedBox(height: TokensSpacing.l),
      _Section(
        title: l10n.challengesFormSectionLink,
        children: [
          Text(
            l10n.challengesFormLinkHint,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          if (link == null)
            Align(
              alignment: Alignment.centerLeft,
              child: AppSecondaryButton(
                label: l10n.challengesFormAddLink,
                icon: const Icon(Icons.link_rounded),
                onPressed: saving ? null : _pickLink,
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                avatar: Icon(link.type.icon),
                label: Text(state.linkLabel ?? link.type.label(context)),
                onPressed: saving ? null : _pickLink,
                deleteButtonTooltipMessage: l10n.challengesFormRemoveLink,
                onDeleted: saving
                    ? null
                    : () => _bloc.add(const ChallengeFormEvent.linkChanged()),
              ),
            ),
        ],
      ),
    ];
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.textStyles.titleMedium),
          const SizedBox(height: TokensSpacing.m),
          ...children,
        ],
      ),
    );
  }
}

class _TasksSection extends StatelessWidget {
  const _TasksSection({
    required this.state,
    required this.enabled,
    required this.onAdd,
    required this.onEdit,
  });

  final ChallengeFormState state;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<MilestoneFormItem> onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<ChallengeFormBloc>();
    final items = state.milestones;
    final weights = state.displayWeights;
    final titles = {for (final m in items) m.key: m.title};
    final sum = state.weightSum;
    final sumOk = (sum - 100).abs() <= ChallengeDraftValidator.weightTolerance;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.challengesFormSectionTasks,
                  style: context.textStyles.titleMedium,
                ),
              ),
              Text(
                l10n.challengesFormTasksCount(items.length),
                style: context.textStyles.labelLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.xs),
          Text(
            l10n.challengesFormTasksHint,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (items.length > 1) ...[
            const SizedBox(height: TokensSpacing.s),
            AppFocusOutline(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: state.manualWeights,
                onChanged: enabled
                    ? (v) =>
                          bloc.add(ChallengeFormEvent.manualWeightsToggled(v))
                    : null,
                title: Text(l10n.challengesFormManualWeights),
                subtitle: Text(l10n.challengesFormManualWeightsHint),
              ),
            ),
            if (state.manualWeights)
              Row(
                children: [
                  Icon(
                    sumOk ? Icons.check_circle_rounded : Icons.error_outline,
                    size: 18,
                    color: sumOk
                        ? context.palette.success
                        : context.colors.error,
                  ),
                  const SizedBox(width: TokensSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.challengesFormWeightSum(
                        ChallengeFormats.number(sum),
                      ),
                      style: context.textStyles.labelLarge?.copyWith(
                        color: sumOk ? null : context.colors.error,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: enabled
                        ? () => bloc.add(
                            const ChallengeFormEvent.weightsDistributed(),
                          )
                        : null,
                    child: Text(l10n.challengesFormDistribute),
                  ),
                ],
              ),
          ],
          const SizedBox(height: TokensSpacing.s),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: TokensSpacing.s),
              child: Text(
                l10n.challengesFormNoTasks,
                style: context.textStyles.bodyMedium,
              ),
            ),
          for (var i = 0; i < items.length; i++)
            _MilestoneRow(
              index: i,
              count: items.length,
              item: items[i],
              weight: i < weights.length ? weights[i] : 0,
              manualWeights: state.manualWeights,
              dependencyTitles: [
                for (final k in items[i].dependsOnKeys) ?titles[k],
              ],
              enabled: enabled,
              onEdit: () => onEdit(items[i]),
            ),
          const SizedBox(height: TokensSpacing.s),
          AppSecondaryButton(
            label: l10n.challengesFormAddTask,
            icon: const Icon(Icons.add_rounded),
            onPressed: enabled && state.canAddMilestone ? onAdd : null,
          ),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.index,
    required this.count,
    required this.item,
    required this.weight,
    required this.manualWeights,
    required this.dependencyTitles,
    required this.enabled,
    required this.onEdit,
  });

  final int index;
  final int count;
  final MilestoneFormItem item;
  final double weight;
  final bool manualWeights;
  final List<String> dependencyTitles;
  final bool enabled;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<ChallengeFormBloc>();
    final link = item.link;
    final attachment = item.noteId != null
        ? (item.noteTitle ?? l10n.challengesMilestoneNote)
        : item.fileId != null
        ? (item.fileName ?? l10n.challengesMilestoneFile)
        : null;
    return Container(
      margin: const EdgeInsets.only(bottom: TokensSpacing.s),
      padding: const EdgeInsets.all(TokensSpacing.s),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(TokensRadius.m),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              IconButton(
                tooltip: l10n.challengesMoveUp,
                onPressed: enabled && index > 0
                    ? () => bloc.add(
                        ChallengeFormEvent.milestoneMoved(item.key, -1),
                      )
                    : null,
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
              ),
              CircleAvatar(
                radius: 12,
                backgroundColor: context.colors.primaryContainer,
                child: Text(
                  '${index + 1}',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.onPrimaryContainer,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.challengesMoveDown,
                onPressed: enabled && index < count - 1
                    ? () => bloc.add(
                        ChallengeFormEvent.milestoneMoved(item.key, 1),
                      )
                    : null,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ],
          ),
          const SizedBox(width: TokensSpacing.s),
          Expanded(
            child: AppFocusOutline(
              borderRadius: BorderRadius.circular(TokensRadius.s),
              child: InkWell(
                onTap: enabled ? onEdit : null,
                borderRadius: BorderRadius.circular(TokensRadius.s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: TokensSpacing.s,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: context.textStyles.bodyLarge),
                      const SizedBox(height: TokensSpacing.xs),
                      Wrap(
                        spacing: TokensSpacing.s,
                        runSpacing: TokensSpacing.xs,
                        children: [
                          AppPill(
                            icon: Icons.pie_chart_outline_rounded,
                            label: l10n.challengesMilestoneWeight(
                              ChallengeFormats.number(weight),
                            ),
                            color: manualWeights
                                ? context.colors.primary
                                : context.colors.onSurfaceVariant,
                          ),
                          AppPill(
                            icon: item.difficulty.icon,
                            label: item.difficulty.effortLabel(context),
                            color: context.colors.onSurfaceVariant,
                          ),
                          if (item.completed)
                            AppPill(
                              icon: Icons.check_circle_rounded,
                              label: l10n.challengesMilestoneCompleted,
                              color: context.palette.success,
                            ),
                          if (attachment != null)
                            AppPill(
                              icon: item.noteId != null
                                  ? Icons.description_outlined
                                  : Icons.attach_file_rounded,
                              label: attachment,
                              color: context.colors.tertiary,
                            ),
                          if (link != null)
                            AppPill(
                              icon: link.type.icon,
                              label: link.type.label(context),
                              color: context.colors.tertiary,
                            ),
                        ],
                      ),
                      if (dependencyTitles.isNotEmpty) ...[
                        const SizedBox(height: TokensSpacing.xs),
                        Text(
                          dependencyTitles.length > 1
                              ? l10n.challengesFeedbackJoin(
                                  l10n.challengesMilestoneDependsOn(
                                    dependencyTitles.join(', '),
                                  ),
                                  item.condition.label(
                                    context,
                                    n: item.conditionN,
                                    total: dependencyTitles.length,
                                  ),
                                )
                              : l10n.challengesMilestoneDependsOn(
                                  dependencyTitles.first,
                                ),
                          style: context.textStyles.labelMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: l10n.challengesFormEditTaskTooltip,
                onPressed: enabled ? onEdit : null,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: l10n.challengesFormRemoveTaskTooltip,
                onPressed: enabled
                    ? () => bloc.add(
                        ChallengeFormEvent.milestoneRemoved(item.key),
                      )
                    : null,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IssueBanner extends StatelessWidget {
  const _IssueBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(TokensSpacing.m),
        decoration: BoxDecoration(
          color: context.colors.errorContainer,
          borderRadius: BorderRadius.circular(TokensRadius.m),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: context.colors.error),
            const SizedBox(width: TokensSpacing.s),
            Expanded(
              child: Text(
                text,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
