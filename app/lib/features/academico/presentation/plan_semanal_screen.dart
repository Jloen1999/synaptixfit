import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/feature_scaffold.dart';

class PlanSemanalScreen extends StatelessWidget {
  const PlanSemanalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Plan Semanal Integrado',
      backPath: '/dashboard',
      child: FutureBuilder<_PlanSemanalData>(
        future: _cargarDatos(),
        builder: (context, snapshot) {
          final data = snapshot.data;
          final sesiones = data?.sesiones ?? 0;
          final calorias = data?.calorias ?? 0;
          final retosActivos = data?.retosActivos ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Card(
                child: ListTile(
                  leading: Icon(Icons.layers_outlined),
                  title: Text('Capas activas: Académico, Deporte, Retos'),
                  subtitle: Text('Vista combinada de la semana'),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.insights_outlined),
                  title: const Text('Resumen diario'),
                  subtitle: Text(
                      'Sesiones: $sesiones · Calorías: $calorias · Retos activos: $retosActivos'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_PlanSemanalData> _cargarDatos() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return _PlanSemanalData(0, 0, 0);

    final sesionesData = await client
        .from('sesiones_registradas')
        .select()
        .eq('usuario_id', user.id);

    final caloriasTotal = (sesionesData as List).fold<int>(
      0,
      (total, s) => total + ((s['calorias_quemadas'] ?? 0) as num).round(),
    );

    final retosData = await client
        .from('retos')
        .select('id')
        .eq('usuario_id', user.id)
        .eq('esta_completado', false);

    return _PlanSemanalData(
      (sesionesData as List).length,
      caloriasTotal,
      (retosData as List).length,
    );
  }
}

class _PlanSemanalData {
  final int sesiones;
  final int calorias;
  final int retosActivos;
  _PlanSemanalData(this.sesiones, this.calorias, this.retosActivos);
}
