import 'package:flutter/material.dart';

import '../../domain/admin_ejercicio_dto.dart';

/// Tarjeta individual de ejercicio en el panel de catálogo.
///
/// Muestra el nombre del ejercicio, chips de dificultad, finalidad y
/// modalidad, junto con un [Switch] para activar/desactivar y un menú
/// contextual para editar.
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

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: ejercicio.activo ? 1.0 : 0.55,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color:
                ejercicio.activo ? Colors.grey.shade200 : Colors.red.shade100,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ejercicio.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: ejercicio.activo ? null : Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Switch(value: ejercicio.activo, onChanged: onToggle),
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'edit') onEdit();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Editar'),
                              dense: true,
                              contentPadding: EdgeInsets.zero)),
                    ],
                    icon: const Icon(Icons.more_vert, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (ejercicio.modalidadEntrenamiento != null)
                    _buildChip(ejercicio.modalidadEntrenamiento!,
                        Icons.fitness_center, Colors.blue),
                  if (ejercicio.dificultad != null)
                    _buildChip(
                        ejercicio.dificultad!, Icons.speed, Colors.orange),
                  if (ejercicio.finalidad != null)
                    for (final f in ejercicio.finalidad!)
                      _buildChip(f, Icons.flag, Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}
