import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/sv_primary_button.dart';
import '../application/ejercicios_provider.dart';

/// Pantalla de detalle de un ejercicio.
/// Muestra GIF animado, instrucciones paso a paso y metadatos.
class DetalleEjercicioScreen extends ConsumerWidget {
  const DetalleEjercicioScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ejercicioAsync = ref.watch(ejercicioDetalleProvider(id));

    return ejercicioAsync.when(
      loading: () => const FeatureScaffold(
        title: 'Cargando...',
        child: Center(child: SkeletonLoader()),
      ),
      error: (error, _) => FeatureScaffold(
        title: 'Error',
        child: Center(child: Text('Error: $error')),
      ),
      data: (ejercicio) {
        if (ejercicio == null) {
          return const FeatureScaffold(
            title: 'No encontrado',
            child: Center(child: Text('Ejercicio no disponible')),
          );
        }

        return DefaultTabController(
          length: 2,
          child: FeatureScaffold(
            title: ejercicio.nombre,
            backPath: '/bienestar/ejercicios',
            child: Column(
              children: [
                // Hero: GIF animado
                _GifHero(urlGif: ejercicio.urlGif),

                // Chips de metadatos
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ...ejercicio.musculosObjetivo.map(
                        (m) => _MetaChip(
                            label: m,
                            icon: Icons.sports_gymnastics,
                            color: SVColors.primary),
                      ),
                      ...ejercicio.partesCuerpo.map(
                        (p) => _MetaChip(
                            label: p,
                            icon: Icons.accessibility_new,
                            color: SVColors.secondary),
                      ),
                      ...ejercicio.equipamientos.map(
                        (e) => _MetaChip(
                            label: e,
                            icon: Icons.hardware,
                            color: SVColors.tertiary),
                      ),
                    ],
                  ),
                ),

                // Tabs
                const TabBar(
                  tabs: [
                    Tab(text: 'Instrucciones'),
                    Tab(text: 'Info'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Instrucciones paso a paso
                      _InstruccionesTab(instrucciones: ejercicio.instrucciones),

                      // Tab 2: Información general
                      _InfoTab(
                        descripcion: ejercicio.descripcion,
                        dificultad: ejercicio.dificultad,
                        musculosSecundarios: ejercicio.musculosSecundarios,
                        exerciseDbId: ejercicio.exerciseDbId,
                      ),
                    ],
                  ),
                ),

                // Botón de acción
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SVPrimaryButton(
                    label: 'Agregar a rutina',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('${ejercicio.nombre} agregado a la rutina'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets privados
// ---------------------------------------------------------------------------

/// Hero image: muestra el GIF animado del ejercicio.
class _GifHero extends StatelessWidget {
  const _GifHero({this.urlGif});
  final String? urlGif;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth >= 900 ? 280.0 : 220.0;

        return Container(
          height: size,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SVColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: urlGif != null
              ? CachedNetworkImage(
                  imageUrl: urlGif!,
                  width: double.infinity,
                  height: size,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (_, __, ___) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image,
                            size: 48, color: SVColors.textSecondary),
                        const SizedBox(height: 8),
                        Text(
                          'GIF no disponible',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: Icon(Icons.fitness_center,
                      size: 56, color: SVColors.textSecondary),
                ),
        );
      },
    );
  }
}

/// Chip de metadato con ícono y color.
class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Tab de instrucciones paso a paso.
class _InstruccionesTab extends StatelessWidget {
  const _InstruccionesTab({required this.instrucciones});
  final List<String> instrucciones;

  @override
  Widget build(BuildContext context) {
    if (instrucciones.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Sin instrucciones disponibles.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: instrucciones.length,
      separatorBuilder: (_, __) => const Divider(height: 24),
      itemBuilder: (context, index) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Número del paso
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: SVColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: SVColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            // Texto de la instrucción (limpiamos el prefijo "Paso: X")
            Expanded(
              child: Text(
                _limpiarPrefijoPaso(instrucciones[index]),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Elimina el prefijo "Paso: N " o "Paso:N " del texto.
  String _limpiarPrefijoPaso(String texto) {
    return texto.replaceFirst(RegExp(r'^Paso:\s*\d+\s*'), '').trim();
  }
}

/// Tab con información general del ejercicio.
class _InfoTab extends StatelessWidget {
  const _InfoTab({
    this.descripcion,
    required this.dificultad,
    required this.musculosSecundarios,
    this.exerciseDbId,
  });

  final String? descripcion;
  final String dificultad;
  final List<String> musculosSecundarios;
  final String? exerciseDbId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (descripcion != null && descripcion!.isNotEmpty) ...[
          Text('Descripción', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(descripcion!, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
        ],

        // Dificultad
        _InfoRow(
          icon: Icons.speed,
          label: 'Dificultad',
          value: _capitalize(dificultad),
        ),
        const SizedBox(height: 12),

        // Músculos secundarios
        if (musculosSecundarios.isNotEmpty) ...[
          _InfoRow(
            icon: Icons.sports_gymnastics,
            label: 'Músculos secundarios',
            value: musculosSecundarios.map(_capitalize).join(', '),
          ),
          const SizedBox(height: 12),
        ],

        // ID de ExerciseDB
        if (exerciseDbId != null) ...[
          _InfoRow(
            icon: Icons.tag,
            label: 'ID ExerciseDB',
            value: exerciseDbId!,
          ),
        ],
      ],
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

/// Fila de información con ícono y texto.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: SVColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
