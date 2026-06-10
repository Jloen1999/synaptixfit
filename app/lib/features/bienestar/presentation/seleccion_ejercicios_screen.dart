import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../shared/models/catalogo_models.dart';
import '../../../shared/models/db_models.dart';
import '../../../shared/utils/string_utils.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/exercise_grid_card.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../application/ejercicios_provider.dart';
import 'detalle_ejercicio_screen.dart';

class SeleccionEjerciciosScreen extends ConsumerStatefulWidget {
  const SeleccionEjerciciosScreen({this.seleccionadosPrevios, super.key});

  final List<String>? seleccionadosPrevios;

  @override
  ConsumerState<SeleccionEjerciciosScreen> createState() =>
      _SeleccionEjerciciosScreenState();
}

class _SeleccionEjerciciosScreenState
    extends ConsumerState<SeleccionEjerciciosScreen> {
  final _searchController = TextEditingController();
  int _tabSeleccionado = 0;
  String? _filtroSeleccionado;
  String _busqueda = '';

  final List<EjercicioDb> _selected = [];

  @override
  void initState() {
    super.initState();
    final previos = widget.seleccionadosPrevios;
    if (previos != null && previos.isNotEmpty) {
      final todos = ref.read(ejerciciosProvider).valueOrNull ?? [];
      for (final id in previos) {
        final match = todos.where((e) => e.id == id).firstOrNull;
        if (match != null) _selected.add(match);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  FiltroEjercicios _buildFiltro() {
    if (_filtroSeleccionado == null) return const FiltroEjercicios();
    switch (_tabSeleccionado) {
      case 0:
        return FiltroEjercicios(
          tipo: FiltroTipo.parteCuerpo,
          valor: _filtroSeleccionado!,
        );
      case 1:
        return FiltroEjercicios(
          tipo: FiltroTipo.musculo,
          valor: _filtroSeleccionado!,
        );
      case 2:
        return FiltroEjercicios(
          tipo: FiltroTipo.equipamiento,
          valor: _filtroSeleccionado!,
        );
      case 3:
        return FiltroEjercicios(
          tipo: FiltroTipo.finalidad,
          valor: _filtroSeleccionado!,
        );
      default:
        return const FiltroEjercicios();
    }
  }

  List<EjercicioDb> _aplicarBusqueda(List<EjercicioDb> items) {
    final q = normalizeSearch(_busqueda);
    if (q.isEmpty) return items;
    return items
        .where(
          (e) =>
              normalizeSearch(e.nombre).contains(q) ||
              (e.descripcion != null &&
                  normalizeSearch(e.descripcion!).contains(q)),
        )
        .toList();
  }

  bool _isSelected(EjercicioDb ej) => _selected.any((s) => s.id == ej.id);

  void _toggle(EjercicioDb ej) {
    setState(() {
      if (_isSelected(ej)) {
        _selected.removeWhere((s) => s.id == ej.id);
      } else {
        _selected.add(ej);
      }
    });
  }

  void _verDetalle(EjercicioDb ejercicio) async {
    final result = await Navigator.of(context).push<EjercicioDb>(
      MaterialPageRoute(
        builder: (_) => DetalleEjercicioScreen(
          id: ejercicio.id,
          showAddButton: true,
        ),
      ),
    );
    if (result != null && mounted) {
      _toggle(result);
    }
  }

  void _confirmar() {
    if (_selected.isNotEmpty) {
      Navigator.of(context).pop(List<EjercicioDb>.from(_selected));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogosAsync = ref.watch(catalogosProvider);
    final filtro = _buildFiltro();
    final baseList = ref.watch(ejerciciosFiltradosProvider(filtro));
    final displayList = _aplicarBusqueda(baseList);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _selected.isEmpty
              ? 'Añadir Ejercicios'
              : '${_selected.length} seleccionados',
        ),
        centerTitle: false,
        actions: [
          if (_selected.isNotEmpty)
            TextButton.icon(
              onPressed: _confirmar,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Listo'),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_selected.isNotEmpty) _buildSelectedBar(context),
          // ── Barra de búsqueda ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                        icon: const Icon(Icons.close_rounded, size: 20),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (v) => setState(
                () => _busqueda = normalizeSearch(v),
              ),
            ),
          ),

          // ── Tabs ──
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
            child: _buildContent(displayList, catalogosAsync.valueOrNull),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedBar(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: SVColors.primary.withValues(alpha: 0.04),
        border: Border(
          bottom: BorderSide(
            color: SVColors.primary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _selected.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final ej = _selected[index];
          return SizedBox(
            width: 68,
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 45,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF1A1A1E),
                        border: Border.all(
                          color: SVColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ej.urlPreview != null && ej.urlPreview!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: ej.urlPreview!,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const Icon(
                                Icons.fitness_center_rounded,
                                size: 16,
                                color: Colors.grey,
                              ),
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.fitness_center_rounded,
                                size: 16,
                                color: Colors.grey,
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.fitness_center_rounded,
                                  size: 16, color: Colors.grey),
                            ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () => _toggle(ej),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ej.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
      List<EjercicioDb> items, CatalogosEjercicios? catalogos) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet = constraints.maxWidth >= 720;
        final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ejerciciosProvider);
            ref.invalidate(catalogosProvider);
          },
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.68,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final ej = items[index];
              final muscleImageUrl =
                  catalogos?.urlImagenMusculo(ej.musculoPrincipal);

              return ExerciseGridCard(
                nombre: ej.nombre,
                muscleGroup: ej.musculoPrincipal,
                equipment: ej.equipamientoPrincipal,
                previewUrl: ej.urlPreview,
                muscleImageUrl: muscleImageUrl,
                isSelected: _isSelected(ej),
                onTap: () => _verDetalle(ej),
                onAdd: () => _toggle(ej),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    if (_busqueda.isNotEmpty) {
      return Center(
        child: EmptyState(
          title: 'Sin resultados',
          message: 'No se encontraron ejercicios para "$_busqueda".',
          icon: Icons.search_off_rounded,
        ),
      );
    }

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
        SkeletonLoader(height: 230),
        SizedBox(height: 10),
        SkeletonLoader(height: 230),
        SizedBox(height: 10),
        SkeletonLoader(height: 230),
      ],
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

    if (nombres.isEmpty) return const SizedBox(height: 44);

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
                      ? Theme.of(context).colorScheme.onSecondaryContainer
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

          if (_tabSeleccionado == 1) {
            final muscleUrl = catalogos?.urlImagenMusculo(name);
            return _MuscleFilterChip(
              name: _capitalize(name),
              imageUrl: muscleUrl,
              isSelected: isSelected,
              onSelected: () {
                setState(
                  () => _filtroSeleccionado = isSelected ? null : name,
                );
              },
            );
          }

          return ChoiceChip(
            label: Text(
              _capitalize(name),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isSelected
                    ? Theme.of(context).colorScheme.onSecondaryContainer
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
              setState(
                () => _filtroSeleccionado = isSelected ? null : name,
              );
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

class _MuscleFilterChip extends StatelessWidget {
  const _MuscleFilterChip({
    required this.name,
    this.imageUrl,
    required this.isSelected,
    required this.onSelected,
  });

  final String name;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: imageUrl != null
          ? CircleAvatar(
              radius: 12,
              backgroundImage: CachedNetworkImageProvider(imageUrl!),
              backgroundColor: SVColors.surfaceContainerLow,
            )
          : null,
      label: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: isSelected
              ? Theme.of(context).colorScheme.onSecondaryContainer
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
      onSelected: (_) => onSelected(),
    );
  }
}
