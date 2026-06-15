import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../application/insignias_provider.dart';
import '../domain/insignia_dto.dart';
import 'widgets/insignia_card.dart';
import 'widgets/racha_indicator.dart';

/// Pantalla de colección de insignias con filtro por categoría.
class InsigniasScreen extends ConsumerStatefulWidget {
  const InsigniasScreen({super.key});

  @override
  ConsumerState<InsigniasScreen> createState() => _InsigniasScreenState();
}

class _InsigniasScreenState extends ConsumerState<InsigniasScreen> {
  String _categoriaSeleccionada = 'todas';

  static const _categorias = [
    'todas',
    'entrenamiento',
    'estudio',
    'social',
    'racha',
    'especial',
  ];

  String _categoriaEtiqueta(String cat) {
    switch (cat) {
      case 'todas':
        return 'Todas';
      case 'entrenamiento':
        return 'Entrenamiento';
      case 'estudio':
        return 'Estudio';
      case 'social':
        return 'Social';
      case 'racha':
        return 'Racha';
      case 'especial':
        return 'Especial';
      default:
        return cat;
    }
  }

  IconData _categoriaIcono(String cat) {
    switch (cat) {
      case 'todas':
        return Icons.grid_view_rounded;
      case 'entrenamiento':
        return Icons.fitness_center_rounded;
      case 'estudio':
        return Icons.school_rounded;
      case 'social':
        return Icons.people_rounded;
      case 'racha':
        return Icons.local_fire_department_rounded;
      case 'especial':
        return Icons.star_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogoAsync = ref.watch(catalogoInsigniasProvider);
    final countAsync = ref.watch(insigniasCountProvider);

    final totalObtenidas = countAsync.valueOrNull ?? 0;

    return FeatureScaffold(
      title: 'Mis Insignias',
      actions: [
        // Badge con contador
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            '$totalObtenidas/15',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFBBF24),
            ),
          ),
        ),
      ],
      child: catalogoAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonLoader(height: 400),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Color(0xFF64748B)),
              const SizedBox(height: 12),
              Text(
                'Error al cargar insignias',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(catalogoInsigniasProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (catalogo) => _buildContent(context, catalogo),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Insignia> catalogo) {
    final filtradas = _categoriaSeleccionada == 'todas'
        ? catalogo
        : catalogo.where((i) => i.categoria == _categoriaSeleccionada).toList();

    return CustomScrollView(
      slivers: [
        // Racha indicator
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: RachaIndicator(),
          ),
        ),

        // Filtro de categorías con chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categorias.map((cat) {
                  final seleccionada = cat == _categoriaSeleccionada;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: seleccionada,
                      onSelected: (_) {
                        setState(() => _categoriaSeleccionada = cat);
                      },
                      label: Text(
                        _categoriaEtiqueta(cat),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: seleccionada
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      avatar: Icon(
                        _categoriaIcono(cat),
                        size: 16,
                        color: seleccionada
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF64748B),
                      ),
                      backgroundColor: const Color(0xFF1E293B),
                      selectedColor:
                          const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      checkmarkColor: const Color(0xFFF1F5F9),
                      side: BorderSide(
                        color: seleccionada
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                            : const Color(0xFF334155),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // Grid de insignias
        filtradas.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          size: 48, color: Color(0xFF334155)),
                      const SizedBox(height: 12),
                      const Text(
                        'Sin insignias',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _categoriaSeleccionada == 'todas'
                            ? 'Completa actividades para desbloquear insignias'
                            : 'No tienes insignias en esta categoría aún',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.92,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => InsigniaCard(
                      insignia: filtradas[index],
                      onTap: filtradas[index].obtenida
                          ? () => _mostrarDetalle(context, filtradas[index])
                          : null,
                    ),
                    childCount: filtradas.length,
                  ),
                ),
              ),
      ],
    );
  }

  void _mostrarDetalle(BuildContext context, Insignia insignia) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final color = Color(insignia.colorRareza);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de arrastre
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Icono grande
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.3),
                      color.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: Text(insignia.icono,
                      style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                insignia.nombre,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF1F5F9),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                insignia.descripcion,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              // Etiquetas
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _etiqueta(
                    _categoriaEtiqueta(insignia.categoria),
                    Icons.category_rounded,
                  ),
                  const SizedBox(width: 8),
                  _etiqueta(
                    insignia.rareza[0].toUpperCase() +
                        insignia.rareza.substring(1),
                    Icons.diamond_rounded,
                    color: color,
                  ),
                ],
              ),
              if (insignia.obtenidaEn != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Obtenida el ${insignia.obtenidaEn!.day}/${insignia.obtenidaEn!.month}/${insignia.obtenidaEn!.year}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _etiqueta(String texto, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? const Color(0xFF64748B)).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (color ?? const Color(0xFF64748B)).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? const Color(0xFF94A3B8)),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color ?? const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
