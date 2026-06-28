import 'package:flutter/material.dart';

import '../../domain/admin_auditoria_dto.dart';

/// Entrada individual del registro de auditoría.
///
/// Muestra una tarjeta compacta con icono contextual según la acción,
/// descripción de la operación realizada, entidad afectada y fecha relativa.
class AdminLogEntry extends StatelessWidget {
  const AdminLogEntry({required this.registro, super.key});

  final AuditoriaRegistro registro;

  /// Traduce el nombre interno de la entidad a una etiqueta legible.
  static String _traducirEntidad(String entidad) {
    switch (entidad) {
      case 'usuarios':
        return 'Usuario';
      case 'ejercicios':
        return 'Ejercicio';
      case 'actividades_sociales':
        return 'Publicación';
      case 'comentarios_feed':
        return 'Comentario';
      default:
        return entidad;
    }
  }

  /// Devuelve el icono y color correspondientes a la [accion].
  static (IconData, Color) _iconoParaAccion(String accion) {
    switch (accion) {
      case 'wipe':
        return (Icons.delete_forever, Colors.red);
      case 'cambiar_rol':
        return (Icons.shield, Colors.blue);
      case 'activar_ejercicio':
      case 'desactivar_ejercicio':
        return (Icons.fitness_center, Colors.green);
      case 'aprobar_contenido':
      case 'eliminar_contenido':
        return (Icons.flag, Colors.orange);
      default:
        return (Icons.history, Colors.grey);
    }
  }

  /// Genera una cadena de fecha relativa en español.
  static String _fechaRelativa(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays == 0) return 'Hoy';
    if (diferencia.inDays == 1) return 'Ayer';
    if (diferencia.inDays < 7) return 'Hace ${diferencia.inDays} días';

    final meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icono, color) = _iconoParaAccion(registro.accion);
    final admin = registro.adminNombre ?? 'Admin';
    final entidadTraducida = _traducirEntidad(registro.entidad);
    final relativo = _fechaRelativa(registro.creadoEn);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icono de la acción
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, size: 20, color: color),
            ),
            const SizedBox(width: 12),

            // Texto descriptivo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      children: [
                        TextSpan(
                          text: admin,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: ' · ${registro.accion} en $entidadTraducida',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    relativo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
