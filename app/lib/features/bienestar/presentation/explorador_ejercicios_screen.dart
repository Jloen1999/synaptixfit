import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../shared/models/catalogo_models.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../application/ejercicios_provider.dart';

/// Pantalla principal del explorador de ejercicios.
/// Muestra una lista filtrable y buscable de todos los ejercicios disponibles.
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
    // Ejercicios filtrados: por parte del cuerpo o lista completa
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar ejercicios...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
              onSubmitted: (_) => setState(() {}),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Chips de filtro por parte del cuerpo
          catalogosAsync.when(
            loading: () => const SizedBox(height: 48),
            error: (_, __) => const SizedBox.shrink(),
            data: (catalogos) => _buildFilterChips(catalogos),
          ),

          const SizedBox(height: 4),

          // Lista de ejercicios
          Expanded(
            child: ejerciciosAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SkeletonLoader(),
                    SizedBox(height: 8),
                    SkeletonLoader(),
                    SizedBox(height: 8),
                    SkeletonLoader(),
                  ],
                ),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      'Error al cargar ejercicios',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$error',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              data: (items) {
                // Filtro local por búsqueda de texto
                final query = _searchController.text.toLowerCase().trim();
                final filtrados = query.isEmpty
                    ? items
                    : items.where((e) {
                        return e.nombre.toLowerCase().contains(query) ||
                            e.musculoPrincipal.toLowerCase().contains(query) ||
                            e.equipamientoPrincipal
                                .toLowerCase()
                                .contains(query);
                      }).toList();

                if (filtrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fitness_center,
                            size: 56,
                          color: SVColors.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'No se encontraron ejercicios',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 760;
                    if (!isWide) {
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filtrados.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = filtrados[index];
                          return _EjercicioCard(
                            nombre: item.nombre,
                            musculoPrincipal: item.musculoPrincipal,
                            equipamiento: item.equipamientoPrincipal,
                            urlGif: item.urlGif,
                            onTap: () => context
                                .go('/bienestar/ejercicio/${item.id}'),
                          );
                        },
                      );
                    }

                    final crossAxisCount =
                        constraints.maxWidth >= 1080 ? 3 : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: filtrados.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.4,
                      ),
                      itemBuilder: (context, index) {
                        final item = filtrados[index];
                        return _EjercicioCard(
                          nombre: item.nombre,
                          musculoPrincipal: item.musculoPrincipal,
                          equipamiento: item.equipamientoPrincipal,
                          urlGif: item.urlGif,
                          onTap: () =>
                              context.go('/bienestar/ejercicio/${item.id}'),
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

  /// Construye la fila horizontal de chips de filtro por parte del cuerpo.
  Widget _buildFilterChips(CatalogosEjercicios catalogos) {
    final partes = catalogos.partesCuerpoNombres;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: partes.length + 1, // +1 para el chip "Todos"
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _filtroParteCuerpo == null;
            return ChoiceChip(
              label: const Text('Todos'),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _filtroParteCuerpo = null);
              },
            );
          }

          final parte = partes[index - 1];
          final isSelected = _filtroParteCuerpo == parte;

          return ChoiceChip(
            label: Text(_capitalize(parte)),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                _filtroParteCuerpo = isSelected ? null : parte;
              });
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

// ---------------------------------------------------------------------------
// Widget privado: tarjeta de ejercicio con GIF preview
// ---------------------------------------------------------------------------
class _EjercicioCard extends StatelessWidget {
  const _EjercicioCard({
    required this.nombre,
    required this.musculoPrincipal,
    required this.equipamiento,
    this.urlGif,
    this.onTap,
  });

  final String nombre;
  final String musculoPrincipal;
  final String equipamiento;
  final String? urlGif;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Miniatura del GIF
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: urlGif == null
                    ? Container(
                        width: 64,
                        height: 64,
                        color: SVColors.surfaceVariant,
                        child: Icon(Icons.fitness_center,
                            color: SVColors.onSurfaceVariant),
                      )
                    : CachedNetworkImage(
                        imageUrl: urlGif!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 64,
                          height: 64,
                          color: SVColors.surfaceVariant,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: SVColors.surfaceVariant,
                          child: Icon(Icons.fitness_center,
                              color: SVColors.onSurfaceVariant),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Información del ejercicio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nombre,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.sports_gymnastics,
                            size: 14, color: SVColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            musculoPrincipal,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: SVColors.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.hardware,
                            size: 14, color: SVColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            equipamiento,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: SVColors.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: SVColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
