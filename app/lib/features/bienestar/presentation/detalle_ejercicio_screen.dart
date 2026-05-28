import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../shared/models/catalogo_models.dart';
import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/exercise_media_widget.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/muscle_image_chip.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/sv_primary_button.dart';
import '../application/ejercicios_provider.dart';

class DetalleEjercicioScreen extends ConsumerWidget {
  const DetalleEjercicioScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ejercicioAsync = ref.watch(ejercicioDetalleProvider(id));
    final catalogos = ref.watch(catalogosProvider).valueOrNull;

    return ejercicioAsync.when(
      loading: () => const FeatureScaffold(
        title: 'Cargando...',
        child: Center(child: SkeletonLoader(height: 200)),
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

        return _buildContent(context, ejercicio, catalogos);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    EjercicioDb ejercicio,
    CatalogosEjercicios? catalogos,
  ) {
    return DefaultTabController(
      length: 2,
      child: FeatureScaffold(
        title: ejercicio.nombre,
        backPath: '/bienestar/explorador',
        child: Column(
          children: [
            ExerciseMediaWidget(
              url: ejercicio.urlGif,
              size: ExerciseMediaSize.hero,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ...ejercicio.musculosObjetivo.map(
                    (m) => MuscleImageChip(
                      label: m,
                      urlImagen: catalogos?.urlImagenMusculo(m),
                      color: SVColors.primary,
                    ),
                  ),
                  ...ejercicio.partesCuerpo.map(
                    (p) => _MetaChip(
                      label: p,
                      icon: Icons.accessibility_new_rounded,
                      color: SVColors.secondary,
                    ),
                  ),
                  ...ejercicio.equipamientos.map(
                    (e) => _MetaChip(
                      label: e,
                      icon: Icons.hardware_rounded,
                      color: SVColors.tertiary,
                    ),
                  ),
                  _MetaChip(
                    label: ejercicio.dificultad,
                    icon: Icons.speed_rounded,
                    color: SVColors.accent,
                  ),
                  _MetaChip(
                    label:
                        '${ejercicio.finalidad.icono} ${ejercicio.finalidad.etiqueta}',
                    icon: Icons.category_rounded,
                    color: _finalidadColor(ejercicio.finalidad),
                  ),
                ],
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Instrucciones'),
                Tab(text: 'Informacion'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _InstruccionesTab(instrucciones: ejercicio.instrucciones),
                  _InfoTab(
                    descripcion: ejercicio.descripcion,
                    musculosSecundarios: ejercicio.musculosSecundarios,
                    catalogos: catalogos,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SVPrimaryButton(
                label: 'Agregar a rutina',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${ejercicio.nombre} agregado a la rutina',
                      ),
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
  }
}

Color _finalidadColor(FinalidadEjercicio f) {
  switch (f) {
    case FinalidadEjercicio.fuerza:
      return Colors.orange;
    case FinalidadEjercicio.cardio:
      return Colors.teal;
    case FinalidadEjercicio.isometrico:
      return Colors.indigo;
  }
}

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.85),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstruccionesTab extends StatelessWidget {
  const _InstruccionesTab({required this.instrucciones});
  final List<String> instrucciones;

  @override
  Widget build(BuildContext context) {
    if (instrucciones.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('Sin instrucciones disponibles.'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: instrucciones.length,
      separatorBuilder: (_, __) => const SizedBox(height: 1),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: SVColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: SVColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _limpiarPrefijoPaso(instrucciones[index]),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _limpiarPrefijoPaso(String texto) {
    return texto.replaceFirst(RegExp(r'^Paso:\s*\d+\s*'), '').trim();
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({
    this.descripcion,
    required this.musculosSecundarios,
    this.catalogos,
  });

  final String? descripcion;
  final List<String> musculosSecundarios;
  final CatalogosEjercicios? catalogos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (descripcion != null && descripcion!.isNotEmpty) ...[
          _sectionTitle(context, 'Descripcion'),
          const SizedBox(height: 10),
          Text(
            descripcion!,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),
        ],
        if (musculosSecundarios.isNotEmpty) ...[
          _sectionTitle(context, 'Musculos secundarios'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: musculosSecundarios
                .map(
                  (m) => MuscleImageChip(
                    label: m,
                    urlImagen: catalogos?.urlImagenMusculo(m),
                    color: SVColors.primary,
                    compact: true,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
