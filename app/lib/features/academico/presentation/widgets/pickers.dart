import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../retos/application/retos_core.dart';
import '../../domain/calendar_dtos.dart';

/// Selector reutilizable de rutinas deportivas con estado vacío.
class RoutinePicker extends ConsumerWidget {
  const RoutinePicker({
    required this.onSelected,
    required this.rutinas,
    super.key,
  });

  final ValueChanged<RutinaActivaItem> onSelected;
  final List<RutinaActivaItem> rutinas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rutinas.isEmpty) {
      return _EmptyState(
        icon: Icons.fitness_center_rounded,
        titulo: 'Sin rutinas activas',
        mensaje: 'Crea tu primera rutina de entrenamiento',
        botonLabel: 'Crear rutina',
        onTap: () => context.push('/bienestar/nueva-rutina'),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rutinas
          .map((r) => ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fitness_center,
                      color: Color(0xFFF97316), size: 18),
                ),
                title: Text(r.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${r.objetivo} · ${r.duracionSemanas} semanas · ${r.cantidadEjercicios} ejercicios'),
                onTap: () => onSelected(r),
              ))
          .toList(),
    );
  }
}

/// Selector reutilizable de retos con estado vacío.
class ChallengePicker extends ConsumerWidget {
  const ChallengePicker({
    required this.onSelected,
    required this.retos,
    super.key,
  });

  final ValueChanged<RetoResumen> onSelected;
  final List<RetoResumen> retos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activos = retos.where((r) => !r.reto.estaCompletado).toList();

    if (activos.isEmpty) {
      return _EmptyState(
        icon: Icons.emoji_events_rounded,
        titulo: 'Sin retos activos',
        mensaje: 'Crea tu primer reto para gamificar tu progreso',
        botonLabel: 'Crear reto',
        onTap: () => context.push('/retos/crear'),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: activos.map((r) {
        final color = r.reto.tipo == 'academico'
            ? const Color(0xFF7B1FA2)
            : const Color(0xFFF97316);
        return ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              r.reto.tipo == 'academico' ? Icons.school : Icons.fitness_center,
              color: color,
              size: 18,
            ),
          ),
          title: Text(r.reto.titulo,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${(r.progreso * 100).round()}% completado'),
          trailing: SizedBox(
            width: 60,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: r.progreso,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          onTap: () => onSelected(r),
        );
      }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.titulo,
    required this.mensaje,
    required this.botonLabel,
    required this.onTap,
  });

  final IconData icon;
  final String titulo, mensaje, botonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(titulo,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(mensaje,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade500)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add, size: 16),
              label: Text(botonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
