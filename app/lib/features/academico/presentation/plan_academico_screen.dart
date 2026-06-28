import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../application/planes_estudio_provider.dart';

class PlanAcademicoScreen extends ConsumerWidget {
  const PlanAcademicoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horariosAsync = ref.watch(horariosSemanaActualProvider);

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
          tooltip: 'Configuración académica',
          onPressed: () => context.push('/academico/configuracion'),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          tooltip: 'Nuevo plan semanal',
          onPressed: () => context.push('/academico/planificar'),
        ),
      ],
      child: horariosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (horarios) {
          if (horarios.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No hay horarios académicos registrados.',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => context.push('/academico/planificar'),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear plan semanal'),
                  ),
                ],
              ),
            );
          }

          // Agrupar por tipo_actividad + hora
          final ahora = DateTime.now();
          final hoyInicio = DateTime(ahora.year, ahora.month, ahora.day);
          final hoyFin =
              DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);

          final hoy = horarios.where((h) {
            return h.horaInicio
                    .isAfter(hoyInicio.subtract(const Duration(minutes: 30))) &&
                h.horaInicio.isBefore(hoyFin.add(const Duration(minutes: 30)));
          }).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final useGrid = constraints.maxWidth >= 900;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Hoy', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (hoy.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Sin actividades programadas para hoy.'),
                      ),
                    )
                  else if (!useGrid)
                    ...hoy.map((b) => _ScheduleCard(bloque: b))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: hoy.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) =>
                          _ScheduleCard(bloque: hoy[index], compact: true),
                    ),
                  const SizedBox(height: 24),
                  Text('Esta semana',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (!useGrid)
                    ...horarios
                        .where((h) => !hoy.contains(h))
                        .take(10)
                        .map((b) => _ScheduleCard(bloque: b))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: horarios.where((h) => !hoy.contains(h)).length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final resto =
                            horarios.where((h) => !hoy.contains(h)).toList();
                        if (index >= resto.length) {
                          return const SizedBox.shrink();
                        }
                        return _ScheduleCard(
                            bloque: resto[index], compact: true);
                      },
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.bloque, this.compact = false});

  final dynamic bloque;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final startHour =
        '${bloque.horaInicio.hour.toString().padLeft(2, '0')}:${bloque.horaInicio.minute.toString().padLeft(2, '0')}';
    final endHour =
        '${bloque.horaFin.hour.toString().padLeft(2, '0')}:${bloque.horaFin.minute.toString().padLeft(2, '0')}';

    final tipo = bloque.tipoActividad ?? 'estudio';
    final (color, icono) = switch (tipo) {
      'clase' => (Colors.purple, Icons.school_outlined),
      'deporte' => (const Color(0xFF00ACC1), Icons.fitness_center_rounded),
      _ => (Colors.blue, Icons.menu_book_rounded),
    };

    return Padding(
      padding: compact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.15)),
        ),
        child: ListTile(
          leading: Icon(icono, color: color),
          title: Text(bloque.asignaturaId ?? 'Sin asignatura'),
          subtitle: Text('$startHour - $endHour'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              switch (tipo) {
                'clase' => 'Clase',
                'deporte' => 'Deporte',
                _ => 'Estudio',
              },
              style: TextStyle(
                  fontSize: 9, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
