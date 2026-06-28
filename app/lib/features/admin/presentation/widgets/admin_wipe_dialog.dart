import 'package:flutter/material.dart';

/// Diálogo de confirmación para la operación de wipe de datos de usuario.
///
/// Muestra tres secciones colapsables que detallan qué se conserva,
/// qué se resetea y qué se elimina, y requiere que el administrador
/// escriba "ELIMINAR" para habilitar el botón de confirmación.
class AdminWipeDialog extends StatefulWidget {
  final String nombreUsuario;
  final String usuarioId;

  const AdminWipeDialog({
    required this.nombreUsuario,
    required this.usuarioId,
    super.key,
  });

  @override
  State<AdminWipeDialog> createState() => _AdminWipeDialogState();
}

class _AdminWipeDialogState extends State<AdminWipeDialog> {
  final _controller = TextEditingController();
  bool _conservarExpandido = false;
  bool _resetearExpandido = false;
  bool _eliminarExpandido = false;

  bool get _confirmado => _controller.text.trim() == 'ELIMINAR';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Wipe — ${widget.nombreUsuario}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Esta acción es irreversible. Revisa cuidadosamente qué datos se afectarán:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // ── SECCIÓN: CONSERVAR (verde) ──
              _SeccionWipe(
                titulo: 'CONSERVAR',
                color: Colors.green,
                expandido: _conservarExpandido,
                onToggle: () =>
                    setState(() => _conservarExpandido = !_conservarExpandido),
                icono: Icons.check_circle_outline,
                items: const [
                  'Perfil de bienestar (peso, altura, objetivo)',
                  'Perfil académico (carrera, semestre)',
                  'Carreras y datos de cuenta',
                ],
              ),
              const SizedBox(height: 8),

              // ── SECCIÓN: RESETEAR (ámbar) ──
              _SeccionWipe(
                titulo: 'RESETEAR',
                color: Colors.amber.shade700,
                expandido: _resetearExpandido,
                onToggle: () =>
                    setState(() => _resetearExpandido = !_resetearExpandido),
                icono: Icons.refresh,
                items: const [
                  'Nivel → 1',
                  'XP total → 0',
                  'Racha actual → 0',
                ],
              ),
              const SizedBox(height: 8),

              // ── SECCIÓN: ELIMINAR (rojo) ──
              _SeccionWipe(
                titulo: 'ELIMINAR',
                color: Colors.red,
                expandido: _eliminarExpandido,
                onToggle: () =>
                    setState(() => _eliminarExpandido = !_eliminarExpandido),
                icono: Icons.delete_forever,
                items: const [
                  'Todas las sesiones de entrenamiento',
                  'Todas las rutinas y ejercicios',
                  'Todos los retos y progresos',
                  'Todas las insignias obtenidas',
                  'Entregas de exámenes y horarios',
                  'Asignaturas y apuntes',
                  'Interacciones sociales y amistades',
                  'Notificaciones y recomendaciones',
                  'Planes de estudio y sesiones focus',
                  'Historial de objetivos y peso',
                ],
              ),

              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Escribe ELIMINAR para confirmar',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${widget.usuarioId}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _confirmado ? () => Navigator.of(context).pop(true) : null,
          icon: const Icon(Icons.delete_forever, size: 18),
          label: const Text('Confirmar Wipe'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Sección colapsable individual dentro del diálogo de wipe.
class _SeccionWipe extends StatelessWidget {
  final String titulo;
  final Color color;
  final bool expandido;
  final VoidCallback onToggle;
  final IconData icono;
  final List<String> items;

  const _SeccionWipe({
    required this.titulo,
    required this.color,
    required this.expandido,
    required this.onToggle,
    required this.icono,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icono, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: expandido ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child:
                        Icon(Icons.keyboard_arrow_down, size: 20, color: color),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• ',
                                      style: TextStyle(
                                          color: color, fontSize: 12)),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: color.withValues(alpha: 0.8)),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
                crossFadeState: expandido
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
