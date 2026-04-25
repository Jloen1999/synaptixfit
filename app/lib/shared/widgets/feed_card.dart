import 'package:flutter/material.dart';

class FeedCard extends StatelessWidget {
  const FeedCard({
    required this.userName,
    required this.achievement,
    required this.likes,
    required this.comments,
    this.activityType,
    this.timeAgo,
    this.isLiked = false,
    this.onLike,
    this.onComment,
    super.key,
  });

  final String userName;
  final String achievement;
  final int likes;
  final int comments;
  final String? activityType;
  final String? timeAgo;
  final bool isLiked;
  final VoidCallback? onLike;
  final VoidCallback? onComment;

  IconData get _activityIcon => switch (activityType) {
        'session_completed' => Icons.fitness_center_rounded,
        'challenge_completed' => Icons.emoji_events_rounded,
        'milestone_reached' => Icons.flag_rounded,
        'badge_unlocked' => Icons.workspace_premium_rounded,
        _ => Icons.celebration_rounded,
      };

  Color _activityColor(BuildContext context) => switch (activityType) {
        'session_completed' => Theme.of(context).colorScheme.primary,
        'challenge_completed' => const Color(0xFF006E2D),
        'milestone_reached' => const Color(0xFFE65100),
        'badge_unlocked' => const Color(0xFF7B1FA2),
        _ => Theme.of(context).colorScheme.secondary,
      };

  String get _activityLabel => switch (activityType) {
        'session_completed' => 'Sesión completada',
        'challenge_completed' => 'Reto completado',
        'milestone_reached' => 'Hito alcanzado',
        'badge_unlocked' => 'Insignia desbloqueada',
        _ => 'Logro',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _activityColor(context);
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + Nombre + Tipo + Timestamp
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (activityType != null)
                        Row(
                          children: [
                            Icon(_activityIcon, size: 14, color: color),
                            const SizedBox(width: 4),
                            Text(
                              _activityLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (timeAgo != null)
                  Text(
                    timeAgo!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Contenido
            Text(
              achievement,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            // Acciones
            Row(
              children: [
                _ActionButton(
                  icon: isLiked
                      ? Icons.thumb_up_rounded
                      : Icons.thumb_up_alt_outlined,
                  label: '$likes',
                  isActive: isLiked,
                  activeColor: theme.colorScheme.primary,
                  onTap: onLike,
                ),
                const SizedBox(width: 4),
                _ActionButton(
                  icon: Icons.mode_comment_outlined,
                  label: '$comments',
                  onTap: onComment,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined, size: 20),
                  visualDensity: VisualDensity.compact,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.activeColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive
        ? (activeColor ?? theme.colorScheme.primary)
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
