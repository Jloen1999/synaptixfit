import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../widgets/notification_texts.dart';
import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/notification_priority.dart';
import '../../../../../domain/enums/notification_type.dart';
import '../../../../../domain/models/social/app_notification.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/social_dialogs.dart';
import '../../widgets/social_feedback.dart';
import '../../widgets/social_format.dart';
import '../../social_routes.dart';
import '../../widgets/social_layout.dart';
import '../bloc/notifications_bloc.dart';

/// Bandeja de notificaciones (`/notifications`).
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<NotificationsBloc>()..add(const NotificationsEvent.started()),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  void _open(BuildContext context, AppNotification notification) {
    context.read<NotificationsBloc>().add(
      NotificationsEvent.opened(notification.id),
    );
    final url = notification.actionUrl;
    // Solo rutas internas de la app (p. ej. /social/posts/{id}).
    if (url == null || !url.startsWith('/')) return;
    if (SocialExternalPaths.isTabRoot(url)) {
      context.go(url);
    } else {
      context.push<void>(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<NotificationsBloc>();
    return BlocConsumer<NotificationsBloc, NotificationsState>(
      listenWhen: (_, current) => current.feedback != null,
      listener: (context, state) =>
          showSocialFeedback(context, state.feedback!),
      builder: (context, state) => Scaffold(
        appBar: AppPageBar.reading(
          title: Text(l10n.socialNotificationsTitle),
          actions: [
            if (state.markingAll)
              const Padding(
                padding: EdgeInsets.all(TokensSpacing.m),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: l10n.socialNotificationsMarkAllRead,
                icon: const Icon(Icons.done_all_rounded),
                onPressed: state.hasUnread
                    ? () => bloc.add(const NotificationsEvent.allMarkedRead())
                    : null,
              ),
          ],
        ),
        body: SocialContentWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TokensSpacing.m,
                  TokensSpacing.s,
                  TokensSpacing.m,
                  0,
                ),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text(l10n.socialNotificationsFilterAll),
                      selected: !state.unreadOnly,
                      onSelected: (_) => bloc.add(
                        const NotificationsEvent.filterChanged(
                          unreadOnly: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: TokensSpacing.s),
                    ChoiceChip(
                      label: Text(l10n.socialNotificationsFilterUnread),
                      selected: state.unreadOnly,
                      onSelected: (_) => bloc.add(
                        const NotificationsEvent.filterChanged(
                          unreadOnly: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _body(context, state)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, NotificationsState state) {
    final l10n = context.localizations;
    final bloc = context.read<NotificationsBloc>();
    return switch (state.status) {
      SocialLoadStatus.loading => const SocialListSkeleton(
        itemHeight: 76,
        count: 6,
      ),
      SocialLoadStatus.failure => AppErrorView(
        error: state.error!,
        onRetry: () => bloc.add(const NotificationsEvent.started()),
      ),
      SocialLoadStatus.loaded => RefreshIndicator(
        onRefresh: () async {
          bloc.add(const NotificationsEvent.refreshed());
          await bloc.stream
              .skipWhile((s) => !s.refreshing)
              .firstWhere((s) => !s.refreshing);
        },
        child: state.items.isEmpty
            ? LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: AppEmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: state.unreadOnly
                          ? l10n.socialNotificationsEmptyUnread
                          : l10n.socialNotificationsEmpty,
                      message: l10n.socialNotificationsEmptyMessage,
                      action: state.unreadOnly
                          ? AppSecondaryButton(
                              label: l10n.socialNotificationsFilterAll,
                              onPressed: () => bloc.add(
                                const NotificationsEvent.filterChanged(
                                  unreadOnly: false,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              )
            : NotificationListener<ScrollNotification>(
                onNotification: (n) => onScrollNearEnd(
                  n,
                  () => bloc.add(const NotificationsEvent.nextPageRequested()),
                ),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(TokensSpacing.m),
                  itemCount: state.items.length + (state.loadingMore ? 1 : 0),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: TokensSpacing.s),
                  itemBuilder: (context, index) {
                    if (index >= state.items.length) {
                      return const LoadMoreIndicator();
                    }
                    final notification = state.items[index];
                    return Dismissible(
                      key: ValueKey(notification.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => confirmSocialAction(
                        context,
                        title: l10n.socialNotificationDeleteTitle,
                        message: l10n.socialNotificationDeleteMessage,
                        confirmLabel: l10n.commonDelete,
                      ),
                      onDismissed: (_) =>
                          bloc.add(NotificationsEvent.deleted(notification.id)),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: TokensSpacing.l,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.errorContainer,
                          borderRadius: BorderRadius.circular(TokensRadius.l),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: context.colors.onErrorContainer,
                          semanticLabel: l10n.commonDelete,
                        ),
                      ),
                      child: _NotificationTile(
                        notification: notification,
                        onTap: () => _open(context, notification),
                      ),
                    );
                  },
                ),
              ),
      ),
    };
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  IconData get _icon => switch (notification.type) {
    NotificationType.conflict => Icons.event_busy_rounded,
    NotificationType.fatigueAlert => Icons.battery_alert_rounded,
    NotificationType.milestone => Icons.emoji_events_rounded,
    NotificationType.social => Icons.people_alt_rounded,
    NotificationType.academic => Icons.school_rounded,
  };

  String _typeLabel(BuildContext context) {
    final l10n = context.localizations;
    return switch (notification.type) {
      NotificationType.conflict => l10n.socialNotificationTypeConflict,
      NotificationType.fatigueAlert => l10n.socialNotificationTypeFatigue,
      NotificationType.milestone => l10n.socialNotificationTypeMilestone,
      NotificationType.social => l10n.socialNotificationTypeSocial,
      NotificationType.academic => l10n.socialNotificationTypeAcademic,
    };
  }

  Color _color(BuildContext context) => switch (notification.type) {
    NotificationType.conflict => context.palette.warning,
    NotificationType.fatigueAlert => context.palette.calories,
    NotificationType.milestone => context.palette.accent,
    NotificationType.social => context.colors.primary,
    NotificationType.academic => context.palette.study,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final texts = notificationTexts(l10n, notification);
    final color = _color(context);
    final unread = !notification.read;
    final priority = notification.priority;
    return Semantics(
      label: unread ? l10n.socialNotificationUnread : null,
      child: AppCard(
        onTap: onTap,
        color: unread ? context.colors.surfaceContainerLow : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(TokensSpacing.s),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(TokensRadius.m),
              ),
              child: Icon(
                _icon,
                color: color,
                size: 22,
                semanticLabel: _typeLabel(context),
              ),
            ),
            const SizedBox(width: TokensSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          texts.title,
                          style: context.textStyles.titleSmall?.copyWith(
                            fontWeight: unread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: context.colors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (texts.description != null) ...[
                    const SizedBox(height: TokensSpacing.xxs),
                    Text(
                      texts.description!,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: TokensSpacing.xs),
                  Wrap(
                    spacing: TokensSpacing.s,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        socialTimeAgo(l10n, notification.createdAt),
                        style: context.textStyles.labelSmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      if (priority != NotificationPriority.informative)
                        _PriorityLabel(priority: priority),
                      if (texts.action != null &&
                          notification.actionUrl != null)
                        Text(
                          texts.action!,
                          style: context.textStyles.labelMedium?.copyWith(
                            color: context.colors.primary,
                          ),
                        ),
                    ],
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

class _PriorityLabel extends StatelessWidget {
  const _PriorityLabel({required this.priority});

  final NotificationPriority priority;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final critical = priority == NotificationPriority.critical;
    final color = critical ? context.colors.error : context.palette.warning;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          critical ? Icons.priority_high_rounded : Icons.lightbulb_outline,
          size: 14,
          color: color,
        ),
        const SizedBox(width: TokensSpacing.xxs),
        Text(
          critical
              ? l10n.socialNotificationPriorityCritical
              : l10n.socialNotificationPriorityRecommended,
          style: context.textStyles.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
