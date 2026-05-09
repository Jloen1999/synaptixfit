import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/challenge_progress_bar.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../application/retos_provider.dart';

class DetalleRetoScreen extends ConsumerWidget {
  const DetalleRetoScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalleAsync = ref.watch(retoDetalleProvider(id));

    ref.listen(retoDetalleProvider(id), (prev, next) {
      final data = next.valueOrNull;
      if (data != null &&
          data.progresoGeneral >= 1.0 &&
          !data.reto.estaCompletado &&
          _esPropio(data.reto.usuarioId)) {
        completarReto(id).then((_) {
          ref.invalidate(retoDetalleProvider(id));
          ref.invalidate(retosProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Reto completado automáticamente!'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      }
    });

    return detalleAsync.when(
      loading: () => const FeatureScaffold(
        title: 'Detalle de Reto',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => FeatureScaffold(
        title: 'Detalle de Reto',
        child: Center(child: Text('Error: $e')),
      ),
      data: (detalle) {
        if (detalle == null) {
          return const FeatureScaffold(
            title: 'Detalle de Reto',
            child: Center(child: Text('Reto no encontrado')),
          );
        }

        final esPropio = _esPropio(detalle.reto.usuarioId);
        final completado = detalle.reto.estaCompletado;

        return FeatureScaffold(
          title: detalle.reto.titulo,
          backPath: '/retos',
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (completado)
                Card(
                  color: Colors.green.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Reto completado',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green)),
                        ),
                        if (esPropio)
                          TextButton(
                            onPressed: () async {
                              await descompletarReto(id);
                              ref.invalidate(retoDetalleProvider(id));
                              ref.invalidate(retosProvider);
                            },
                            child: const Text('Desmarcar'),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              _buildMetadataCard(context, detalle.reto),
              const SizedBox(height: 8),
              if (detalle.hitos.isNotEmpty) ...[
                ChallengeProgressBar(
                    progress: detalle.progresoGeneral,
                    label: 'Progreso general'),
                const SizedBox(height: 2),
                Text(
                  'Calculado como Σ (importancia% × avance%) de cada tarea',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                ),
              ] else ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hourglass_empty,
                              size: 16, color: Colors.grey),
                          SizedBox(width: 6),
                          Text('Pendiente',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Marca como completado cuando termines',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (!completado && esPropio)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Marcar como completado'),
                    onPressed: () => _confirmarCompletar(context, ref),
                  ),
                ),
              if (detalle.hitos.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Tareas', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
              ],
              ...detalle.hitos.map((hito) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TareaControl(
                      hito: hito,
                      editable: esPropio && !completado,
                      onProgressChanged: (v) async {
                        await actualizarProgresoHito(hito.id, v);
                        ref.invalidate(retoDetalleProvider(id));
                        ref.invalidate(retosProvider);
                      },
                    ),
                  )),
              if (!esPropio)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Clonar reto a mi perfil'),
                    onPressed: () => _clonar(context, ref),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _esPropio(String usuarioId) {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.id == usuarioId;
  }

  static Widget _buildMetadataCard(BuildContext context, RetoDb reto) {
    final tipoIcono = reto.tipo == 'fitness'
        ? Icons.fitness_center_rounded
        : Icons.school_rounded;
    final tipoColor =
        reto.tipo == 'fitness' ? Colors.green : Colors.blue;
    final tipoLabel =
        reto.tipo == 'fitness' ? 'Fitness' : 'Académico';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(tipoIcono, size: 18, color: tipoColor),
                const SizedBox(width: 6),
                Text(tipoLabel,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: tipoColor)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: reto.visibilidad == 'publico'
                        ? Colors.orange.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    reto.visibilidad == 'publico' ? 'Público' : 'Privado',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: reto.visibilidad == 'publico'
                          ? Colors.orange
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            if (reto.meta.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(reto.meta, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const Divider(height: 20),
            Row(
              children: [
                _MetadataItem(
                  icon: Icons.calendar_today,
                  label: 'Inicio',
                  value: DateFormat('dd/MM/yy').format(reto.fechaInicio),
                ),
                const SizedBox(width: 16),
                _MetadataItem(
                  icon: Icons.flag_outlined,
                  label: 'Fin',
                  value: DateFormat('dd/MM/yy').format(reto.fechaFin),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _MetadataItem(
              icon: Icons.edit_calendar_outlined,
              label: 'Creado',
              value: DateFormat('dd/MM/yy').format(reto.creadoEn),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarCompletar(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Completar reto'),
        content:
            const Text('¿Marcar este reto como completado? No se podrá editar después.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await completarReto(id);
              ref.invalidate(retoDetalleProvider(id));
              ref.invalidate(retosProvider);
            },
            child: const Text('Completar'),
          ),
        ],
      ),
    );
  }

  void _clonar(BuildContext context, WidgetRef ref) async {
    final nuevoId = await clonarReto(id);
    if (nuevoId != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reto clonado correctamente')),
      );
      ref.invalidate(retosProvider);
      context.go('/retos/$nuevoId');
    }
  }
}

class _TareaControl extends StatelessWidget {
  const _TareaControl({
    required this.hito,
    required this.editable,
    required this.onProgressChanged,
  });

  final HitoRetoDb hito;
  final bool editable;
  final ValueChanged<double> onProgressChanged;

  @override
  Widget build(BuildContext context) {
    final tareaProgress =
        (hito.progresoActual / 100).clamp(0.0, 1.0);
    final tareaColor = tareaProgress >= 0.7
        ? Colors.green
        : tareaProgress >= 0.3
            ? Colors.orange
            : tareaProgress > 0
                ? Colors.blue
                : Colors.grey.shade400;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(hito.titulo,
                      style: Theme.of(context).textTheme.labelLarge),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('${hito.porcentajePeso}% del total',
                      style: const TextStyle(
                          fontSize: 10, color: Colors.blueGrey)),
                ),
                if (hito.estaCompletado)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.check_circle,
                        size: 18, color: Colors.green),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: tareaProgress,
                      minHeight: 6,
                      backgroundColor:
                          tareaColor.withValues(alpha: 0.12),
                      valueColor:
                          AlwaysStoppedAnimation(tareaColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                    '${hito.progresoActual}%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tareaColor)),
              ],
            ),
            if (editable) ...[
              const SizedBox(height: 8),
              Slider(
                value: hito.progresoActual.toDouble(),
                min: 0,
                max: 100,
                divisions: 10,
                label: '${hito.progresoActual}%',
                onChanged: onProgressChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetadataItem extends StatelessWidget {
  const _MetadataItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text('$label: ',
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
