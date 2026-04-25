import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/design_system/sv_colors.dart';

/// Tarjeta reutilizable para mostrar un ejercicio en listas y grids.
/// Muestra una miniatura GIF, nombre, músculo objetivo y equipamiento.
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Miniatura del GIF
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: gifUrl == null
                    ? Container(
                        width: 64,
                        height: 64,
                        color: SVColors.surfaceContainerHighest,
                        child: Icon(Icons.fitness_center,
                            color: SVColors.onSurfaceVariant),
                      )
                    : CachedNetworkImage(
                        imageUrl: gifUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 64,
                          height: 64,
                          color: SVColors.surfaceContainerHighest,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: SVColors.surfaceContainerHighest,
                          child: Icon(Icons.fitness_center,
                              color: SVColors.onSurfaceVariant),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Info del ejercicio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(muscleGroup,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: SVColors.onSurfaceVariant,
                            )),
                    if (equipment != null) ...[
                      const SizedBox(height: 2),
                      Text(equipment!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: SVColors.onSurfaceVariant,
                                  )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
