import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/admin_auditoria_provider.dart';
import 'admin_log_entry.dart';
import 'admin_paginacion_bar.dart';

/// Listado paginado del historial de auditoría administrativa.
///
/// Muestra las acciones realizadas por administradores en orden cronológico
/// inverso, con barra de paginación para navegar entre páginas.
class AdminAuditoriaList extends ConsumerStatefulWidget {
  const AdminAuditoriaList({super.key});

  @override
  ConsumerState<AdminAuditoriaList> createState() => _AdminAuditoriaListState();
}

class _AdminAuditoriaListState extends ConsumerState<AdminAuditoriaList> {
  int _paginaActual = 0;
  static const int _registrosPorPagina = 30;

  @override
  Widget build(BuildContext context) {
    final auditoriaAsync = ref.watch(adminAuditoriaProvider(_paginaActual));

    return auditoriaAsync.when(
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
                  ref.invalidate(adminAuditoriaProvider(_paginaActual)),
            ),
          ],
        ),
      ),
      data: (registros) {
        if (registros.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Sin registros',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Estimación conservadora del total de páginas
        final bool puedeTenerMas = registros.length >= _registrosPorPagina;
        final int totalPaginas =
            puedeTenerMas ? _paginaActual + 2 : _paginaActual + 1;

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(adminAuditoriaProvider(_paginaActual)),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: registros.length,
                  itemBuilder: (context, index) {
                    return AdminLogEntry(registro: registros[index]);
                  },
                ),
              ),
            ),
            AdminPaginacionBar(
              paginaActual: _paginaActual,
              totalPaginas: totalPaginas,
              onPageChanged: (nuevaPagina) {
                setState(() => _paginaActual = nuevaPagina);
              },
            ),
          ],
        );
      },
    );
  }
}
