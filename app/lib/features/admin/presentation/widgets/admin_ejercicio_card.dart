import 'package:flutter/material.dart';

import '../../domain/admin_ejercicio_dto.dart';

/// Tarjeta de ejercicio con diseno visual limpio y profesional.
///
/// Muestra un acento lateral de color segun la dificultad, chips semanticos
/// compactos para modalidad y finalidad, un toggle moderno con etiqueta de
/// estado y un menu contextual sutil.
class AdminEjercicioCard extends StatelessWidget {
  final AdminEjercicio ejercicio;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const AdminEjercicioCard({
    required this.ejercicio,
    required this.onToggle,
    required this.onEdit,
    super.key,
  });

  static const _coloresDificultad = {
    'principiante': Color(0xFF4CAF50),
    'intermedio': Color(0xFFFF9800),
    'avanzado': Color(0xFFE53935),
  };

  Color get _acento {
    return _coloresDificultad[ejercicio.dificultad?.toLowerCase()] ??
        const Color(0xFF607D8B);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activo = ejercicio.activo;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(
                color: activo ? _acento : Colors.grey.shade300,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ejercicio.nombre,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color:
                                  activo ? cs.onSurface : Colors.grey.shade400,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (ejercicio.dificultad != null)
                                _buildEtiqueta(
                                  ejercicio.dificultad!,
                                  _acento,
                                  Icons.speed_rounded,
                                ),
                              if (ejercicio.modalidadEntrenamiento != null)
                                _buildEtiqueta(
                                  ejercicio.modalidadEntrenamiento!,
                                  const Color(0xFF1565C0),
                                  Icons.fitness_center_rounded,
                                ),
                              if (ejercicio.finalidad != null)
                                for (final f in ejercicio.finalidad!)
                                  _buildEtiqueta(
                                    f,
                                    const Color(0xFF2E7D32),
                                    Icons.track_changes_rounded,
                                  ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => onToggle(!activo),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 44,
                            height: 26,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              color:
                                  activo ? _acento : cs.surfaceContainerHighest,
                            ),
                            alignment: activo
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: activo
                                    ? Colors.white
                                    : cs.onSurfaceVariant
                                        .withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activo ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: activo ? _acento : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.more_horiz,
                          size: 20,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEtiqueta(String texto, Color color, IconData icono) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 12, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
