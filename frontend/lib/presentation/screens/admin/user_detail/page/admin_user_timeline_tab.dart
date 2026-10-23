import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/models/admin/admin_user_stats.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/admin_labels.dart';
import '../../widgets/admin_widgets.dart';
import '../bloc/admin_user_detail_bloc.dart';

/// Sub-pestaña Timeline: eventos del usuario, paginados con «Cargar más».
class AdminUserTimelineTab extends StatelessWidget {
  const AdminUserTimelineTab({super.key, required this.state});

  final AdminUserDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<AdminUserDetailBloc>();
    final entries = state.timeline;
    if (entries.isEmpty) {
      if (state.timelineError != null) {
        return AppErrorView(
          error: state.timelineError!,
          onRetry: () =>
              bloc.add(const AdminUserDetailEvent.timelineMoreRequested()),
        );
      }
      return AppEmptyState(
        icon: Icons.timeline_rounded,
        title: l10n.adminTimelineEmpty,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(TokensSpacing.m),
      itemCount: entries.length + 1,
      itemBuilder: (context, index) {
        if (index == entries.length) {
          return AdminContentWidth(child: _Footer(state: state));
        }
        return AdminContentWidth(
          child: _TimelineRow(
            entry: entries[index],
            isLast: index == entries.length - 1,
          ),
        );
      },
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.isLast});

  final AdminTimelineEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final colors = context.colors;
    final color = entry.type.color(colors);
    final typeLabel = entry.type.label(l10n);
    final title = entry.title;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Semantics(
                  label: typeLabel,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withValues(alpha: 0.14),
                    child: Icon(entry.type.icon, size: 18, color: color),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: colors.outlineVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(width: TokensSpacing.s),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: TokensSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title == null || title.isEmpty ? typeLabel : title,
                    style: context.textStyles.titleSmall,
                  ),
                  Text(
                    [
                      typeLabel,
                      AdminFormat.dateTime(entry.occurredAt),
                      if (entry.value != null)
                        l10n.adminTimelineValue(entry.value!),
                    ].join(' · '),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
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

class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final AdminUserDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    if (state.timelineLoading) {
      return const Padding(
        padding: EdgeInsets.all(TokensSpacing.m),
        child: AppLoadingView(),
      );
    }
    if (state.timelineError != null || state.timelineHasMore) {
      return Center(
        child: Column(
          children: [
            if (state.timelineError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: TokensSpacing.xs),
                child: Text(
                  l10n.adminTimelineLoadError,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ),
            AppSecondaryButton(
              label: l10n.adminTimelineLoadMore,
              onPressed: () => context.read<AdminUserDetailBloc>().add(
                const AdminUserDetailEvent.timelineMoreRequested(),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(TokensSpacing.m),
      child: Center(
        child: Text(
          l10n.adminTimelineEnd,
          style: context.textStyles.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
