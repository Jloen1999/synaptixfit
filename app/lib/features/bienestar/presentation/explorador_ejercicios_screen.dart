import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../shared/models/catalogo_models.dart';
import '../../../shared/widgets/exercise_card.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/ejercicios_provider.dart';

class ExploradorEjerciciosScreen extends ConsumerStatefulWidget {
  const ExploradorEjerciciosScreen({super.key});

  @override
  ConsumerState<ExploradorEjerciciosScreen> createState() =>
      _ExploradorEjerciciosScreenState();
}

class _ExploradorEjerciciosScreenState
    extends ConsumerState<ExploradorEjerciciosScreen> {
  final _searchController = TextEditingController();
  String? _filtroParteCuerpo;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ejerciciosAsync = _filtroParteCuerpo != null
        ? ref.watch(ejerciciosPorParteCuerpoProvider(_filtroParteCuerpo!))
        : ref.watch(ejerciciosProvider);

    final catalogosAsync = ref.watch(catalogosProvider);

    return FeatureScaffold(
      title: 'Explorar Ejercicios',
      backPath: '/bienestar/constructor-rutina',
      child: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar ejercicios...',
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
              onSubmitted: (_) => setState(() {}),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Chips de filtro por parte del cuerpo
          catalogosAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(height: 42),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (catalogos) => _buildFilterChips(catalogos),
          ),

          const SizedBox(height: 8),

          // Lista de ejercicios
          Expanded(
            child: ejerciciosAsync.when(
              loading: () => ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  SizedBox(height: 8),
                  SkeletonLoader(height: 80),
                  SizedBox(height: 8),
                  SkeletonLoader(height: 80),
                  SizedBox(height: 8),
                  SkeletonLoader(height: 80),
                  SizedBox(height: 8),
                  SkeletonLoader(height: 80),
                ],
              ),
              error: (error, _) => Center(
                child: EmptyState(
                  title: 'Error al cargar',
                  message: '$error',
                  icon: Icons.cloud_off_rounded,
                ),
              ),
              data: (items) {
                final query = _searchController.text.toLowerCase().trim();
                final filtrados = query.isEmpty
                    ? items
                    : items.where((e) {
                        final nombre = e.nombre.toLowerCase();
                        final musculo = e.musculoPrincipal.toLowerCase();
                        final equip = e.equipamientoPrincipal.toLowerCase();
                        return nombre.contains(query) ||
                            musculo.contains(query) ||
                            equip.contains(query);
                      }).toList();

                if (filtrados.isEmpty) {
                  return Center(
                    child: EmptyState(
                      title: 'Sin resultados',
                      message: query.isNotEmpty
                          ? 'No se encontraron ejercicios para "$query".'
                          : 'No hay ejercicios en esta categoría.',
                      icon: Icons.fitness_center_rounded,
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 760;
                    if (!isWide) {
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtrados.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = filtrados[index];
                          return ExerciseCard(
                            name: item.nombre,
                            muscleGroup: item.musculoPrincipal,
                            equipment: item.equipamientoPrincipal,
                            gifUrl: item.urlGif,
                            onTap: () => context.push(
                              '/bienestar/ejercicio/${item.id}',
                            ),
                          );
                        },
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            constraints.maxWidth >= 1080 ? 3 : 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.8,
                      ),
                      itemCount: filtrados.length,
                      itemBuilder: (context, index) {
                        final item = filtrados[index];
                        return ExerciseCard(
                          name: item.nombre,
                          muscleGroup: item.musculoPrincipal,
                          equipment: item.equipamientoPrincipal,
                          gifUrl: item.urlGif,
                          onTap: () => context.go(
                            '/bienestar/ejercicio/${item.id}',
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(CatalogosEjercicios catalogos) {
    final partes = catalogos.partesCuerpoNombres;
    final theme = Theme.of(context);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: partes.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _filtroParteCuerpo == null;
            return ChoiceChip(
              label: Text(
                'Todos',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isSelected
                      ? theme.colorScheme.onSecondaryContainer
                      : SVColors.onSurfaceVariant,
                ),
              ),
              selected: isSelected,
              selectedColor: SVColors.secondaryContainer,
              backgroundColor: SVColors.surfaceContainerLow,
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : SVColors.outlineVariant.withValues(alpha: 0.4),
              ),
              onSelected: (_) {
                setState(() => _filtroParteCuerpo = null);
              },
            );
          }

          final parte = partes[index - 1];
          final isSelected = _filtroParteCuerpo == parte;

          return ChoiceChip(
            label: Text(
              _capitalize(parte),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isSelected
                    ? theme.colorScheme.onSecondaryContainer
                    : SVColors.onSurfaceVariant,
              ),
            ),
            selected: isSelected,
            selectedColor: SVColors.secondaryContainer,
            backgroundColor: SVColors.surfaceContainerLow,
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : SVColors.outlineVariant.withValues(alpha: 0.4),
            ),
            onSelected: (_) {
              setState(() => _filtroParteCuerpo = parte);
            },
          );
        },
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
