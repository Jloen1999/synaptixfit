import 'package:flutter/material.dart';

import '../../domain/admin_contenido_dto.dart';

/// Tarjeta de contenido reportado con diseno limpio y profesional.
///
/// Muestra tipo (publicacion / comentario) con acento lateral de color,
/// contenido truncado, autor en cursiva, timestamp relativo y acciones
/// de moderacion (aprobar / eliminar) con estilo visual mejorado.
class AdminContenidoCard extends StatelessWidget {
  final ContenidoReportado contenido;
  final VoidCallback onAprobar;
  final VoidCallback onEliminar;

  const AdminContenidoCard({
    required this.contenido,
    required this.onAprobar,
    required this.onEliminar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final esActividad = contenido.tipo == ContenidoTipo.actividad;
    final tipoIcono =
        esActividad ? Icons.article_rounded : Icons.chat_bubble_rounded;
    final tipoEtiqueta = esActividad ? 'Publicacion' : 'Comentario';
    final tipoColor =
        esActividad ? const Color(0xFF1565C0) : const Color(0xFF7B1FA2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left:
                  BorderSide(color: tipoColor.withValues(alpha: 0.5), width: 4),
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
              right:
                  BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
              bottom:
                  BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: tipoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(tipoIcono, size: 16, color: tipoColor),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tipoColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tipoEtiqueta,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tipoColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.schedule_rounded,
                        size: 13, color: cs.onSurface.withValues(alpha: 0.35)),
                    const SizedBox(width: 4),
                    Text(
                      _formatearFecha(contenido.creadoEn),
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  contenido.contenido,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: cs.onSurface.withValues(alpha: 0.85),
                  ),
                ),
                if (contenido.autorNombre != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 13, color: cs.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(width: 4),
                      Text(
                        'Por ${contenido.autorNombre}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.45),
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      onPressed: onAprobar,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Aprobar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onEliminar,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Eliminar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diff = ahora.difference(fecha);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
