import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../shared/utils/string_utils.dart';
import '../../../shared/widgets/badge_reutilizado.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/exercise_metrics.dart';
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
  String _filtroEstado = 'todas'; // 'todas' | 'activas' | 'completadas'

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
                ButtonSegment(value: 0, label: Text('Mis rutinas')),
                ButtonSegment(value: 1, label: Text('Comunidad')),
              ],
              selected: {_tab},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _tab = v.first),
            ),
          ),
          if (_tab == 0) _buildFiltroEstado(),
          Expanded(
            child: _tab == 0
                ? misRutinasAsync.when(
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
                  )
                : comunidadAsync.when(
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
                  ),
          ),
        ],
      ),
    );
  }

  /// Barra de filtros por estado para «Mis rutinas» (CLEAN UI).
  Widget _buildFiltroEstado() {
    Widget chip(String label, String value) {
      final sel = _filtroEstado == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          selected: sel,
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          onSelected: (_) => setState(() => _filtroEstado = value),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip('Todas', 'todas'),
          chip('Activas', 'activas'),
          chip('Completadas', 'completadas'),
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

    bool estaCompletada(RutinaDb r) {
      final esActiva = r.estado == 'activo' || r.estado == 'pausado';
      final prog = progresos[r.id] ??
          const ProgresoRutinaDto(diasCompletados: 0, totalDias: 0);
      return prog.porcentaje >= 1.0 || !esActiva;
    }

    final filtradas = switch (_filtroEstado) {
      'activas' => rutinas.where((r) => !estaCompletada(r)).toList(),
      'completadas' => rutinas.where(estaCompletada).toList(),
      _ => rutinas,
    };

    if (filtradas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 32),
        child: EmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: 'Sin resultados',
          message: _filtroEstado == 'activas'
              ? 'No tienes rutinas activas.'
              : 'No tienes rutinas completadas.',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: filtradas.length,
      itemBuilder: (context, index) {
        final r = filtradas[index];
        final theme = Theme.of(context);

        final esActiva = r.estado == 'activo' || r.estado == 'pausado';
        final prog = progresos[r.id] ??
            const ProgresoRutinaDto(diasCompletados: 0, totalDias: 0);
        final progress = prog.porcentaje;
        final completada = progress >= 1.0 || !esActiva;
        final esPrivada = r.visibilidad == 'private';
        final colorAcento = completada
            ? Colors.green
            : (esPrivada ? Colors.grey : theme.colorScheme.primary);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push('/bienestar/rutina/${r.id}'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorAcento.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      completada
                          ? Icons.check_circle_outline
                          : (esPrivada
                              ? Icons.lock_outline
                              : Icons.people_outline),
                      size: 20,
                      color: colorAcento,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          r.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${esPrivada ? 'Privada' : 'Amigos'} · ${r.cantidadEjercicios} ejercicios'
                          '${completada ? ' · Completada' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (r.esReutilizada) ...[
                          const SizedBox(height: 3),
                          const BadgeReutilizado(
                            dense: true,
                            etiqueta: 'Reutilizada',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircularPercentIndicator(
                    radius: 18.0,
                    lineWidth: 3.5,
                    percent: progress.clamp(0.0, 1.0),
                    center: Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 9),
                    ),
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: colorAcento,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    padding: EdgeInsets.zero,
                    tooltip: 'Opciones',
                    onSelected: (v) {
                      if (v == 'eliminar') {
                        _eliminarRutina(r);
                      } else if (v == 'editar') {
                        context.push('/bienestar/rutina/${r.id}');
                      } else if (v == 'reutilizar') {
                        _clonarRutina(r);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'editar', child: Text('Editar')),
                      if (completada)
                        const PopupMenuItem(
                            value: 'reutilizar', child: Text('Reutilizar')),
                      const PopupMenuItem(
                          value: 'eliminar', child: Text('Eliminar')),
                    ],
                  ),
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
      setState(() => _tab = 0);
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
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: ExerciseMetricsRow(
                                    dense: true,
                                    categoria: ExerciseMetricCategoria.fuerza,
                                    series: series,
                                    repeticiones: reps,
                                    segundosDescanso: descanso,
                                  ),
                                ),
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
