import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../core/design_system/sv_shapes.dart';
import '../../../../shared/models/db_models.dart';
import '../../application/conteos_asignatura_provider.dart';
import '../../domain/asignatura_visual.dart';

/// Tarjeta plana de asignatura (Clean UI).
///
/// Franja vertical de color semántico, siglas destacadas, nombre completo con
/// ellipsis y métricas rápidas de apuntes y archivos.
class AsignaturaCard extends ConsumerWidget {
  const AsignaturaCard({
    required this.asignatura,
    required this.onTap,
    super.key,
  });

  final AsignaturaDb asignatura;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = colorAsignatura(asignatura.id);
    final siglas = siglasAsignatura(asignatura);
    final conteosAsync = ref.watch(conteosAsignaturaProvider(asignatura.id));

    return Material(
      color: SVColors.surfaceContainerLowest,
      borderRadius: SVShapes.large16,
      elevation: 1,
      shadowColor: SVColors.outlineVariant.withValues(alpha: 0.3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: SVShapes.standard,
                        ),
                        child: Text(
                          siglas,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        asignatura.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SVColors.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      conteosAsync.when(
                        loading: () => const Text(
                          'Cargando…',
                          style: TextStyle(
                              color: SVColors.onSurfaceMuted, fontSize: 11.5),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (c) => Text(
                          '${c.apuntes} ${c.apuntes == 1 ? 'apunte' : 'apuntes'} • '
                          '${c.archivos} ${c.archivos == 1 ? 'archivo' : 'archivos'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SVColors.onSurfaceMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
