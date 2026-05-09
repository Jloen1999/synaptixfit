import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/design_system/sv_colors.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    required this.name,
    required this.muscleGroup,
    this.equipment,
    this.gifUrl,
    this.onTap,
    super.key,
  });

  final String name;
  final String muscleGroup;
  final String? equipment;
  final String? gifUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: SVColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Miniatura del GIF — más grande y con bordes curvos
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: gifUrl != null
                      ? CachedNetworkImage(
                          imageUrl: gifUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: SVColors.surfaceContainerHighest,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: SVColors.surfaceContainerHighest,
                            child: const Icon(
                              Icons.fitness_center_rounded,
                              size: 24,
                              color: SVColors.onSurfaceMuted,
                            ),
                          ),
                        )
                      : Container(
                          color: SVColors.surfaceContainerHighest,
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            size: 24,
                            color: SVColors.onSurfaceMuted,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Tag(
                          label: muscleGroup,
                          icon: Icons.sports_gymnastics_rounded,
                          color: SVColors.primary,
                        ),
                        if (equipment != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: _Tag(
                              label: equipment!,
                              icon: Icons.fitness_center_rounded,
                              color: SVColors.secondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: SVColors.onSurfaceMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.85),
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
