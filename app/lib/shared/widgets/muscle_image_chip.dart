import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/sv_colors.dart';

class MuscleImageChip extends StatelessWidget {
  const MuscleImageChip({
    required this.label,
    this.urlImagen,
    this.color = SVColors.primary,
    this.compact = false,
    super.key,
  });

  final String label;
  final String? urlImagen;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showImage = urlImagen != null && urlImagen!.isNotEmpty;
    final avatarRadius = compact ? 10.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showImage
            ? 4
            : compact
                ? 8
                : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showImage)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: SVColors.surfaceContainerHighest,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: urlImagen!,
                    width: avatarRadius * 2,
                    height: avatarRadius * 2,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Icon(
                      Icons.sports_gymnastics_rounded,
                      size: avatarRadius,
                      color: color.withValues(alpha: 0.5),
                    ),
                    errorWidget: (_, __, ___) => Icon(
                      Icons.sports_gymnastics_rounded,
                      size: avatarRadius,
                      color: color.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            )
          else
            Icon(
              Icons.sports_gymnastics_rounded,
              size: compact ? 11 : 13,
              color: color.withValues(alpha: 0.7),
            ),
          if (showImage || !compact) const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.85),
                letterSpacing: 0.3,
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
