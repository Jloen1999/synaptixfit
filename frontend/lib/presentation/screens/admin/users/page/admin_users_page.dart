import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/admin/admin_sort_direction.dart';
import '../../../../../domain/enums/admin/admin_user_sort.dart';
import '../../../../../domain/enums/user_role.dart';
import '../../../../../domain/models/admin/admin_queries.dart';
import '../../../../../domain/models/admin/admin_user.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../admin_routes.dart';
import '../../widgets/admin_labels.dart';
import '../../widgets/admin_status.dart';
import '../../widgets/admin_widgets.dart';
import '../bloc/admin_users_bloc.dart';
import 'admin_user_filters_sheet.dart';

/// Pestaña Usuarios del panel.
class AdminUsersTab extends StatelessWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<AdminUsersBloc>()..add(const AdminUsersEvent.started()),
      child: const _AdminUsersView(),
    );
  }
}

class _AdminUsersView extends StatefulWidget {
  const _AdminUsersView();

  @override
  State<_AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<_AdminUsersView> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  AdminUsersBloc get _bloc => context.read<AdminUsersBloc>();

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _bloc.add(
        AdminUsersEvent.queryChanged(_bloc.state.query.copyWith(text: text)),
      );
    });
  }

  Future<void> _openFilters(AdminUserQuery query) async {
    final result = await showAdminUserFiltersSheet(context, query);
    if (result != null && mounted) {
      _bloc.add(AdminUsersEvent.queryChanged(result));
    }
  }

  Future<void> _openUser(AdminUserSummary user) async {
    await context.push(AdminPaths.userDetail(user.id));
    if (mounted) _bloc.add(const AdminUsersEvent.refreshed());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<AdminUsersBloc, AdminUsersState>(
      builder: (context, state) {
        final query = state.query;
        return AdminContentWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TokensSpacing.m,
                  TokensSpacing.m,
                  TokensSpacing.m,
                  TokensSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: _onSearchChanged,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          labelText: l10n.adminUsersSearchHint,
                          prefixIcon: const Icon(AppIcons.search),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: TokensSpacing.s),
                    _FilterButton(
                      activeCount: _activeFilters(query),
                      onPressed: () => _openFilters(query),
                    ),
                  ],
                ),
              ),
              _SortBar(query: query),
              Expanded(child: _buildList(context, state)),
              if (state.users != null && state.users!.totalItems > 0)
                AdminPaginationBar(
                  page: state.users!.page,
                  totalPages: state.users!.totalPages,
                  totalItems: state.users!.totalItems,
                  onPageSelected: (page) =>
                      _bloc.add(AdminUsersEvent.pageRequested(page)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, AdminUsersState state) {
    final l10n = context.localizations;
    if (state.status == AdminStatus.failure) {
      return AppErrorView(
        error: state.error!,
        onRetry: () => _bloc.add(const AdminUsersEvent.refreshed()),
      );
    }
    final users = state.users;
    if (users == null || (state.status.isLoading && users.items.isEmpty)) {
      return const AppSkeletonList(count: 6);
    }
    if (users.items.isEmpty) {
      return AppEmptyState(
        icon: Icons.person_search_outlined,
        title: l10n.adminUsersEmptyTitle,
        message: l10n.adminUsersEmptyMessage,
        action: AppSecondaryButton(
          label: l10n.adminFiltersClear,
          onPressed: () {
            _search.clear();
            _bloc.add(const AdminUsersEvent.queryChanged(AdminUserQuery()));
          },
        ),
      );
    }
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            _bloc.add(const AdminUsersEvent.refreshed());
            await _bloc.stream.firstWhere((s) => !s.status.isLoading);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(TokensSpacing.m),
            itemCount: users.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: TokensSpacing.s),
            itemBuilder: (context, index) {
              final user = users.items[index];
              return _UserTile(user: user, onTap: () => _openUser(user));
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

  static int _activeFilters(AdminUserQuery q) => [
    q.role != null,
    q.shadowbanned != null,
    q.status != const AdminUserQuery().status,
    q.minLevel != null || q.maxLevel != null,
  ].where((active) => active).length;
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onPressed});

  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: activeCount > 0,
      label: Text('$activeCount'),
      child: IconButton.outlined(
        tooltip: context.localizations.adminFiltersTitle,
        onPressed: onPressed,
        icon: const Icon(AppIcons.filters),
      ),
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({required this.query});

  final AdminUserQuery query;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<AdminUsersBloc>();
    final ascending = query.direction == AdminSortDirection.asc;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.m),
      child: Row(
        children: [
          Text(l10n.adminSortLabel, style: context.textStyles.labelMedium),
          const SizedBox(width: TokensSpacing.s),
          DropdownButton<AdminUserSort>(
            value: query.sort,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(TokensRadius.m),
            items: [
              for (final sort in AdminUserSort.values)
                DropdownMenuItem(value: sort, child: Text(sort.label(l10n))),
            ],
            onChanged: (sort) {
              if (sort == null) return;
              bloc.add(
                AdminUsersEvent.queryChanged(query.copyWith(sort: sort)),
              );
            },
          ),
          IconButton(
            tooltip: ascending
                ? l10n.adminSortAscending
                : l10n.adminSortDescending,
            onPressed: () => bloc.add(
              AdminUsersEvent.queryChanged(
                query.copyWith(
                  direction: ascending
                      ? AdminSortDirection.desc
                      : AdminSortDirection.asc,
                ),
              ),
            ),
            icon: Icon(
              ascending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onTap});

  final AdminUserSummary user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final colors = context.colors;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          AppAvatar(name: user.fullName, imageUrl: user.avatarUrl),
          const SizedBox(width: TokensSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: context.textStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user.email,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: TokensSpacing.xs),
                Wrap(
                  spacing: TokensSpacing.xs,
                  runSpacing: TokensSpacing.xs,
                  children: [
                    AppPill(
                      label: l10n.commonLevel(user.level),
                      color: context.palette.accent,
                      icon: Icons.star_rounded,
                    ),
                    if (user.role == UserRole.admin)
                      AppPill(
                        label: UserRole.admin.adminLabel(l10n),
                        color: colors.primary,
                        icon: Icons.admin_panel_settings_outlined,
                      ),
                    if (user.shadowbanned)
                      AppPill(
                        label: l10n.adminTagShadowban,
                        color: context.palette.warning,
                        icon: Icons.visibility_off_outlined,
                      ),
                    if (user.deleted)
                      AppPill(
                        label: l10n.adminTagDeleted,
                        color: colors.error,
                        icon: Icons.block_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: TokensSpacing.s),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.adminUsersTotalXp(AdminFormat.number(user.totalXp)),
                style: context.textStyles.labelLarge,
              ),
              Text(
                l10n.adminUsersStreak(user.streak),
                style: context.textStyles.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                AdminFormat.date(user.createdAt),
                style: context.textStyles.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Icon(AppIcons.next),
        ],
      ),
    );
  }
}
