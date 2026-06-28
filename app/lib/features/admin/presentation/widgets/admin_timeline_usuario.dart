import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/admin_usuario_stats_provider.dart';
import '../../domain/admin_timeline_dto.dart';
import 'admin_paginacion_bar.dart';

/// Línea de tiempo de un usuario en el panel de administración.
///
/// Muestra eventos cronológicos como sesiones, retos completados y acciones
/// administrativas, con iconos distintivos para cada tipo de evento.
class AdminTimelineUsuario extends ConsumerStatefulWidget {
  final String usuarioId;

  const AdminTimelineUsuario({required this.usuarioId, super.key});

  @override
  ConsumerState<AdminTimelineUsuario> createState() =>
      _AdminTimelineUsuarioState();
}

class _AdminTimelineUsuarioState extends ConsumerState<AdminTimelineUsuario> {
  int _pagina = 0;
  static const int _itemsPorPagina = 30;

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(
      adminTimelineUsuarioProvider(
        (usuarioId: widget.usuarioId, page: _pagina),
      ),
    );

    return timelineAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Error: $err'),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              onPressed: () => ref.invalidate(
                adminTimelineUsuarioProvider(
                  (usuarioId: widget.usuarioId, page: _pagina),
                ),
              ),
            ),
          ],
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timeline, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Sin eventos en la línea de tiempo',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final bool puedeTenerMas = entries.length >= _itemsPorPagina;
        final int totalPaginas = puedeTenerMas ? _pagina + 2 : _pagina + 1;

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(
                  adminTimelineUsuarioProvider(
                    (usuarioId: widget.usuarioId, page: _pagina),
                  ),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    return _TimelineEntryTile(entry: entries[index]);
                  },
                ),
              ),
            ),
            AdminPaginacionBar(
              paginaActual: _pagina,
              totalPaginas: totalPaginas,
              onPageChanged: (nuevaPagina) {
                setState(() => _pagina = nuevaPagina);
              },
            ),
          ],
        );
      },
    );
  }
}

/// Tile individual para una entrada de la línea de tiempo.
///
/// Muestra un icono distintivo según el tipo de evento, la fecha y una
/// descripción legible.
class _TimelineEntryTile extends StatelessWidget {
  final AdminTimelineEntry entry;

  const _TimelineEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final iconData = _iconoParaTipo(entry.tipo);
    final color = _colorParaTipo(entry.tipo);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Línea vertical + icono
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, size: 16, color: color),
                ),
                Container(
                  width: 2,
                  height: 30,
                  color: Colors.grey.shade200,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.descripcion,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatearFecha(entry.fecha),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconoParaTipo(TimelineTipoAdmin tipo) {
    switch (tipo) {
      case TimelineTipoAdmin.sesion:
        return Icons.fitness_center;
      case TimelineTipoAdmin.rutina:
        return Icons.list_alt;
      case TimelineTipoAdmin.reto:
        return Icons.emoji_events;
      case TimelineTipoAdmin.insignia:
      case TimelineTipoAdmin.logro:
        return Icons.military_tech;
      case TimelineTipoAdmin.wipe:
        return Icons.delete;
      case TimelineTipoAdmin.rolCambio:
        return Icons.shield;
    }
  }

  Color _colorParaTipo(TimelineTipoAdmin tipo) {
    switch (tipo) {
      case TimelineTipoAdmin.sesion:
        return Colors.green;
      case TimelineTipoAdmin.rutina:
        return Colors.blue;
      case TimelineTipoAdmin.reto:
        return Colors.amber;
      case TimelineTipoAdmin.insignia:
      case TimelineTipoAdmin.logro:
        return Colors.purple;
      case TimelineTipoAdmin.wipe:
        return Colors.red;
      case TimelineTipoAdmin.rolCambio:
        return Colors.orange;
    }
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diff = ahora.difference(fecha);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
