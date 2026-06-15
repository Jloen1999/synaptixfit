import 'package:flutter/material.dart';

import '../../domain/reto_grafo_dto.dart';
import '../../domain/reto_condicion_dto.dart';

class GrafoDependencias extends StatelessWidget {
  const GrafoDependencias({required this.grafo, super.key});

  final GrafoReto grafo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (grafo.nodos.isEmpty) return const SizedBox.shrink();

    final nodosPorProfundidad = <int, List<NodoHito>>{};
    for (final n in grafo.nodos) {
      nodosPorProfundidad.putIfAbsent(n.profundidad, () => []).add(n);
    }
    final profundidades = nodosPorProfundidad.keys.toList()..sort();

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_tree_rounded,
                      size: 16, color: Colors.purple),
                ),
                const SizedBox(width: 10),
                Text('Dependencias',
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                const Spacer(),
                _LeyendaLabel(
                  color: Colors.grey.shade300,
                  label: 'Bloqueado',
                ),
                const SizedBox(width: 8),
                _LeyendaLabel(
                  color: Colors.blue.shade200,
                  label: 'Disponible',
                ),
                const SizedBox(width: 8),
                _LeyendaLabel(
                  color: Colors.orange.shade200,
                  label: 'En curso',
                ),
                const SizedBox(width: 8),
                _LeyendaLabel(
                  color: Colors.green.shade200,
                  label: 'Completado',
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...profundidades.map((p) {
              final nodos = nodosPorProfundidad[p]!;
              final esUltimoNivel = p == profundidades.last;
              return Padding(
                padding: EdgeInsets.only(bottom: esUltimoNivel ? 0 : 8),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: nodos
                          .map((n) => _NodoHitoCard(
                                nodo: n,
                                aristasEntrantes: grafo.aristas
                                    .where((a) => a.haciaHitoId == n.hitoId)
                                    .toList(),
                              ))
                          .toList(),
                    ),
                    if (!esUltimoNivel)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(Icons.arrow_downward_rounded,
                            size: 20, color: theme.colorScheme.outlineVariant),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LeyendaLabel extends StatelessWidget {
  const _LeyendaLabel({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _NodoHitoCard extends StatelessWidget {
  const _NodoHitoCard({required this.nodo, required this.aristasEntrantes});
  final NodoHito nodo;
  final List<AristaDependencia> aristasEntrantes;

  Color _colorFondo(BuildContext context) {
    final theme = Theme.of(context);
    return switch (nodo.estado) {
      EstadoHito.completado => Colors.green.withValues(alpha: 0.15),
      EstadoHito.enProgreso => Colors.orange.withValues(alpha: 0.15),
      EstadoHito.disponible => Colors.blue.withValues(alpha: 0.15),
      EstadoHito.bloqueado => theme.colorScheme.surfaceContainerHighest,
    };
  }

  Color _colorBorde() {
    return switch (nodo.estado) {
      EstadoHito.completado => Colors.green,
      EstadoHito.enProgreso => Colors.orange,
      EstadoHito.disponible => Colors.blue,
      EstadoHito.bloqueado => Colors.grey.shade300,
    };
  }

  IconData _iconoEstado() {
    return switch (nodo.estado) {
      EstadoHito.completado => Icons.check_circle_rounded,
      EstadoHito.enProgreso => Icons.play_circle_rounded,
      EstadoHito.disponible => Icons.radio_button_unchecked,
      EstadoHito.bloqueado => Icons.lock_rounded,
    };
  }

  String _condicionLabel() {
    if (aristasEntrantes.isEmpty) return '';
    final a = aristasEntrantes.first;
    return switch (a.condicion) {
      TipoCondicion.AND => 'Requiere todas',
      TipoCondicion.OR => 'Requiere 1',
      TipoCondicion.X_OF_Y =>
        'Requiere ${a.condicionN} de ${aristasEntrantes.length}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorBorde = _colorBorde();
    final condicion = _condicionLabel();

    return Container(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: _colorFondo(context),
        border: Border.all(color: colorBorde.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(_iconoEstado(), size: 16, color: colorBorde),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  nodo.titulo,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (condicion.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              condicion,
              style: TextStyle(
                  fontSize: 9,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.6)),
            ),
          ],
          if (nodo.porcentajePeso > 0) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: nodo.estaCompletado ? 1.0 : 0.0,
              backgroundColor: colorBorde.withValues(alpha: 0.1),
              color: colorBorde,
              minHeight: 3,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ],
      ),
    );
  }
}
