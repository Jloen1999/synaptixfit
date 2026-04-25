import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    required this.title,
    required this.description,
    required this.priority,
    this.type,
    this.isRead = false,
    this.actionLabel,
    this.onTap,
    this.onAction,
    super.key,
  });

  final String title;
  final String description;
  final String priority;
  final String? type;
  final bool isRead;
  final String? actionLabel;
  final VoidCallback? onTap;
  final VoidCallback? onAction;

  IconData get _typeIcon => switch (type) {
        'conflict' => Icons.warning_amber_rounded,
        'fatigue_alert' => Icons.bolt_rounded,
        'milestone' => Icons.emoji_events_rounded,
        'social' => Icons.group_rounded,
        'academic' => Icons.school_rounded,
        _ => Icons.notifications_active_rounded,
      };

  Color _priorityColor(BuildContext context) => switch (priority) {
        'critical' => const Color(0xFFBA1A1A),
        'recommended' => const Color(0xFFE65100),
        _ => Theme.of(context).colorScheme.primary,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _priorityColor(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isRead
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
              : color.withValues(alpha: 0.3),
        ),
      ),
      color: isRead
          ? theme.colorScheme.surface
          : color.withValues(alpha: 0.04),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícono con badge de no leída
              Stack(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_typeIcon, color: color, size: 22),
                  ),
                  if (!isRead)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                        color: isRead
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 30,
                        child: OutlinedButton(
                          onPressed: onAction,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            side: BorderSide(color: color.withValues(alpha: 0.5)),
                            foregroundColor: color,
                          ),
                          child: Text(actionLabel!),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
