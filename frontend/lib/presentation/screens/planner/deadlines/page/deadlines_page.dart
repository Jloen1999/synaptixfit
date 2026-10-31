import '../../../../../domain/enums/item_time_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/planner_enums.dart';
import '../../../../../domain/models/planner/deadline.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../widgets/deadline_form_sheet.dart';
import '../../widgets/planner_visuals.dart';
import '../bloc/deadlines_bloc.dart';

/// Entregas y exámenes (`/planner/deadlines`).
class DeadlinesPage extends StatelessWidget {
  const DeadlinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<DeadlinesBloc>()..add(const DeadlinesEvent.started()),
      child: const _DeadlinesView(),
    );
  }
}

class _DeadlinesView extends StatelessWidget with ErrorsMessageMixin {
  const _DeadlinesView();

  Future<void> _openForm(BuildContext context, {Deadline? deadline}) async {
    final bloc = context.read<DeadlinesBloc>();
    final draft = await DeadlineFormSheet.show(
      context,
      deadline: deadline,
      subjects: bloc.state.subjects,
    );
    if (draft != null) {
      bloc.add(DeadlinesEvent.saved(id: deadline?.id, draft: draft));
    }
  }

  void _onNotice(BuildContext context, DeadlinesNotice notice) {
    final l10n = context.localizations;
    switch (notice) {
      case DeadlinesNoticeSaved(:final created):
        context.showSnack(
          created ? l10n.plannerDeadlineCreated : l10n.plannerDeadlineUpdated,
        );
      case DeadlinesNoticeDeleted(:final id):
        final bloc = context.read<DeadlinesBloc>();
        context.showUndoSnack(
          l10n.plannerDeadlineDeleted,
          onUndo: () {
            if (!bloc.isClosed) bloc.add(DeadlinesEvent.deleteUndone(id));
          },
          onCommit: () {
            if (!bloc.isClosed) bloc.add(DeadlinesEvent.deleteCommitted(id));
          },
        );
      case DeadlinesNoticeCompletion(
        :final completed,
        :final xpDelta,
        :final account,
      ):
        if (account != null) {
          context.read<SessionBloc>().add(SessionEvent.accountUpdated(account));
        }
        context.showSnack(
          !completed
              ? l10n.plannerDeadlinePending
              : xpDelta > 0
              ? l10n.plannerDeadlineCompletedXp(xpDelta)
              : l10n.plannerDeadlineCompleted,
        );
      case DeadlinesNoticeFailure(:final error):
        context.showSnack(errorMessage(context, error));
    }
  }

  @override
  Widget build(BuildContext context) => AppUndoShortcut(
    onUndo: () {
      final bloc = context.read<DeadlinesBloc>();
      final last = bloc.state.pendingDeletionIds.lastOrNull;
      if (last == null) return;
      bloc.add(DeadlinesEvent.deleteUndone(last));
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    },
    child: _content(context),
  );

