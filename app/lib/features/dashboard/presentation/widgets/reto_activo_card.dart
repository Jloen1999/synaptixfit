import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/db_models.dart';
import '../../../../core/design_system/sv_colors.dart';
import '../../../retos/application/retos_provider.dart';

/// Tarjeta de reto en el dashboard.
///
/// - **Simple:** tarjeta horizontal plana con *Swipe-to-Complete* bidireccional
///   (deslizar → derecha = completar, ← izquierda = deshacer).
/// - **Complejo:** acordeón minimalista. El padre muestra el progreso "X/N
///   tareas" y un icono de estado; al tocarlo se despliegan las subtareas con
///   indentación. *Swipe* sobre el padre completa todas las subtareas pendientes
///   de golpe (transacción masiva).
class RetoActivoCard extends ConsumerStatefulWidget {
  const RetoActivoCard({
    required this.reto,
    required this.progreso,
    required this.tieneTareas,
    this.onTap,
    super.key,
  });

  final RetoDb reto;
  final double progreso;
  final bool tieneTareas;
  final VoidCallback? onTap;

  @override
  ConsumerState<RetoActivoCard> createState() => _RetoActivoCardState();
}

class _RetoActivoCardState extends ConsumerState<RetoActivoCard> {
  bool _expanded = false;
  final Map<String, bool> _optimistas = {};

  RetoDb get reto => widget.reto;

  bool get _completado => reto.estaCompletado || widget.progreso >= 1.0;

  Color get _color => reto.tipo == 'fitness'
      ? Theme.of(context).colorScheme.primary
      : const Color(0xFF7B1FA2);

  // ---------------------------------------------------------------------------
  // Acciones de completado (gamificación exacta en retos_provider)
  // ---------------------------------------------------------------------------
  Future<void> _completar() async {
    if (_completado) return;
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    await completarReto(reto.id, ref);
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Reto completado'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => descompletarReto(reto.id, ref),
          ),
        ),
      );
  }

  Future<void> _deshacer() async {
    HapticFeedback.mediumImpact();
    await descompletarReto(reto.id, ref);
  }

  Future<void> _toggleTarea(HitoRetoDb t) async {
    final actual = _optimistas[t.id] ?? t.estaCompletado;
    final nuevo = !actual;
    setState(() => _optimistas[t.id] = nuevo);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await toggleTareaCompletada(t.id, reto.id, completada: nuevo, ref: ref);
    } catch (_) {
      if (!mounted) return;
      setState(() => _optimistas.remove(t.id));
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la tarea')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('reto_${reto.id}'),
      direction: DismissDirection.horizontal,
      background: _swipeBg(
        const Color(0xFF10B981),
        Icons.check_circle_rounded,
        'Completar',
        Alignment.centerLeft,
      ),
      secondaryBackground: _swipeBg(
        const Color(0xFFF59E0B),
        Icons.undo_rounded,
        'Deshacer',
        Alignment.centerRight,
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await _completar();
        } else {
          await _deshacer();
        }
        return false; // No se elimina; el provider refresca la lista.
      },
      child: widget.tieneTareas ? _buildComplejo() : _buildSimple(),
    );
  }

  // ---------------------------------------------------------------------------
  // Reto SIMPLE — tarjeta horizontal plana
  // ---------------------------------------------------------------------------
  Widget _buildSimple() {
    final theme = Theme.of(context);
    final dias = reto.fechaFin.difference(DateTime.now()).inDays;
    return _CardPlano(
      color: _color,
      onTap: widget.onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              reto.tipo == 'fitness'
                  ? Icons.fitness_center_rounded
                  : Icons.school_rounded,
              size: 20,
              color: _color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reto.titulo,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.swipe_rounded,
                        size: 12, color: SVColors.onSurfaceMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Desliza para completar',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: SVColors.onSurfaceMuted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _ChipDias(dias: dias),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reto COMPLEJO — acordeón minimalista
  // ---------------------------------------------------------------------------
  Widget _buildComplejo() {
    final theme = Theme.of(context);
    final tareasAsync = ref.watch(tareasDeRetoProvider(reto.id));
    final tareas = tareasAsync.valueOrNull ?? const <HitoRetoDb>[];
    final total = tareas.length;
    final completadas = tareas.where((t) {
      return _optimistas[t.id] ?? t.estaCompletado;
    }).length;

    return _CardPlano(
      color: _color,
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.checklist_rounded, size: 20, color: _color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reto.titulo,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      total > 0 ? '$completadas/$total tareas' : 'Sin tareas',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _color,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.expand_more_rounded,
                    color: SVColors.onSurfaceMuted),
              ),
            ],
          ),
          // Subtareas (indentadas)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(left: 52, top: 6),
                    child: tareasAsync.when(
                      data: (ts) => Column(
                        children: ts.map(_buildSubtarea).toList(),
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (e, _) => const SizedBox.shrink(),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtarea(HitoRetoDb t) {
    final completado = _optimistas[t.id] ?? t.estaCompletado;
    return InkWell(
      onTap: () => _toggleTarea(t),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(
              completado
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              size: 18,
              color:
                  completado ? const Color(0xFF10B981) : Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.titulo,
                style: TextStyle(
                  fontSize: 12,
                  decoration: completado ? TextDecoration.lineThrough : null,
                  color: completado ? Colors.grey : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swipeBg(
      Color color, IconData icon, String label, Alignment alignment) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// Tarjeta plana reutilizable (sin sombra, borde sutil).
class _CardPlano extends StatelessWidget {
  const _CardPlano({required this.color, required this.child, this.onTap});

  final Color color;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }
}

class _ChipDias extends StatelessWidget {
  const _ChipDias({required this.dias});
  final int dias;

  @override
  Widget build(BuildContext context) {
    final urgente = dias <= 3;
    final texto = dias > 0
        ? '$dias d'
        : dias == 0
            ? 'Hoy'
            : 'Vencido';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded,
            size: 12,
            color: urgente ? SVColors.error : SVColors.onSurfaceMuted),
        const SizedBox(width: 3),
        Text(
          texto,
          style: TextStyle(
            fontSize: 11,
            fontWeight: urgente ? FontWeight.w700 : FontWeight.w500,
            color: urgente ? SVColors.error : SVColors.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}
