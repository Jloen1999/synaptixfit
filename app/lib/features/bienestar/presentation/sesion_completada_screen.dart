import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/sesion_provider.dart';
import '../application/rutina_provider.dart';

class SesionCompletadaScreen extends ConsumerWidget {
  const SesionCompletadaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesionesAsync = ref.watch(sesionesProvider);
    final rutinasAsync = ref.watch(rutinasUsuarioProvider);
    final tieneRutinas = rutinasAsync.valueOrNull?.isNotEmpty ?? false;

    return FeatureScaffold(
      title: 'Sesiones',
      backPath: '/bienestar/constructor-rutina',
      floatingActionButton: tieneRutinas
          ? FloatingActionButton.extended(
              onPressed: () => _mostrarDialogoRegistrar(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Registrar sesión'),
            )
          : null,
      child: sesionesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (sesiones) {
          if (sesiones.isEmpty) {
            return const EmptyState(
              icon: Icons.fitness_center_outlined,
              title: 'Sin sesiones',
              message: 'Registra tu primera sesión de entrenamiento.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(sesionesProvider);
              return ref.read(sesionesProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                const SizedBox(height: 12),
                ...sesiones.map((s) => _SesionCard(sesion: s)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _mostrarDialogoRegistrar(BuildContext context, WidgetRef ref) {
    final rutinasAsync = ref.read(rutinasUsuarioProvider);
    final rutinas = rutinasAsync.valueOrNull ?? [];
    if (rutinas.isEmpty) return;

    String? rutinaId = rutinas.first.id;
    double duracion = 45;
    int rpe = 5;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Registrar sesión'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: rutinaId,
                  decoration: const InputDecoration(labelText: 'Rutina'),
                  items: rutinas
                      .map((r) =>
                          DropdownMenuItem(value: r.id, child: Text(r.nombre)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => rutinaId = v),
                ),
                const SizedBox(height: 16),
                Text('Duración: ${duracion.round()} min',
                    style: Theme.of(ctx).textTheme.bodyMedium),
                Slider(
                  value: duracion,
                  min: 5,
                  max: 120,
                  divisions: 23,
                  label: '${duracion.round()} min',
                  onChanged: (v) => setDialogState(() => duracion = v),
                ),
                const SizedBox(height: 8),
                Text('Esfuerzo: $rpe/10',
                    style: Theme.of(ctx).textTheme.bodyMedium),
                Slider(
                  value: rpe.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$rpe',
                  onChanged: (v) => setDialogState(() => rpe = v.round()),
                ),
                const SizedBox(height: 4),
                Text(
                  'Calorías estimadas: ${(duracion * rpe * 0.8).round()} kcal',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (rutinaId == null) return;
                await registrarSesion(
                  rutinaId: rutinaId!,
                  duracionMinutos: duracion.round(),
                  rpe: rpe,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(sesionesProvider);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SesionCard extends ConsumerWidget {
  const _SesionCard({required this.sesion});

  final SesionRegistradaDb sesion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutinasAsync = ref.watch(rutinasUsuarioProvider);
    final nombreRutina = rutinasAsync.whenOrNull(
          data: (rs) =>
              rs.where((r) => r.id == sesion.rutinaId).firstOrNull?.nombre ??
              'Rutina',
        ) ??
        'Rutina';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.celebration, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombreRutina,
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        '${sesion.duracionMinutos} min · Esfuerzo ${sesion.rpe} · ${sesion.caloriasQuemadas.round()} kcal',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '+${sesion.duracionMinutos * 2 + sesion.rpe * 3} XP',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
