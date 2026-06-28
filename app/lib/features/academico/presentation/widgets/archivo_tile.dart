import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../core/design_system/sv_shapes.dart';
import '../../application/documento_ia_provider.dart';
import '../../domain/archivo_asignatura_dto.dart';
import '../../domain/fuente_estudio.dart';
import '../mapa_mental_screen.dart';
import '../resumen_ia_screen.dart';

/// Fila plana de un archivo ya almacenado (Clean UI) con indicadores de
/// documentos generados por IA (resumen / mapa mental).
///
/// Micro-chip semántico (icono según tipo) + nombre con ellipsis + peso, y
/// acción de eliminar.
class ArchivoTile extends ConsumerWidget {
  const ArchivoTile({
    required this.archivo,
    required this.onAbrir,
    required this.onEliminar,
    super.key,
  });

  final ArchivoAsignaturaDto archivo;
  final VoidCallback onAbrir;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref
        .watch(docsGuardadosProvider((
          fuenteTipo: 'archivo',
          fuenteId: archivo.id,
        )))
        .valueOrNull;
    final tipo = archivo.tipo;
    final tieneResumen = docs?.resumen == true;
    final tieneMapa = docs?.mapa == true;

    return Material(
      color: SVColors.surfaceContainerLowest,
      borderRadius: SVShapes.standard12,
      elevation: 1,
      shadowColor: SVColors.outlineVariant.withValues(alpha: 0.2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAbrir,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tipo.color.withValues(alpha: 0.12),
                  borderRadius: SVShapes.standard,
                ),
                child: Icon(tipo.icono, color: tipo.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      archivo.nombreArchivo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SVColors.onSurface,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      archivo.tamanoLegible,
                      style: const TextStyle(
                        color: SVColors.onSurfaceMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              _iaBadge(Icons.article_outlined, 'Ver resumen',
                  visible: tieneResumen, onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ResumenIaScreen(
                      fuente: FuenteArchivo(
                        titulo: archivo.nombreArchivo,
                        fuenteId: archivo.id,
                        asignaturaId: archivo.asignaturaId,
                        url: archivo.urlPublica,
                        mimeType:
                            archivo.tipoMime ?? 'application/octet-stream',
                      ),
                    ),
                  ),
                );
              }),
              _iaBadge(Icons.account_tree_outlined, 'Ver mapa mental',
                  visible: tieneMapa, onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MapaMentalScreen(
                      fuente: FuenteArchivo(
                        titulo: archivo.nombreArchivo,
                        fuenteId: archivo.id,
                        asignaturaId: archivo.asignaturaId,
                        url: archivo.urlPublica,
                        mimeType:
                            archivo.tipoMime ?? 'application/octet-stream',
                      ),
                    ),
                  ),
                );
              }),
              IconButton(
                onPressed: onEliminar,
                icon: const Icon(Icons.delete_outline,
                    color: SVColors.onSurfaceMuted, size: 20),
                tooltip: 'Eliminar',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila plana de un archivo en proceso de subida (Clean UI).
///
/// `LinearProgressIndicator` integrado con el color semántico del tipo de
/// archivo.
class ArchivoSubiendoTile extends StatelessWidget {
  const ArchivoSubiendoTile({
    required this.nombre,
    required this.progreso,
    super.key,
  });

  final String nombre;
  final double progreso;

  @override
  Widget build(BuildContext context) {
    final tipo = TipoArchivo.desdeNombre(nombre);
    final pct = (progreso.clamp(0.0, 1.0) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SVColors.surfaceContainerLowest,
        borderRadius: SVShapes.standard12,
        boxShadow: [
          BoxShadow(
            color: SVColors.outlineVariant.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tipo.color.withValues(alpha: 0.12),
              borderRadius: SVShapes.standard,
            ),
            child: Icon(tipo.icono, color: tipo.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SVColors.onSurface,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: SVShapes.standard,
                  child: LinearProgressIndicator(
                    value: progreso <= 0 ? null : progreso.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: SVColors.surfaceContainerLow,
                    valueColor: AlwaysStoppedAnimation<Color>(tipo.color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Subiendo $pct%',
            style:
                const TextStyle(color: SVColors.onSurfaceMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

Widget _iaBadge(
  IconData icono,
  String tooltip, {
  required bool visible,
  required VoidCallback onTap,
}) {
  return SizedBox(
    width: 32,
    height: 28,
    child: visible
        ? Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: SVColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icono, size: 16, color: SVColors.primary),
              ),
            ),
          )
        : const SizedBox.shrink(),
  );
}
