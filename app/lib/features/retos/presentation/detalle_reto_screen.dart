import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/challenge_progress_bar.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../application/retos_provider.dart';
import 'widgets/grafo_dependencias.dart';

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
        completarReto(id, ref).then((_) {
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
                              await descompletarReto(id, ref);
                            },
                            child: const Text('Desmarcar'),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              _buildMetadataCard(context, detalle.reto),
              if (detalle.reto.tieneDependencias &&
                  detalle.hitos.isNotEmpty) ...[
                const SizedBox(height: 8),
                _GrafoSection(retoId: id),
              ],
              const SizedBox(height: 8),
              if (detalle.hitos.isNotEmpty) ...[
                ChallengeProgressBar(
                    progress: detalle.progresoGeneral,
                    label: 'Progreso general'),
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
                if (esPropio && !completado)
                  _TareasOrdenables(
                    hitos: detalle.hitos,
                    retoId: id,
                    onToggle: (hitoId, completada) async {
                      await toggleTareaCompletada(hitoId, id,
                          completada: completada, ref: ref);
                    },
                    onReorder: (ids) async {
                      await reordenarTareas(id, ids, ref: ref);
                    },
                  )
                else
                  ...detalle.hitos.map((hito) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TareaControl(
                          hito: hito,
                          editable: false,
                          onToggle: (_) {},
                        ),
                      )),
              ],
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
    final tipoColor = reto.tipo == 'fitness' ? Colors.green : Colors.blue;
    final tipoLabel = reto.tipo == 'fitness' ? 'Fitness' : 'Académico';

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: reto.visibilidad == 'public'
                        ? Colors.orange.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    reto.visibilidad == 'public' ? 'Público' : 'Privado',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: reto.visibilidad == 'public'
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
        content: const Text(
            '¿Marcar este reto como completado? No se podrá editar después.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await completarReto(id, ref);
            },
            child: const Text('Completar'),
          ),
        ],
      ),
    );
  }

  void _clonar(BuildContext context, WidgetRef ref) async {
    final nuevoId = await clonarReto(id, ref);
    if (nuevoId != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reto clonado correctamente')),
      );
      context.go('/retos/$nuevoId');
    }
  }
}

class _TareasOrdenables extends StatefulWidget {
  const _TareasOrdenables({
    required this.hitos,
    required this.retoId,
    required this.onToggle,
    required this.onReorder,
  });

  final List<HitoRetoDb> hitos;
  final String retoId;
  final Future<void> Function(String hitoId, bool completada) onToggle;
  final Future<void> Function(List<String> idsOrdenados) onReorder;

  @override
  State<_TareasOrdenables> createState() => _TareasOrdenablesState();
}

class _TareasOrdenablesState extends State<_TareasOrdenables> {
  late List<HitoRetoDb> _locales;
  bool _reordenando = false;

  @override
  void initState() {
    super.initState();
    _locales = List.from(widget.hitos);
  }

  @override
  void didUpdateWidget(covariant _TareasOrdenables oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_reordenando && oldWidget.hitos != widget.hitos) {
      _locales = List.from(widget.hitos);
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      _reordenando = true;
      if (newIndex > oldIndex) newIndex--;
      final item = _locales.removeAt(oldIndex);
      _locales.insert(newIndex, item);
    });

    widget.onReorder(_locales.map((h) => h.id).toList()).then((_) {
      if (mounted) setState(() => _reordenando = false);
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _reordenando = false;
          _locales = List.from(widget.hitos);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _locales.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final hito = _locales[index];
        return Padding(
          key: ValueKey(hito.id),
          padding: const EdgeInsets.only(bottom: 8),
          child: _TareaControl(
            hito: hito,
            editable: true,
            onToggle: (completada) {
              widget.onToggle(hito.id, completada);
            },
          ),
        );
      },
    );
  }
}

class _TareaControl extends StatelessWidget {
  const _TareaControl({
    required this.hito,
    required this.editable,
    required this.onToggle,
  });

  final HitoRetoDb hito;
  final bool editable;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: editable ? () => onToggle(!hito.estaCompletado) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                hito.estaCompletado
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 22,
                color:
                    hito.estaCompletado ? Colors.green : Colors.grey.shade400,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hito.titulo,
                  style: TextStyle(
                    fontSize: 14,
                    decoration:
                        hito.estaCompletado ? TextDecoration.lineThrough : null,
                    color: hito.estaCompletado ? Colors.grey : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${hito.porcentajePeso}% del total',
                    style:
                        const TextStyle(fontSize: 10, color: Colors.blueGrey)),
              ),
            ],
          ),
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
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _GrafoSection extends ConsumerWidget {
  const _GrafoSection({required this.retoId});

  final String retoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grafoAsync = ref.watch(grafoRetoProvider(retoId));
    return grafoAsync.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (grafo) {
        if (grafo == null) return const SizedBox.shrink();
        return GrafoDependencias(grafo: grafo);
      },
    );
  }
}
