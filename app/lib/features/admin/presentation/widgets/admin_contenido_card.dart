import 'package:flutter/material.dart';

import '../../domain/admin_contenido_dto.dart';

/// Tarjeta individual de contenido reportado en el panel de moderación.
///
/// Muestra el tipo de contenido (publicación o comentario), el texto truncado,
/// el autor, la fecha y botones para aprobar o eliminar.
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
    final esActividad = contenido.tipo == ContenidoTipo.actividad;
    final tipoIcono = esActividad ? Icons.article : Icons.chat_bubble;
    final tipoEtiqueta = esActividad ? 'Publicación' : 'Comentario';
    final tipoColor = esActividad ? Colors.blue : Colors.purple;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: tipo + fecha
            Row(
              children: [
                Icon(tipoIcono, size: 18, color: tipoColor),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tipoColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tipoEtiqueta,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tipoColor,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  _formatearFecha(contenido.creadoEn),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Contenido truncado
            Text(
              contenido.contenido,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),

            // Autor
            if (contenido.autorNombre != null)
              Text(
                'Por ${contenido.autorNombre}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 12),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: onAprobar,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Aprobar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onEliminar,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
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
