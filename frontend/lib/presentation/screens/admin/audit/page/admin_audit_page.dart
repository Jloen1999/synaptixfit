import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/admin/admin_audit_action.dart';
import '../../../../../domain/enums/admin/admin_audit_entity.dart';
import '../../../../../domain/models/admin/admin_queries.dart';
import '../../../../../domain/models/admin/audit_entry.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../admin_routes.dart';
import '../../widgets/admin_labels.dart';
import '../../widgets/admin_status.dart';
import '../../widgets/admin_widgets.dart';
import '../bloc/admin_audit_bloc.dart';

/// Pestaña Auditoría del panel.
class AdminAuditTab extends StatelessWidget {
  const AdminAuditTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<AdminAuditBloc>()..add(const AdminAuditEvent.started()),
      child: const _AdminAuditView(),
    );
  }
}

class _AdminAuditView extends StatelessWidget {
  const _AdminAuditView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminAuditBloc, AdminAuditState>(
      builder: (context, state) {
        final bloc = context.read<AdminAuditBloc>();
        return AdminContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Filters(query: state.query),
              Expanded(child: _buildList(context, state)),
              if (state.entries != null && state.entries!.totalItems > 0)
                AdminPaginationBar(
                  page: state.entries!.page,
                  totalPages: state.entries!.totalPages,
                  totalItems: state.entries!.totalItems,
                  onPageSelected: (page) =>
                      bloc.add(AdminAuditEvent.pageRequested(page)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, AdminAuditState state) {
    final l10n = context.localizations;
    final bloc = context.read<AdminAuditBloc>();
    if (state.status == AdminStatus.failure) {
      return AppErrorView(
        error: state.error!,
        onRetry: () => bloc.add(const AdminAuditEvent.refreshed()),
      );
    }
    final entries = state.entries;
    if (entries == null) return const AppSkeletonList(count: 6, height: 64);
    if (entries.items.isEmpty) {
      return AppEmptyState(
        icon: Icons.history_toggle_off_rounded,
        title: l10n.adminAuditEmptyTitle,
        message: l10n.adminAuditEmptyMessage,
        action: state.query == const AuditQuery()
            ? null
            : AppSecondaryButton(
                label: l10n.adminFiltersClear,
                onPressed: () =>
                    bloc.add(const AdminAuditEvent.queryChanged(AuditQuery())),
              ),
      );
    }
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            bloc.add(const AdminAuditEvent.refreshed());
            await bloc.stream.firstWhere((s) => !s.status.isLoading);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(TokensSpacing.m),
            itemCount: entries.items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: TokensSpacing.xs),
            itemBuilder: (context, index) =>
                _AuditTile(entry: entries.items[index]),
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

class _Filters extends StatelessWidget {
  const _Filters({required this.query});

  final AuditQuery query;

  Future<void> _pickRange(BuildContext context) async {
    final bloc = context.read<AdminAuditBloc>();
    final now = DateTime.now();
    final from = query.from;
    final to = query.to;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: from == null || to == null
          ? null
          : DateTimeRange(
              start: from,
              end: to.subtract(const Duration(days: 1)),
            ),
    );
    if (range == null) return;
    // `to` es exclusivo en la API: se toma hasta el final del último día.
    bloc.add(
      AdminAuditEvent.queryChanged(
        query.copyWith(
          from: range.start,
          to: DateTime(range.end.year, range.end.month, range.end.day + 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<AdminAuditBloc>();
    final from = query.from;
    final to = query.to;
    final hasFilters = query != const AuditQuery();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        TokensSpacing.m,
        TokensSpacing.m,
        0,
      ),
      child: Row(
        children: [
          _Menu<AdminAuditAction>(
            label: l10n.adminAuditFilterAction,
            value: query.action,
            values: AdminAuditAction.values,
            itemLabel: (v) => v.label(l10n),
            onChanged: (v) => bloc.add(
              AdminAuditEvent.queryChanged(
                AuditQuery(
                  action: v,
                  entityType: query.entityType,
                  entityId: query.entityId,
                  from: from,
                  to: to,
                ),
              ),
            ),
          ),
          const SizedBox(width: TokensSpacing.s),
          _Menu<AdminAuditEntity>(
            label: l10n.adminAuditFilterEntity,
            value: query.entityType,
            values: AdminAuditEntity.values,
            itemLabel: (v) => v.label(l10n),
            onChanged: (v) => bloc.add(
              AdminAuditEvent.queryChanged(
                AuditQuery(
                  action: query.action,
                  entityType: v,
                  entityId: query.entityId,
                  from: from,
                  to: to,
                ),
              ),
            ),
          ),
          const SizedBox(width: TokensSpacing.s),
          InputChip(
            avatar: const Icon(Icons.date_range_rounded, size: 18),
            label: Text(
              from == null || to == null
                  ? l10n.adminAuditFilterDates
                  : l10n.adminAuditDateRange(
                      AdminFormat.date(from),
                      AdminFormat.date(to.subtract(const Duration(days: 1))),
                    ),
            ),
            onPressed: () => _pickRange(context),
            onDeleted: from == null
                ? null
                : () => bloc.add(
                    AdminAuditEvent.queryChanged(
                      AuditQuery(
                        action: query.action,
                        entityType: query.entityType,
                        entityId: query.entityId,
                      ),
                    ),
                  ),
          ),
          if (hasFilters) ...[
            const SizedBox(width: TokensSpacing.s),
            TextButton(
              onPressed: () =>
                  bloc.add(const AdminAuditEvent.queryChanged(AuditQuery())),
              child: Text(l10n.adminFiltersClear),
            ),
          ],
        ],
      ),
    );
  }
}

/// Selector de un enum con opción «Todas» (índice -1).
class _Menu<T extends Enum> extends StatelessWidget {
  const _Menu({
    required this.label,
    required this.value,
    required this.values,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> values;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = value;
    return PopupMenuButton<int>(
      tooltip: label,
      onSelected: (index) => onChanged(index < 0 ? null : values[index]),
      itemBuilder: (_) => [
        PopupMenuItem<int>(
          value: -1,
          child: Text(context.localizations.adminFilterAll),
        ),
        for (var i = 0; i < values.length; i++)
          PopupMenuItem<int>(value: i, child: Text(itemLabel(values[i]))),
      ],
      child: Chip(
        avatar: const Icon(Icons.arrow_drop_down_rounded, size: 18),
        label: Text(current == null ? label : '$label: ${itemLabel(current)}'),
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.entry});

  final AuditEntry entry;

  Future<void> _showDetail(BuildContext context) {
    final l10n = context.localizations;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => _AuditDetailDialog(
        entry: entry,
        onOpenUser:
            entry.entityType == AdminAuditEntity.user && entry.entityId != null
            ? () {
                Navigator.of(dialogContext).pop();
                context.push(AdminPaths.userDetail(entry.entityId!));
              }
            : null,
        title: entry.action.label(l10n),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final colors = context.colors;
    final color = entry.action.isDestructive ? colors.error : colors.primary;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: TokensSpacing.m,
        vertical: TokensSpacing.s,
      ),
      onTap: () => _showDetail(context),
      child: Row(
        children: [
          Icon(
            entry.action.isDestructive
                ? Icons.warning_amber_rounded
                : AppIcons.history,
            color: color,
            size: 20,
          ),
          const SizedBox(width: TokensSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.action.label(l10n),
                  style: context.textStyles.titleSmall,
                ),
                Text(
                  [
                    entry.entityType.label(l10n),
                    l10n.adminAuditBy(
                      entry.adminName ?? entry.adminEmail ?? '—',
                    ),
                  ].join(' · '),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            AdminFormat.dateTime(entry.createdAt),
            style: context.textStyles.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _AuditDetailDialog extends StatelessWidget {
  const _AuditDetailDialog({
    required this.entry,
    required this.title,
    this.onOpenUser,
  });

  final AuditEntry entry;
  final String title;
  final VoidCallback? onOpenUser;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final details = entry.details;
    return AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminKeyValue(
                label: l10n.adminAuditDate,
                value: AdminFormat.dateTime(entry.createdAt),
              ),
              AdminKeyValue(
                label: l10n.adminAuditAdmin,
                value: [?entry.adminName, ?entry.adminEmail].join(' · '),
              ),
              AdminKeyValue(
                label: l10n.adminAuditFilterEntity,
                value: entry.entityType.label(l10n),
              ),
              if (entry.entityId != null)
                AdminKeyValue(label: l10n.adminFieldId, value: entry.entityId!),
              const SizedBox(height: TokensSpacing.s),
              Text(
                l10n.adminAuditDetails,
                style: context.textStyles.labelLarge,
              ),
              const SizedBox(height: TokensSpacing.xs),
              if (details.isEmpty)
                Text(
                  l10n.adminAuditNoDetails,
                  style: context.textStyles.bodySmall,
                )
              else
                for (final MapEntry(:key, :value) in details.entries)
                  _DetailValue(name: key, value: value),
            ],
          ),
        ),
      ),
      actions: [
        if (onOpenUser != null)
          TextButton.icon(
            onPressed: onOpenUser,
            icon: const Icon(Icons.person_outline_rounded),
            label: Text(l10n.adminAuditOpenUser),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  }
}

/// Valor de `details` legible: los objetos y listas se muestran con sangría.
class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.name, required this.value});

  final String name;
  final Object? value;

  static String _format(Object? value, [String indent = '']) {
    final next = '$indent  ';
    return switch (value) {
      null => '—',
      Map() when value.isEmpty => '{}',
      Map() =>
        value.entries
            .map((e) => '\n$next${e.key}: ${_format(e.value, next)}')
            .join(),
      List() when value.isEmpty => '[]',
      List() => value.map((e) => '\n$next• ${_format(e, next)}').join(),
      _ => value.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: TokensSpacing.xs),
      padding: const EdgeInsets.all(TokensSpacing.s),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(TokensRadius.s),
      ),
      child: SelectableText.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$name: ',
              style: context.textStyles.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: _format(value), style: context.textStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
