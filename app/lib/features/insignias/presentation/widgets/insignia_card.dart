import 'package:flutter/material.dart';

import '../../domain/insignia_dto.dart';

/// Card individual de insignia (obtenida o bloqueada).
class InsigniaCard extends StatelessWidget {
  const InsigniaCard({
    super.key,
    required this.insignia,
    this.onTap,
  });

  final Insignia insignia;
  final VoidCallback? onTap;

  Color _rarezaColor(String rareza, {bool bloqueada = false}) {
    if (bloqueada) return const Color(0xFF334155);
    switch (rareza) {
      case 'legendaria':
        return const Color(0xFFFBBF24);
      case 'epica':
        return const Color(0xFFA78BFA);
      case 'rara':
        return const Color(0xFF60A5FA);
      default:
        return const Color(0xFF4ADE80);
    }
  }

  String _rarezaEtiqueta(String rareza) {
    switch (rareza) {
      case 'legendaria':
        return 'Legendaria';
      case 'epica':
        return 'Épica';
      case 'rara':
        return 'Rara';
      default:
        return 'Común';
    }
  }

  @override
  Widget build(BuildContext context) {
    final obtenida = insignia.obtenida;
    final color = _rarezaColor(insignia.rareza, bloqueada: !obtenida);
    final bgColor =
        obtenida ? color.withValues(alpha: 0.08) : const Color(0xFF1E293B);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: obtenida
                ? color.withValues(alpha: 0.2)
                : const Color(0xFF334155),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: obtenida
                    ? color.withValues(alpha: 0.15)
                    : const Color(0xFF334155).withValues(alpha: 0.5),
                border: Border.all(
                  color: obtenida
                      ? color.withValues(alpha: 0.4)
                      : const Color(0xFF475569),
                ),
              ),
              child: Center(
                child: obtenida
                    ? Text(
                        insignia.icono,
                        style: const TextStyle(fontSize: 24),
                      )
                    : Icon(
                        Icons.lock_rounded,
                        size: 22,
                        color: const Color(0xFF64748B).withValues(alpha: 0.7),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            // Nombre
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                insignia.nombre,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: obtenida
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Rareza / fecha
            Text(
              obtenida && insignia.obtenidaEn != null
                  ? _formatearFecha(insignia.obtenidaEn!)
                  : _rarezaEtiqueta(insignia.rareza),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: obtenida
                    ? color.withValues(alpha: 0.8)
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diff = ahora.difference(fecha);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    if (diff.inDays < 30) return 'Hace ${(diff.inDays / 7).floor()} sem';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
