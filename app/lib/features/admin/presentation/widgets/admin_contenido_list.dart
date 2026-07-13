import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/admin_contenido_provider.dart';
import '../../domain/admin_contenido_dto.dart';
import 'admin_contenido_card.dart';
import 'admin_paginacion_bar.dart';

/// Listado paginado de moderacion de contenido con diseno Clean UI.
///
/// Encabezado con indicador de pendientes, listado de tarjetas con tipo
/// y acciones de aprobar/eliminar, y paginacion inferior.
class AdminContenidoList extends ConsumerStatefulWidget {
  const AdminContenidoList({super.key});

  @override
  ConsumerState<AdminContenidoList> createState() => _AdminContenidoListState();
}

class _AdminContenidoListState extends ConsumerState<AdminContenidoList> {
  int _pagina = 0;
  static const int _itemsPorPagina = 20;

  @override
  Widget build(BuildContext context) {
    final contenidoAsync = ref.watch(adminContenidoReportadoProvider(_pagina));
    final cs = Theme.of(context).colorScheme;

    return contenidoAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 44, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text('Error al cargar', style: TextStyle(color: cs.error)),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              onPressed: () =>
                  ref.invalidate(adminContenidoReportadoProvider(_pagina)),
            ),
          ],
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_outline_rounded,
                      size: 32, color: Colors.green.shade400),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sin contenido pendiente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Todo el contenido reportado ha sido moderado',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        }

        final bool puedeTenerMas = items.length >= _itemsPorPagina;
        final int totalPaginas = puedeTenerMas ? _pagina + 2 : _pagina + 1;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Moderacion',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${items.length} pendientes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(adminContenidoReportadoProvider(_pagina)),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 2, bottom: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return AdminContenidoCard(
                      contenido: item,
                      onAprobar: () => _confirmarAprobar(item),
                      onEliminar: () => _confirmarEliminar(item),
                    );
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

  void _confirmarAprobar(ContenidoReportado item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.check_circle_outline_rounded,
            size: 40, color: Colors.green.shade500),
        title: const Text('Aprobar contenido'),
        content: const Text(
            'El contenido sera restaurado y el reporte se marcara como resuelto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await aprobarContenido(ref,
                    tipo: item.tipo, id: item.id, autorId: item.autorId);
                messenger.showSnackBar(SnackBar(
                  content: const Row(children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Contenido aprobado'),
                  ]),
                  backgroundColor: Colors.green.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              } catch (e) {
                messenger.showSnackBar(SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Aprobar'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(ContenidoReportado item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.warning_amber_rounded,
            size: 40, color: Colors.red.shade400),
        title: const Text('Eliminar contenido'),
        content: const Text(
            'Esta accion es irreversible. El contenido sera eliminado permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await eliminarContenido(ref,
                    tipo: item.tipo, id: item.id, autorId: item.autorId);
                messenger.showSnackBar(SnackBar(
                  content: const Row(children: [
                    Icon(Icons.delete, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Contenido eliminado'),
                  ]),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              } catch (e) {
                messenger.showSnackBar(SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Eliminar'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
