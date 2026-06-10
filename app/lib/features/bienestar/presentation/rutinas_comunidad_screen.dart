import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../shared/utils/string_utils.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/models/db_models.dart';
import '../application/rutina_provider.dart';

class RutinasComunidadScreen extends ConsumerStatefulWidget {
  const RutinasComunidadScreen({super.key});

  @override
  ConsumerState<RutinasComunidadScreen> createState() =>
      _RutinasComunidadScreenState();
}

class _RutinasComunidadScreenState
    extends ConsumerState<RutinasComunidadScreen> {
  int _tab = 0;
  final _busquedaCtrl = TextEditingController();
  String _busqueda = '';

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final misRutinasAsync = ref.watch(rutinasUsuarioProvider);
    final comunidadAsync = ref.watch(rutinasComunidadProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return FeatureScaffold(
      title: 'Rutinas',
      actions: [
        IconButton(
          icon: const Icon(Icons.auto_awesome),
          tooltip: 'Generar rutina con IA',
          onPressed: () => context
              .push('/bienestar/nueva-rutina', extra: {'autoRecomendar': true}),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/bienestar/nueva-rutina'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva rutina'),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _busquedaCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar rutinas...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _busquedaCtrl.clear();
                          setState(() => _busqueda = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _busqueda = normalizeSearch(v)),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Comunidad')),
                ButtonSegment(value: 1, label: Text('Mis rutinas')),
              ],
              selected: {_tab},
              onSelectionChanged: (v) => setState(() => _tab = v.first),
            ),
          ),
          Expanded(
            child: _tab == 0
                ? comunidadAsync.when(
                    data: (r) {
                      final filtrados = _busqueda.isEmpty
                          ? r
                          : r
                              .where((dto) => normalizeSearch(dto.rutina.nombre)
                                  .contains(_busqueda))
                              .toList();
                      return _buildListaComunidad(filtrados, userId);
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  )
                : misRutinasAsync.when(
                    data: (r) {
                      final filtrados = _busqueda.isEmpty
                          ? r
                          : r
                              .where((rut) => normalizeSearch(rut.nombre)
                                  .contains(_busqueda))
                              .toList();
                      return _buildListaMisRutinas(filtrados);
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaComunidad(
      List<RutinaComunidadDto> rutinas, String? userId) {
    if (rutinas.isEmpty) {
      return const EmptyState(
        icon: Icons.fitness_center_outlined,
        title: 'Sin rutinas públicas',
        message: 'Sé el primero en compartir una rutina.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: rutinas.length,
      itemBuilder: (context, index) {
        final dto = rutinas[index];
        final r = dto.rutina;
        final esPropia = userId != null && r.usuarioId == userId;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fitness_center_rounded, size: 20),
            ),
            title: Text(r.nombre,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(
                'por ${dto.autorNombre} · ${r.cantidadEjercicios} ejercicios',
                style: const TextStyle(fontSize: 12)),
            trailing: esPropia
                ? null
                : FilledButton.tonal(
                    onPressed: () => _clonarRutina(r),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      minimumSize: const Size(0, 30),
                    ),
                    child: const Text('Usar', style: TextStyle(fontSize: 11)),
                  ),
            onTap: () => _mostrarDetalleRutina(context, r.id),
          ),
        );
      },
    );
  }

  Widget _buildListaMisRutinas(List<RutinaDb> rutinas) {
    if (rutinas.isEmpty) {
      return const EmptyState(
        icon: Icons.fitness_center_outlined,
        title: 'Sin rutinas creadas',
        message: 'Crea tu primera rutina para empezar.',
      );
    }

    final progresos = ref.watch(progresoRutinasProvider).valueOrNull ?? {};

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: rutinas.length,
      itemBuilder: (context, index) {
        final r = rutinas[index];
        final theme = Theme.of(context);

        final esActiva = r.estado == 'activo' || r.estado == 'pausado';
        final prog = progresos[r.id] ??
            const ProgresoRutinaDto(diasCompletados: 0, totalDias: 0);
        final progress = prog.porcentaje;
        final colorProgreso = progress >= 1.0
            ? Colors.green
            : (progress > 0.5 ? Colors.blue : Colors.orange);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: esActiva ? 2 : 0.5,
          color: esActiva ? null : theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: esActiva
                ? BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1)
                : BorderSide(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/bienestar/rutina/${r.id}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: !esActiva
                              ? Colors.green.withValues(alpha: 0.1)
                              : (r.visibilidad == 'private'
                                  ? Colors.grey.withValues(alpha: 0.12)
                                  : theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          !esActiva
                              ? Icons.check_circle_outline
                              : (r.visibilidad == 'private'
                                  ? Icons.lock_outlined
                                  : Icons.people_outline),
                          size: 24,
                          color: !esActiva
                              ? Colors.green
                              : (r.visibilidad == 'private'
                                  ? Colors.grey
                                  : theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.nombre,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${r.visibilidad == 'private' ? 'Privada' : 'Amigos'} · ${r.cantidadEjercicios} ejercicios',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'editar', child: Text('Editar')),
                          PopupMenuItem(
                              value: 'eliminar', child: Text('Eliminar')),
                        ],
                        onSelected: (v) {
                          if (v == 'eliminar') {
                            _eliminarRutina(r);
                          } else if (v == 'editar') {
                            context.push('/bienestar/rutina/${r.id}');
                          }
                        },
                      ),
                    ],
                  ),
                  if (r.descripcion?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Text(
                      r.descripcion!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircularPercentIndicator(
                        radius: 20.0,
                        lineWidth: 4.0,
                        animation: true,
                        percent: progress,
                        center: Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 10.0),
                        ),
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: colorProgreso,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              esActiva ? 'En progreso' : 'Completada',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: !esActiva ? Colors.green.shade700 : null,
                              ),
                            ),
                            if (esActiva && progress > 0)
                              Text(
                                '${prog.diasCompletados} de ${prog.totalDias} días',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (esActiva) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.push('/bienestar/rutina/${r.id}'),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Continuar entrenamiento'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                  if (!esActiva) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _clonarRutina(r),
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Reutilizar rutina'),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarDetalleRutina(BuildContext context, String rutinaId) {
    final router = GoRouter.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RutinaDetalleSheet(rutinaId: rutinaId, router: router),
    );
  }

  Future<void> _eliminarRutina(RutinaDb rutina) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar rutina'),
        content: Text(
            '¿Estás seguro de que quieres eliminar la rutina "${rutina.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await eliminarRutina(rutina.id, ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rutina eliminada')),
        );
      }
    }
  }

  Future<void> _clonarRutina(RutinaDb rutina) async {
    await clonarRutina(rutina.id, ref);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rutina «${rutina.nombre}» copiada')),
      );
      setState(() => _tab = 1);
    }
  }
}

