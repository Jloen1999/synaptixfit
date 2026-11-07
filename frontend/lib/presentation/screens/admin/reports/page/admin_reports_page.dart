import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/admin/admin_report_type.dart';
import '../../../../../domain/models/admin/reported_content.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/admin_dialogs.dart';
import '../../widgets/admin_labels.dart';
import '../../widgets/admin_status.dart';
import '../../widgets/admin_widgets.dart';
import '../bloc/admin_reports_bloc.dart';

/// Ruta del módulo social para abrir una publicación.
String _socialPostPath(String postId) => '/social/posts/$postId';

/// Pestaña Contenido: cola de moderación.
class AdminReportsTab extends StatelessWidget {
  const AdminReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<AdminReportsBloc>()..add(const AdminReportsEvent.started()),
      child: const _AdminReportsView(),
    );
  }
}

class _AdminReportsView extends StatelessWidget with ErrorsMessageMixin {
  const _AdminReportsView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<AdminReportsBloc, AdminReportsState>(
      listenWhen: (a, b) => a.effect != b.effect && b.effect != null,
      listener: (context, state) => context.showSnack(switch (state.effect!) {
        AdminReportsDismissedEffect() => l10n.adminReportsDismissed,
        AdminReportsRemovedEffect() => l10n.adminReportsRemoved,
        AdminReportsFailureEffect(:final error) => errorMessage(context, error),
      }),
      builder: (context, state) {
        final bloc = context.read<AdminReportsBloc>();
        return AdminContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TokensSpacing.m,
                  TokensSpacing.m,
                  TokensSpacing.m,
                  0,
                ),
                child: Wrap(
                  spacing: TokensSpacing.s,
                  children: [
                    for (final type in <AdminReportType?>[
                      null,
                      ...AdminReportType.values,
                    ])
                      ChoiceChip(
                        avatar: type == null ? null : Icon(type.icon, size: 18),
                        label: Text(type?.label(l10n) ?? l10n.adminReportsAll),
                        selected: state.type == type,
                        onSelected: (_) =>
                            bloc.add(AdminReportsEvent.typeChanged(type)),
                      ),
                  ],
                ),
              ),
              Expanded(child: _buildList(context, state)),
              if (state.reports != null && state.reports!.totalItems > 0)
                AdminPaginationBar(
                  page: state.reports!.page,
                  totalPages: state.reports!.totalPages,
                  totalItems: state.reports!.totalItems,
                  onPageSelected: (page) =>
                      bloc.add(AdminReportsEvent.pageRequested(page)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, AdminReportsState state) {
    final l10n = context.localizations;
    final bloc = context.read<AdminReportsBloc>();
    if (state.status == AdminStatus.failure) {
      return AppErrorView(
        error: state.error!,
        onRetry: () => bloc.add(const AdminReportsEvent.refreshed()),
      );
    }
    final reports = state.reports;
    if (reports == null) return const AppSkeletonList(count: 6, height: 120);
    Future<void> refresh() async {
      bloc.add(const AdminReportsEvent.refreshed());
      await bloc.stream.firstWhere((s) => !s.status.isLoading);
    }

    if (reports.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          children: [
            AppEmptyState(
              icon: Icons.verified_user_outlined,
              title: l10n.adminReportsEmptyTitle,
              message: l10n.adminReportsEmptyMessage,
              action: AppSecondaryButton(
                label: l10n.adminRefresh,
                onPressed: () => bloc.add(const AdminReportsEvent.refreshed()),
              ),
            ),
          ],
        ),
      );
    }
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(TokensSpacing.m),
            itemCount: reports.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: TokensSpacing.s),
            itemBuilder: (context, index) {
              final item = reports.items[index];
              return _ReportCard(item: item, busy: state.busyId == item.id);
            },
          ),
        ),
        if (state.status.isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.item, required this.busy});

  final ReportedContent item;
  final bool busy;

  Future<void> _showContent(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(item.type.label(context.localizations)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(child: SelectableText(item.content)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.localizations.commonClose),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final colors = context.colors;
    final bloc = context.read<AdminReportsBloc>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppPill(
                label: item.type.label(l10n),
                color: colors.error,
                icon: item.type.icon,
              ),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                child: Text(
                  item.authorName ?? l10n.adminReportsUnknownAuthor,
                  style: context.textStyles.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                AdminFormat.dateTime(item.createdAt),
                style: context.textStyles.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          Text(
            item.content,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodyMedium,
          ),
          const SizedBox(height: TokensSpacing.s),
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.xs,
            alignment: WrapAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showContent(context),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: Text(l10n.adminReportsView),
              ),
              if (item.postId != null)
                TextButton.icon(
                  onPressed: () => context.push(_socialPostPath(item.postId!)),
                  icon: const Icon(AppIcons.openExternal, size: 18),
                  label: Text(l10n.adminReportsOpenPost),
                ),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        final ok = await showAdminConfirmDialog(
                          context,
                          title: l10n.adminReportsDismiss,
                          message: l10n.adminReportsDismissConfirm,
                          confirmLabel: l10n.adminReportsDismiss,
                        );
                        if (ok) {
                          bloc.add(AdminReportsEvent.dismissRequested(item));
                        }
                      },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(l10n.adminReportsDismiss),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                ),
                onPressed: busy
                    ? null
                    : () async {
                        final ok = await showAdminConfirmDialog(
                          context,
                          title: l10n.adminReportsRemove,
                          message: l10n.adminReportsRemoveConfirm,
                          confirmLabel: l10n.commonDelete,
                          destructive: true,
                        );
                        if (ok) {
                          bloc.add(AdminReportsEvent.removeRequested(item));
                        }
                      },
                icon: busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(AppIcons.delete, size: 18),
                label: Text(l10n.adminReportsRemove),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
