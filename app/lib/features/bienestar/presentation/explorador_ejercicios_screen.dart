import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../shared/utils/string_utils.dart';
import '../../../shared/models/catalogo_models.dart';
import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/exercise_card.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton_loader.dart';
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
  int _tabSeleccionado = 0;
  String? _filtroSeleccionado;
  String _busqueda = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  FiltroEjercicios _buildFiltro() {
    if (_filtroSeleccionado == null) return const FiltroEjercicios();
    if (_busqueda.isNotEmpty) {
      return FiltroEjercicios(tipo: FiltroTipo.busqueda, valor: _busqueda);
    }
    switch (_tabSeleccionado) {
      case 0:
        return FiltroEjercicios(
            tipo: FiltroTipo.parteCuerpo, valor: _filtroSeleccionado!);
      case 1:
        return FiltroEjercicios(
            tipo: FiltroTipo.musculo, valor: _filtroSeleccionado!);
      case 2:
        return FiltroEjercicios(
            tipo: FiltroTipo.equipamiento, valor: _filtroSeleccionado!);
      case 3:
        return FiltroEjercicios(
            tipo: FiltroTipo.finalidad, valor: _filtroSeleccionado!);
      default:
        return const FiltroEjercicios();
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogosAsync = ref.watch(catalogosProvider);
    final ejerciciosFiltrados =
        ref.watch(ejerciciosFiltradosProvider(_buildFiltro()));

    return FeatureScaffold(
      title: 'Explorar Ejercicios',
      backPath: '/bienestar',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar ejercicios...',
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _busqueda = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _busqueda = normalizeSearch(v)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Partes')),
                ButtonSegment(value: 1, label: Text('Músculos')),
                ButtonSegment(value: 2, label: Text('Equipo')),
                ButtonSegment(value: 3, label: Text('Finalidad')),
              ],
              selected: {_tabSeleccionado},
              onSelectionChanged: (v) {
                setState(() {
                  _tabSeleccionado = v.first;
                  _filtroSeleccionado = null;
                });
              },
            ),
          ),
          _buildFilterChips(catalogosAsync.valueOrNull),
          const SizedBox(height: 8),
          Expanded(
            child: _searchController.text.isNotEmpty &&
                    _busqueda.isNotEmpty &&
                    _filtroSeleccionado == null
                ? _buildSearchResults(ejerciciosFiltrados)
                : _buildEjerciciosList(ejerciciosFiltrados),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<EjercicioDb> items) {
    final filtrados = items
        .where((e) =>
            normalizeSearch(e.nombre).contains(_busqueda) ||
            normalizeSearch(e.musculoPrincipal).contains(_busqueda) ||
            normalizeSearch(e.equipamientoPrincipal).contains(_busqueda))
        .toList();

    if (filtrados.isEmpty) {
      return Center(
        child: EmptyState(
          title: 'Sin resultados',
          message: 'No hay ejercicios para "$_busqueda".',
          icon: Icons.fitness_center_rounded,
        ),
      );
    }
    return _buildGridOrList(filtrados);
  }

  Widget _buildEjerciciosList(List<EjercicioDb> items) {
    if (items.isEmpty) {
      if (_filtroSeleccionado != null) {
        return const Center(
          child: EmptyState(
            title: 'Sin ejercicios',
            message: 'No hay ejercicios en esta categoría.',
            icon: Icons.fitness_center_rounded,
          ),
        );
      }
      return ListView(
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
      );
    }

    return _buildGridOrList(items);
  }

  Widget _buildGridOrList(List<EjercicioDb> items) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(ejerciciosProvider),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          if (!isWide) {
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _buildExerciseTile(items[index]);
              },
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth >= 1080 ? 3 : 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.8,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildExerciseTile(items[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildExerciseTile(EjercicioDb item) {
    final catalogos = ref.read(catalogosProvider).valueOrNull;
    final muscleImageUrl = catalogos?.urlImagenMusculo(item.musculoPrincipal);

    return ExerciseCard(
      name: item.nombre,
      muscleGroup: item.musculoPrincipal,
      equipment: item.equipamientoPrincipal,
      gifUrl: item.urlGif,
      previewUrl: item.urlPreview,
      muscleImageUrl: muscleImageUrl,
      onTap: () => context.push('/bienestar/ejercicio/${item.id}'),
    );
  }

  Widget _buildFilterChips(CatalogosEjercicios? catalogos) {
    final finalidades = ref.watch(finalidadesDisponiblesProvider);
    final nombres = switch (_tabSeleccionado) {
      0 => catalogos?.partesCuerpoNombres ?? [],
      1 => catalogos?.musculosNombres ?? [],
      2 => catalogos?.equipamientosNombres ?? [],
      3 => finalidades,
      _ => <String>[],
    };

    final theme = Theme.of(context);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: nombres.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _filtroSeleccionado == null;
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
              onSelected: (_) => setState(() => _filtroSeleccionado = null),
            );
          }

          final name = nombres[index - 1];
          final isSelected = _filtroSeleccionado == name;

          return ChoiceChip(
            label: Text(
              _capitalize(name),
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
            onSelected: (_) => setState(() => _filtroSeleccionado = name),
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
