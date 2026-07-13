import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/admin_auditoria_provider.dart';
import 'admin_log_entry.dart';
import 'admin_paginacion_bar.dart';

/// Historial de auditoria administrativa con diseno Clean UI.
///
/// Encabezado con titulo, listado estilo timeline con puntos de severidad
/// y paginacion inferior.
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
    final cs = Theme.of(context).colorScheme;

    return auditoriaAsync.when(
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
                  ref.invalidate(adminAuditoriaProvider(_paginaActual)),
            ),
          ],
        ),
      ),
      data: (registros) {
        if (registros.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.history_rounded,
                      size: 32, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sin registros de auditoria',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        final bool puedeTenerMas = registros.length >= _registrosPorPagina;
        final int totalPaginas =
            puedeTenerMas ? _paginaActual + 2 : _paginaActual + 1;

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
                      color: const Color(0xFF5D6D7E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Auditoria',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  _buildLeyenda(),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminAuditoriaProvider(_paginaActual));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  itemCount: registros.length,
                  itemBuilder: (context, index) {
                    return AdminLogEntry(
                      registro: registros[index],
                      esPrimero: index == 0,
                      esUltimo: index == registros.length - 1,
                    );
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

  Widget _buildLeyenda() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _puntoLeyenda('CRÍTICO', const Color(0xFFC0392B)),
        const SizedBox(width: 10),
        _puntoLeyenda('ALTO', const Color(0xFFE67E22)),
        const SizedBox(width: 10),
        _puntoLeyenda('MEDIO', const Color(0xFFF39C12)),
        const SizedBox(width: 10),
        _puntoLeyenda('INFO', const Color(0xFF5D6D7E)),
      ],
    );
  }

  Widget _puntoLeyenda(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            color: color,
          ),
        ),
      ],
    );
  }
}
