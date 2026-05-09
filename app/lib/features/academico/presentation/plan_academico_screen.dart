import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/feature_scaffold.dart';

class PlanAcademicoScreen extends StatelessWidget {
  const PlanAcademicoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Plan Académico Semanal',
      actions: [
        IconButton(
          icon: const Icon(Icons.article_outlined),
          tooltip: 'Apuntes',
          onPressed: () => context.push('/academico/apuntes'),
        ),
        IconButton(
          icon: const Icon(Icons.school_outlined),
          tooltip: 'Gestionar asignaturas',
          onPressed: () => context.push('/academico/asignaturas'),
        ),
      ],
      child: FutureBuilder<List<_BloqueHorario>>(
        future: _cargarHorarios(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bloques = snapshot.data ?? [];
          if (bloques.isEmpty) {
            return const Center(
              child: Text('No hay horarios académicos registrados.'),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final useGrid = constraints.maxWidth >= 900;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Semana actual',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (!useGrid)
                    ...bloques.map((b) => _ScheduleCard(bloque: b))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bloques.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) =>
                          _ScheduleCard(bloque: bloques[index], compact: true),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<List<_BloqueHorario>> _cargarHorarios() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return [];

    final data = await client
        .from('horarios_academicos')
        .select('*, asignaturas(nombre)')
        .eq('usuario_id', user.id)
        .order('hora_inicio', ascending: true);

    return (data as List).map((row) {
      final asigNombre =
          (row['asignaturas'] as Map<String, dynamic>?)?['nombre'] ??
              'Asignatura';
      return _BloqueHorario(
        nombre: asigNombre as String,
        horaInicio: DateTime.tryParse(row['hora_inicio']?.toString() ?? '') ??
            DateTime.now(),
        horaFin: DateTime.tryParse(row['hora_fin']?.toString() ?? '') ??
            DateTime.now(),
        ubicacion: row['ubicacion'] as String? ?? 'Sin ubicación',
        tieneConflicto: row['tiene_conflicto'] as bool? ?? false,
      );
    }).toList();
  }
}

class _BloqueHorario {
  final String nombre;
  final DateTime horaInicio;
  final DateTime horaFin;
  final String ubicacion;
  final bool tieneConflicto;

  _BloqueHorario({
    required this.nombre,
    required this.horaInicio,
    required this.horaFin,
    required this.ubicacion,
    required this.tieneConflicto,
  });
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.bloque, this.compact = false});

  final _BloqueHorario bloque;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final startHour =
        '${bloque.horaInicio.hour.toString().padLeft(2, '0')}:${bloque.horaInicio.minute.toString().padLeft(2, '0')}';
    final endHour =
        '${bloque.horaFin.hour.toString().padLeft(2, '0')}:${bloque.horaFin.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: compact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: Icon(bloque.tieneConflicto
              ? Icons.warning_amber_rounded
              : Icons.school_outlined),
          title: Text(bloque.nombre),
          subtitle: Text('$startHour - $endHour · ${bloque.ubicacion}'),
          trailing: bloque.tieneConflicto
              ? const Icon(Icons.error_outline, color: Colors.orange)
              : null,
        ),
      ),
    );
  }
}
