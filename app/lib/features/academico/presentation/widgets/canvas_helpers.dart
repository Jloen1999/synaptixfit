import 'package:flutter/material.dart';

/// Banner de conflicto que aparece cuando bloques planificados colisionan.
class ConflictBanner extends StatelessWidget {
  const ConflictBanner({required this.mensaje, super.key});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFEF4444).withValues(alpha: 0.08),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: Color(0xFFEF4444)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado vacío cuando el grid no tiene bloques generados.
class GridEmptyState extends StatelessWidget {
  const GridEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_month_outlined,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Sin bloques planificados',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Arrastra bloques desde el inbox o usa la IA',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

/// Botón para autocompletar con IA ubicado como FAB.
class AutocompleteFab extends StatelessWidget {
  const AutocompleteFab({
    required this.onPressed,
    required this.cargando,
    super.key,
  });

  final VoidCallback onPressed;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: cargando ? null : onPressed,
      icon: cargando
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.auto_awesome),
      label: Text(cargando ? 'Generando...' : 'Autocompletar con IA'),
    );
  }
}
