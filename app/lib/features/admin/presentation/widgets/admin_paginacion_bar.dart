import 'package:flutter/material.dart';

/// Barra de navegación de paginación genérica.
///
/// Muestra botones "Anterior" / "Siguiente" junto con el texto de página
/// actual sobre el total. Los botones se deshabilitan automáticamente
/// en los extremos.
class AdminPaginacionBar extends StatelessWidget {
  const AdminPaginacionBar({
    required this.paginaActual,
    required this.totalPaginas,
    required this.onPageChanged,
    super.key,
  });

  final int paginaActual;
  final int totalPaginas;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed:
                paginaActual > 0 ? () => onPageChanged(paginaActual - 1) : null,
            icon: const Icon(Icons.chevron_left, size: 20),
            label: const Text('Anterior'),
          ),
          Text(
            'Página ${paginaActual + 1} de $totalPaginas',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          TextButton.icon(
            onPressed: paginaActual < totalPaginas - 1
                ? () => onPageChanged(paginaActual + 1)
                : null,
            icon: const Icon(Icons.chevron_right, size: 20),
            label: const Text('Siguiente'),
          ),
        ],
      ),
    );
  }
}
