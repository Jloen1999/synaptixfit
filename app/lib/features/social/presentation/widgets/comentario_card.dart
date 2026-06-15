import 'package:flutter/material.dart';

import '../../domain/social_dto.dart';

/// Card individual para un comentario.
///
/// Muestra avatar, nombre, timestamp, texto y si es del usuario actual,
/// iconos de editar y eliminar.
class ComentarioCard extends StatelessWidget {
  const ComentarioCard({
    required this.comentario,
    this.onEditar,
    this.onEliminar,
    super.key,
  });

  final Comentario comentario;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;

  String get _tiempoRelativo {
    final diff = DateTime.now().difference(comentario.fecha);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${comentario.fecha.day}/${comentario.fecha.month}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = comentario.nombreUsuario.isNotEmpty
        ? comentario.nombreUsuario[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              initial,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comentario.nombreUsuario,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _tiempoRelativo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    if (comentario.esMio) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: onEditar,
                        child: Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onEliminar,
                        child: Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comentario.texto,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
