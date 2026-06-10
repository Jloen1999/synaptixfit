import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/sv_colors.dart';
import 'muscle_image_chip.dart';

class ExerciseGridCard extends StatelessWidget {
  const ExerciseGridCard({
    required this.nombre,
    required this.muscleGroup,
    this.equipment,
    this.previewUrl,
    this.muscleImageUrl,
    this.isSelected = false,
    this.onTap,
    this.onAdd,
    super.key,
  });

  final String nombre;
  final String muscleGroup;
  final String? equipment;
  final String? previewUrl;
  final String? muscleImageUrl;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  static const _previewHeight = 132.0;
  static const _previewBg = Color(0xFF1A1A1E);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? SVColors.primary.withValues(alpha: 0.5)
              : SVColors.outlineVariant.withValues(alpha: 0.25),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPreview(context),
            Expanded(child: _buildInfo(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return SizedBox(
      height: _previewHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: _previewBg),
          if (previewUrl != null && previewUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: previewUrl!,
              fit: BoxFit.contain,
              placeholder: (_, __) => _buildLoading(),
              errorWidget: (_, __, ___) => _buildFallback(),
            )
          else
            _buildFallback(),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x22000000),
                      Colors.transparent,
                      Colors.transparent,
                      Color(0x18000000),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onAdd != null)
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: isSelected
                    ? SVColors.primary.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      isSelected ? Icons.check_rounded : Icons.add_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfo(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nombre,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Flexible(
            child: _buildTags(),
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        MuscleImageChip(
          label: muscleGroup,
          urlImagen: muscleImageUrl,
          color: SVColors.primary,
          compact: true,
        ),
        if (equipment != null && equipment!.isNotEmpty)
          _EquipmentTag(label: equipment!),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: SVColors.outlineVariant,
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: _previewBg,
      child: Center(
        child: Icon(
          Icons.fitness_center_rounded,
          size: 44,
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

class _EquipmentTag extends StatelessWidget {
  const _EquipmentTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: SVColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 12,
            color: SVColors.secondary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: SVColors.secondary.withValues(alpha: 0.85),
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
