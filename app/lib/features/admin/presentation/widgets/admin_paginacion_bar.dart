import 'package:flutter/material.dart';

/// Barra de paginacion con diseno limpio y compacto.
///
/// Botones Anterior/Siguiente con navegacion y texto central de pagina.
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
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: paginaActual > 0
                  ? () => onPageChanged(paginaActual - 1)
                  : null,
              icon: const Icon(Icons.chevron_left_rounded, size: 18),
              label: const Text('Anterior'),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                textStyle: const TextStyle(fontSize: 12),
                foregroundColor: cs.primary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Pag. ${paginaActual + 1} de $totalPaginas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: paginaActual < totalPaginas - 1
                  ? () => onPageChanged(paginaActual + 1)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
              label: const Text('Siguiente'),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                textStyle: const TextStyle(fontSize: 12),
                foregroundColor: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