  Widget _content(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<DeadlinesBloc, DeadlinesState>(
      listenWhen: (a, b) => a.noticeId != b.noticeId && b.notice != null,
      listener: (context, state) => _onNotice(context, state.notice!),
      builder: (context, state) {
        return Scaffold(
          appBar: AppPageBar.reading(title: Text(l10n.plannerDeadlinesTitle)),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'planner-add-deadline',
            onPressed: state.saving ? null : () => _openForm(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.plannerNewDeadline),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: TokensLayout.readingMaxWidth,
              ),
              child: Column(
                children: [
                  _Filters(state: state),
                  Expanded(child: _list(context, state)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _list(BuildContext context, DeadlinesState state) {
    final l10n = context.localizations;
    final bloc = context.read<DeadlinesBloc>();
    switch (state.status) {
      case DeadlinesStatus.loading:
        return AppSkeletonGroup(
          child: ListView(
            padding: const EdgeInsets.all(TokensSpacing.m),
            children: [
              for (var i = 0; i < 5; i++) ...[
                const AppSkeleton(height: 76),
                const SizedBox(height: TokensSpacing.s),
              ],
            ],
          ),
        );
      case DeadlinesStatus.failure:
        return AppErrorView(
          error: state.error!,
          onRetry: () => bloc.add(const DeadlinesEvent.started()),
        );
      case DeadlinesStatus.ready:
        return RefreshIndicator(
          onRefresh: () async {
            bloc.add(const DeadlinesEvent.refreshed());
            await bloc.stream.first.timeout(
              const Duration(seconds: 10),
              onTimeout: () => bloc.state,
            );
          },
          child: state.visibleItems.isEmpty
              ? ListView(
                  children: [
                    AppEmptyState(
                      icon: Icons.event_available_rounded,
                      title: l10n.plannerDeadlinesEmptyTitle,
                      message: l10n.plannerDeadlinesEmptyMessage,
                      action: AppPrimaryButton(
                        label: l10n.plannerNewDeadline,
                        icon: Icons.add_rounded,
                        onPressed: () => _openForm(context),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    TokensSpacing.m,
                    TokensSpacing.s,
                    TokensSpacing.m,
                    96,
                  ),
                  itemCount:
                      state.visibleItems.length + (state.hasMore ? 1 : 0),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: TokensSpacing.s),
                  itemBuilder: (context, i) {
                    if (i == state.visibleItems.length) {
                      return Center(
                        child: state.loadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(TokensSpacing.s),
                                child: CircularProgressIndicator(),
                              )
                            : TextButton(
                                onPressed: () => bloc.add(
                                  const DeadlinesEvent.moreRequested(),
                                ),
                                child: Text(l10n.plannerLoadMore),
                              ),
                      );
                    }
                    final d = state.visibleItems[i];
                    return _DeadlineTile(
                      deadline: d,
                      subjectName: state.subjectName(d.subjectId),
                      busy: state.busyIds.contains(d.id),
                      onToggle: () =>
                          bloc.add(DeadlinesEvent.completionToggled(d.id)),
                      onEdit: () => _openForm(context, deadline: d),
                      onDelete: () {
                        FocusScope.of(context).nextFocus();
                        bloc.add(DeadlinesEvent.deleted(d.id));
                      },
                    );
                  },
                ),
        );
    }
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state});

  final DeadlinesState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<DeadlinesBloc>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        TokensSpacing.s,
        TokensSpacing.m,
        0,
      ),
      child: Wrap(
        spacing: TokensSpacing.s,
        runSpacing: TokensSpacing.s,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: true,
                label: Text(l10n.plannerFilterPending),
              ),
              ButtonSegment(value: false, label: Text(l10n.plannerFilterAll)),
            ],
            selected: {state.pendingOnly},
            onSelectionChanged: (s) =>
                bloc.add(DeadlinesEvent.pendingFilterChanged(s.first)),
          ),
          if (state.subjects.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: DropdownButtonFormField<String?>(
                initialValue: state.subjectId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.plannerFieldSubject,
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.plannerFilterSubjectAll),
                  ),
                  for (final s in state.subjects)
                    DropdownMenuItem(value: s.id, child: Text(s.name)),
                ],
                onChanged: (v) =>
                    bloc.add(DeadlinesEvent.subjectFilterChanged(v)),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeadlineTile extends StatelessWidget {
  const _DeadlineTile({
    required this.deadline,
    required this.subjectName,
    required this.busy,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Deadline deadline;
  final String? subjectName;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final d = deadline;
    final overdue = d.timeStatus == ItemTimeStatus.missed;
    final accent = d.type == DeadlineType.exam
        ? context.colors.error
        : context.colors.tertiary;
    return AppCard(
      onTap: onEdit,
      padding: const EdgeInsets.symmetric(
        horizontal: TokensSpacing.s,
        vertical: TokensSpacing.s,
      ),
      child: Row(
        children: [
          busy
              ? const SizedBox.square(
                  dimension: 48,
                  child: Padding(
                    padding: EdgeInsets.all(TokensSpacing.m - 2),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip: d.completed
                      ? l10n.plannerMarkUndone
                      : l10n.plannerMarkDone,
                  onPressed: onToggle,
                  icon: Icon(
                    d.completed
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: d.completed
                        ? context.palette.success
                        : context.colors.onSurfaceVariant,
                  ),
                ),
          const SizedBox(width: TokensSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(d.type.icon, size: 16, color: accent),
                    const SizedBox(width: TokensSpacing.xs),
                    Expanded(
                      child: Text(
                        d.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleSmall?.copyWith(
                          decoration: d.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TokensSpacing.xxs),
                Text(
                  [
                    d.type.label(context),
                    ?subjectName,
                    l10n.plannerDueOn(PlannerFormats.dateTime(d.dueAt)),
                  ].join(' · '),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: TokensSpacing.xs),
                Wrap(
                  spacing: TokensSpacing.xs,
                  runSpacing: TokensSpacing.xs,
                  children: [
                    _Tag(
                      icon: Icons.signal_cellular_alt_rounded,
                      label: d.difficulty.label(context),
                      color: context.colors.onSurfaceVariant,
                    ),
                    if (overdue)
                      _Tag(
                        icon: Icons.error_outline_rounded,
                        label: l10n.plannerOverdue,
                        color: context.colors.error,
                      ),
                    if (d.imported)
                      _Tag(
                        icon: Icons.cloud_download_outlined,
                        label: l10n.plannerImported,
                        color: context.colors.primary,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.commonDelete,
            onPressed: busy ? null : onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TokensSpacing.s,
        vertical: TokensSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(TokensRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: TokensSpacing.xxs),
          Text(label, style: context.textStyles.labelSmall),
        ],
      ),
    );
  }
}
