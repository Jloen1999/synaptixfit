import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
              onChanged: (v) =>
                  setState(() => _busqueda = v.trim().toLowerCase()),
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
                              .where((dto) => dto.rutina.nombre
                                  .toLowerCase()
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
                              .where((rut) =>
                                  rut.nombre.toLowerCase().contains(_busqueda))
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
                    child: const Text('Usar', style: TextStyle(fontSize: 11)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      minimumSize: const Size(0, 30),
                    ),
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: rutinas.length,
      itemBuilder: (context, index) {
        final r = rutinas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: r.visibilidad == 'private'
                    ? Colors.grey.withValues(alpha: 0.12)
                    : Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                r.visibilidad == 'private'
                    ? Icons.lock_outlined
                    : Icons.people_outline,
                size: 18,
                color: r.visibilidad == 'private'
                    ? Colors.grey
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(r.nombre,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(
              '${r.visibilidad == 'private' ? 'Privada' : 'Amigos'} · ${r.descripcion?.isNotEmpty == true ? r.descripcion! : '${r.cantidadEjercicios} ejercicios'}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/bienestar/rutina/${r.id}'),
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
