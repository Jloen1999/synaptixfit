import 'package:flutter/material.dart';

/// Badge que indica que una rutina o reto es una **reutilización (clon)** del
/// contenido de otro usuario, mostrando una referencia al propietario
/// original. Distinción visual con enfoque CLEAN UI (pastilla plana violácea).
class BadgeReutilizado extends StatelessWidget {
  const BadgeReutilizado({
    super.key,
    this.propietario,
    this.etiqueta = 'Reutilizado',
    this.dense = false,
  });

  /// Nombre del propietario original (si se conoce).
  final String? propietario;

  /// Etiqueta base ('Reutilizado' / 'Reutilizada').
  final String etiqueta;

  /// Versión compacta para tarjetas.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF7B5BD6);
    final texto = (propietario != null && propietario!.isNotEmpty)
        ? '$etiqueta · de $propietario'
        : etiqueta;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cached_rounded, size: dense ? 11 : 13, color: color),
          SizedBox(width: dense ? 3 : 5),
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: dense ? 9 : 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