class _RutinaDetalleSheet extends ConsumerWidget {
  const _RutinaDetalleSheet({required this.rutinaId, required this.router});

  final String rutinaId;
  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = Supabase.instance.client;

    return FutureBuilder<Map<String, dynamic>?>(
      future: client
          .from('rutinas')
          .select('*, usuarios(nombre_completo)')
          .eq('id', rutinaId)
          .maybeSingle(),
      builder: (context, rutinaSnap) {
        final rutina = rutinaSnap.data;
        final nombre = rutina?['nombre'] as String? ?? '...';
        final desc = rutina?['descripcion'] as String? ?? '';

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: client
              .from('seleccion_de_ejercicios')
              .select('*, ejercicios(nombre)')
              .eq('rutina_id', rutinaId)
              .order('indice_orden'),
          builder: (context, ejerciciosSnap) {
            final ejercicios = ejerciciosSnap.data ?? [];

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (rutina != null &&
                          rutinaSnap.connectionState ==
                              ConnectionState.done) ...[
                        Text(nombre,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center),
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(desc,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                              textAlign: TextAlign.center),
                        ],
                        const SizedBox(height: 4),
                        if ((rutina['usuarios']
                                as Map<String, dynamic>?)?['nombre_completo'] !=
                            null)
                          Text(
                              'por ${(rutina['usuarios'] as Map<String, dynamic>)['nombre_completo']}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                      ],
                      const SizedBox(height: 12),
                      const Divider(),
                      if (ejerciciosSnap.connectionState ==
                          ConnectionState.waiting)
                        const Expanded(
                            child: Center(child: CircularProgressIndicator()))
                      else if (ejercicios.isEmpty)
                        const Expanded(
                            child: Center(
                                child: Text('Sin ejercicios',
                                    style: TextStyle(color: Colors.grey))))
                      else
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: ejercicios.length,
                            itemBuilder: (context, index) {
                              final e = ejercicios[index];
                              final ejNombre = (e['ejercicios']
                                          as Map<String, dynamic>?)?['nombre']
                                      as String? ??
                                  'Ejercicio';
                              final series = e['series'] as int? ?? 3;
                              final reps = e['repeticiones'] as int? ?? 10;
                              final descanso =
                                  e['segundos_descanso'] as int? ?? 60;

                              return ListTile(
                                dense: true,
                                leading: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text('${index + 1}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer)),
                                  ),
                                ),
                                title: Text(ejNombre,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                    '$series series · $reps reps · ${descanso}s descanso',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                                trailing:
                                    const Icon(Icons.chevron_right, size: 16),
                                onTap: () {
                                  final ejId = e['ejercicio_id'] as String;
                                  Navigator.of(context).pop();
                                  router.push('/bienestar/ejercicio/$ejId');
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
