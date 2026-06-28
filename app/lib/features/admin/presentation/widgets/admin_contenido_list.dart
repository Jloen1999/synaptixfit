import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/admin_contenido_provider.dart';
import '../../domain/admin_contenido_dto.dart';
import 'admin_contenido_card.dart';
import 'admin_paginacion_bar.dart';

/// Listado paginado de contenido reportado pendiente de moderación.
///
/// Muestra tarjetas con el contenido reportado y permite al administrador
/// aprobar o eliminar cada elemento mediante diálogos de confirmación.
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

    return contenidoAsync.when(
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
              onPressed: () =>
                  ref.invalidate(adminContenidoReportadoProvider(_pagina)),
            ),
          ],
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                SizedBox(height: 12),
                Text(
                  'No hay contenido reportado',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final bool puedeTenerMas = items.length >= _itemsPorPagina;
        final int totalPaginas = puedeTenerMas ? _pagina + 2 : _pagina + 1;

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(adminContenidoReportadoProvider(_pagina)),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
        title: const Text('Aprobar contenido'),
        content:
            const Text('¿Estás seguro de que deseas aprobar este contenido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await aprobarContenido(
                  ref,
                  tipo: item.tipo,
                  id: item.id,
                  autorId: item.autorId,
                );
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Contenido aprobado'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(ContenidoReportado item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar contenido'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este contenido? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await eliminarContenido(
                  ref,
                  tipo: item.tipo,
                  id: item.id,
                  autorId: item.autorId,
                );
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Contenido eliminado'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
