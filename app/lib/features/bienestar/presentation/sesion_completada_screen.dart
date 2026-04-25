import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/kpi_card.dart';

class SesionCompletadaScreen extends ConsumerWidget {
  const SesionCompletadaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<SesionRegistradaDb>>(
      future: _cargarSesiones(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const FeatureScaffold(
            title: 'Sesión Completada',
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final sesiones = snapshot.data ?? [];
        if (sesiones.isEmpty) {
          return const FeatureScaffold(
            title: 'Sesión Completada',
            child: Center(child: Text('No hay sesiones registradas todavía.')),
          );
        }

        final sesion = sesiones.first;
        final xpGanada = sesion.duracionMinutos * 2 + (sesion.rpe * 3);

        return FeatureScaffold(
          title: 'Sesión Completada',
          backPath: '/bienestar/constructor-rutina',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useGrid = constraints.maxWidth >= 760;
              final cards = [
                KpiCard(
                    title: 'Duración',
                    value: '${sesion.duracionMinutos} min',
                    icon: Icons.timer_outlined),
                KpiCard(
                  title: 'Calorías',
                  value: '${sesion.caloriasQuemadas.round()} kcal',
                  icon: Icons.local_fire_department_outlined,
                ),
                KpiCard(
                    title: 'XP ganada',
                    value: '+$xpGanada XP',
                    icon: Icons.stars_outlined),
              ];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.celebration,
                              size: 64, color: Colors.orange),
                          const SizedBox(height: 12),
                          const Text('Entrenamiento completado'),
                          const SizedBox(height: 6),
                          FutureBuilder<String>(
                            future: _nombreRutina(sesion.rutinaId),
                            builder: (ctx, snap) =>
                                Text(snap.data ?? 'Rutina registrada'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!useGrid)
                    ...cards.expand(
                      (card) => [
                        card,
                        const SizedBox(height: 12),
                      ],
                    )
                  else
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.9,
                      children: cards,
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<List<SesionRegistradaDb>> _cargarSesiones() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return [];

    final data = await client
        .from('sesiones_registradas')
        .select()
        .eq('usuario_id', user.id)
        .order('completada_en', ascending: false)
        .limit(5);

    return (data as List)
        .map((s) => SesionRegistradaDb.fromMap(s as Map<String, dynamic>))
        .toList();
  }

  Future<String> _nombreRutina(String rutinaId) async {
    try {
      final result = await Supabase.instance.client
          .from('rutinas')
          .select('nombre')
          .eq('id', rutinaId)
          .maybeSingle();
      return result?['nombre'] as String? ?? 'Rutina registrada';
    } catch (_) {
      return 'Rutina registrada';
    }
  }
}
