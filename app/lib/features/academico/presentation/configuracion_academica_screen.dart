import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../application/catalogo_provider.dart';
import '../application/asignaturas_provider.dart';
import '../application/usuario_carreras_provider.dart';

class ConfiguracionAcademicaScreen extends ConsumerStatefulWidget {
  const ConfiguracionAcademicaScreen({super.key});

  @override
  ConsumerState<ConfiguracionAcademicaScreen> createState() =>
      _ConfiguracionAcademicaScreenState();
}

class _ConfiguracionAcademicaScreenState
    extends ConsumerState<ConfiguracionAcademicaScreen> {
  String? _universidadId;
  String? _carreraId;

  @override
  Widget build(BuildContext context) {
    final universidadesAsync = ref.watch(universidadesProvider);
    final carrerasAsync = _universidadId != null
        ? ref.watch(carrerasPorUniversidadProvider(_universidadId!))
        : null;
    final asignaturasAsync = _carreraId != null
        ? ref.watch(catalogoAsignaturasPorCarreraProvider(_carreraId!))
        : null;
    final carrerasUsuario =
        ref.watch(usuarioCarrerasProvider).valueOrNull ?? [];
    final carrerasAgregadasIds =
        carrerasUsuario.map((uc) => uc.carreraId).toSet();

    return FeatureScaffold(
      title: 'Configuración académica',
      floatingActionButton: _carreraId != null
          ? FloatingActionButton.extended(
              onPressed: () => _cargarAsignaturas(context),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Cargar asignaturas'),
            )
          : null,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Selecciona tu universidad y carrera',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Cargaremos automáticamente las asignaturas de tu plan de estudios.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),

          // Universidad
          universidadesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (universidades) => DropdownButtonFormField<String>(
              value: _universidadId,
              isExpanded: true,
              decoration:
                  const InputDecoration(labelText: 'Universidad'),
              items: universidades
                  .map((u) => DropdownMenuItem(
                      value: u.id, child: Text(u.nombre, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() {
                _universidadId = v;
                _carreraId = null;
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Carrera
          if (_universidadId != null && carrerasAsync != null)
            carrerasAsync.when(
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Text('Error: $e'),
              data: (carreras) {
                if (carreras.isEmpty) {
                  return const Text(
                      'No hay carreras disponibles para esta universidad.');
                }
                return DropdownButtonFormField<String>(
                  value: _carreraId,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: 'Carrera'),
                  items: carreras
                      .map((c) {
                    final yaAgregada = carrerasAgregadasIds.contains(c.id);
                    return DropdownMenuItem(
                        value: c.id,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(c.nombre,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (yaAgregada) ...[
                              const SizedBox(width: 8),
                              Text('✓ Añadida',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ],
                        ));
                  }).toList(),
                  onChanged: (v) =>
                      setState(() => _carreraId = v),
                );
              },
            ),

          // Asignaturas del catálogo (preview)
          if (_carreraId != null) ...[
            const SizedBox(height: 20),
            Text('Asignaturas de esta carrera',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (asignaturasAsync != null)
              asignaturasAsync.when(
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Text('Error: $e'),
              data: (asignaturas) {
                if (asignaturas.isEmpty) {
                  return const Text(
                      'No hay asignaturas registradas para esta carrera.');
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: asignaturas
                          .map((a) => ListTile(
                                dense: true,
                                leading:
                                    const Icon(Icons.book_outlined, size: 20),
                                title: Text(a.nombre,
                                    style:
                                        const TextStyle(fontSize: 14)),
                                subtitle: a.caracter != null
                                    ? Text('${a.caracter} · ${a.creditos ?? 0} ECTS',
                                        style:
                                            const TextStyle(fontSize: 11))
                                    : null,
                              ))
                          .toList(),
                    ),
                  ),
                );
              },
            ),
          ],

          if (_carreraId == null) ...[
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Omitir — lo haré después'),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _cargarAsignaturas(BuildContext context) async {
    if (_carreraId == null) return;

    // Verificar si la carrera ya está añadida
    final carrerasUsuario =
        ref.read(usuarioCarrerasProvider).valueOrNull ?? [];
    final yaAgregada = carrerasUsuario
        .any((uc) => uc.carreraId == _carreraId);
    if (yaAgregada) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Esta carrera ya la tienes añadida con sus asignaturas.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final asignaturasAsync =
        ref.read(catalogoAsignaturasPorCarreraProvider(_carreraId!));
    final asignaturas = asignaturasAsync.valueOrNull ?? [];

    if (asignaturas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay asignaturas para cargar.')),
      );
      return;
    }

    final total = asignaturas.length;
    final nuevasIds = <String>[];
    int creadas = 0;
    final progresoNotifier = ValueNotifier(0);
    final anadidasNotifier = ValueNotifier(0);

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ValueListenableBuilder<int>(
        valueListenable: progresoNotifier,
        builder: (ctx, proc, _) {
          return ValueListenableBuilder<int>(
            valueListenable: anadidasNotifier,
            builder: (ctx, anadidas, _) {
              return AlertDialog(
                title: const Text('Cargando asignaturas'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: total > 0 ? proc / total : null,
                    ),
                    const SizedBox(height: 16),
                    Text('$proc de $total procesadas'),
                    const SizedBox(height: 4),
                    Text('$anadidas añadidas',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.green)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );

    for (final a in asignaturas) {
      final existente = await _existeAsignatura(a.nombre);
      if (!existente) {
        final codigo = a.caracter != null && a.curso != null
            ? '${a.caracter!.substring(0, 3)}-${a.curso}S${a.semestre ?? 1}'
            : null;
        final descripcion = [
          if (a.curso != null) 'Curso ${a.curso}',
          if (a.semestre != null) 'Sem ${a.semestre}',
          if (a.caracter != null) a.caracter,
          if (a.creditos != null) '${a.creditos} ECTS',
        ].join(' · ');

        final creada = await crearAsignatura(
          nombre: a.nombre,
          codigo: codigo,
          descripcion: descripcion.isNotEmpty ? descripcion : null,
        );
        if (creada != null) {
          nuevasIds.add(creada.id);
          creadas++;
          anadidasNotifier.value = creadas;
        }
      }
      progresoNotifier.value = progresoNotifier.value + 1;
    }

    // Persistir la asociación de carrera
    await agregarCarrera(_carreraId!, ref);

    progresoNotifier.dispose();
    anadidasNotifier.dispose();

    if (context.mounted) {
      Navigator.of(context).pop();
      ref.invalidate(asignaturasActivasProvider);
      ref.invalidate(asignaturasArchivadasProvider);
      context.go('/academico/asignaturas',
          extra: {'nuevasIds': nuevasIds});
    }
  }

  Future<bool> _existeAsignatura(String nombre) async {
    final asignaturas =
        ref.read(asignaturasActivasProvider).valueOrNull ?? [];
    return asignaturas.any(
        (a) => a.nombre.toLowerCase() == nombre.toLowerCase());
  }
}
