import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/challenge_progress_bar.dart';
import '../../../../shared/models/db_models.dart';
import '../../../../core/design_system/sv_colors.dart';
import '../../../retos/application/retos_provider.dart';

/// Tarjeta de reto activo mejorada con tareas expandibles y botón confirmar.
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
  bool _confirmando = false;
  final Map<String, bool> _optimistas = {};

  @override
  Widget build(BuildContext context) {
    final reto = widget.reto;
    final theme = Theme.of(context);
    final esFitness = reto.tipo == 'fitness';
    final color =
        esFitness ? theme.colorScheme.primary : const Color(0xFF7B1FA2);
    final diasRestantes = reto.fechaFin.difference(DateTime.now()).inDays;

    final expandible = widget.tieneTareas;
    final tareasAsync =
        _expanded ? ref.watch(tareasDeRetoProvider(reto.id)) : null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      color: theme.colorScheme.surfaceContainerLowest,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: tipo badge + complejidad + días restantes
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      esFitness ? '💪 Fitness' : '📚 Académico',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  widget.tieneTareas
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text('Complejo',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.w600)),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text('Simple',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600)),
                        ),
                  const Spacer(),
                  const Icon(Icons.schedule_rounded,
                      size: 11, color: SVColors.onSurfaceMuted),
                  const SizedBox(width: 2),
                  Text(
                    diasRestantes > 0
                        ? '$diasRestantes d'
                        : diasRestantes == 0
                            ? 'Hoy'
                            : 'Vencido',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: diasRestantes <= 3
                          ? SVColors.error
                          : SVColors.onSurfaceMuted,
                      fontWeight: diasRestantes <= 3 ? FontWeight.w600 : null,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Titulo
              Text(
                reto.titulo,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Barra de progreso + Completar a la izquierda
              Row(
                children: [
                  // Botón Completar a la izquierda
                  InkWell(
                    onTap: _confirmando ? null : () => _confirmarCompletar(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _confirmando
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check,
                                    size: 12, color: Colors.green),
                                SizedBox(width: 3),
                                Text('Completar',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChallengeProgressBar(progress: widget.progreso),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${(widget.progreso * 100).round()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              // Tareas expandibles
              if (expandible) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _expanded ? 'Ocultar tareas' : 'Ver tareas',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (_expanded && tareasAsync != null)
                  tareasAsync.when(
                    data: (tareas) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: [
                          ...tareas.map((t) {
                            final completado = _optimistas.containsKey(t.id)
                                ? _optimistas[t.id]!
                                : t.estaCompletado;
                            return InkWell(
                              onTap: () async {
                                final nuevoValor = !completado;
                                setState(() => _optimistas[t.id] = nuevoValor);
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  await toggleTareaCompletada(
                                    t.id,
                                    widget.reto.id,
                                    completada: nuevoValor,
                                    ref: ref,
                                  );
                                } catch (_) {
                                  if (mounted) {
                                    setState(() => _optimistas.remove(t.id));
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Error al ${nuevoValor ? "completar" : "desmarcar"} tarea'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      completado
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      size: 18,
                                      color: completado
                                          ? Colors.green
                                          : Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        t.titulo,
                                        style: TextStyle(
                                          fontSize: 12,
                                          decoration: completado
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color:
                                              completado ? Colors.grey : null,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${t.porcentajePeso}%',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (e, _) =>
                        Text('Error: $e', style: const TextStyle(fontSize: 11)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarCompletar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Completar reto'),
        content: Text('¿Marcar "${widget.reto.titulo}" como completado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, completar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _confirmando = true);
      try {
        await completarReto(widget.reto.id, ref);
      } finally {
        if (mounted) setState(() => _confirmando = false);
      }
    }
  }
}
