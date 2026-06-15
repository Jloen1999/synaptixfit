import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../dashboard/application/timeline_provider.dart';
import '../application/social_provider.dart';
import 'widgets/feed_item_card.dart';

/// Pantalla principal del Muro Social (refactorizada con Riverpod).
///
/// Carga el feed desde [socialFeedProvider] y permite dar like, comentar
/// y crear nuevas publicaciones vía FAB.
class MuroSocialScreen extends ConsumerStatefulWidget {
  const MuroSocialScreen({super.key});

  @override
  ConsumerState<MuroSocialScreen> createState() => _MuroSocialScreenState();
}

class _MuroSocialScreenState extends ConsumerState<MuroSocialScreen> {
  String _filtroTemporal = 'todo';

  List<dynamic> _aplicarFiltro(List<dynamic> publicaciones) {
    final ahora = DateTime.now();
    var lista = [...publicaciones];

    switch (_filtroTemporal) {
      case 'hoy':
        lista = lista.where((a) {
          final fecha = a.fecha ?? a.creadoEn;
          if (fecha == null) return false;
          return fecha.year == ahora.year &&
              fecha.month == ahora.month &&
              fecha.day == ahora.day;
        }).toList();
        break;
      case 'semana':
        final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
        lista = lista.where((a) {
          final fecha = a.fecha ?? a.creadoEn;
          if (fecha == null) return false;
          return fecha.isAfter(DateTime(
              inicioSemana.year, inicioSemana.month, inicioSemana.day));
        }).toList();
        break;
      case 'mes':
        lista = lista.where((a) {
          final fecha = a.fecha ?? a.creadoEn;
          if (fecha == null) return false;
          return fecha.year == ahora.year && fecha.month == ahora.month;
        }).toList();
        break;
    }

    lista.sort((a, b) {
      final fa = a.fecha ?? a.creadoEn ?? DateTime(2000);
      final fb = b.fecha ?? b.creadoEn ?? DateTime(2000);
      return fb.compareTo(fa);
    });
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(socialFeedProvider);

    return FeatureScaffold(
      title: 'Muro Social',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarCrearPublicacion(context),
        child: const Icon(Icons.share_outlined),
      ),
      child: Column(
        children: [
          // Filtros temporales
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: _FiltrosRow(
              filtroActual: _filtroTemporal,
              onCambiar: (filtro) => setState(() => _filtroTemporal = filtro),
            ),
          ),
          // Contenido del feed
          Expanded(
            child: feedAsync.when(
              data: (publicaciones) {
                final filtradas = _aplicarFiltro(publicaciones);

                if (filtradas.isEmpty) {
                  return const EmptyState(
                    title: 'Sin actividad',
                    message: 'Sé el primero en compartir un logro 🏆',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(socialFeedProvider);
                    // También refrescar timeline y dashboard
                    ref.invalidate(timelineHoyProvider);
                    ref.invalidate(dashboardProvider);
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final useGrid = constraints.maxWidth >= 980;
                      if (useGrid) {
                        return GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: filtradas.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.5,
                          ),
                          itemBuilder: (context, index) =>
                              FeedItemCard(publicacion: filtradas[index]),
                        );
                      }

                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: filtradas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            FeedItemCard(publicacion: filtradas[index]),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: EmptyState(
                  title: 'Error al cargar',
                  message: 'No se pudo cargar el feed: $error',
                  icon: Icons.error_outline,
                  action: FilledButton.tonal(
                    onPressed: () => ref.invalidate(socialFeedProvider),
                    child: const Text('Reintentar'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Crear publicación (FAB → BottomSheet)
  // ---------------------------------------------------------------------------

  void _mostrarCrearPublicacion(BuildContext context) {
    final tipoController = ValueNotifier<String>('milestone_reached');
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Crear publicación',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              // Tipo de publicación
              ValueListenableBuilder<String>(
                valueListenable: tipoController,
                builder: (context, tipo, _) {
                  return SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'milestone_reached',
                        label: Text('Logro'),
                        icon: Icon(Icons.star_outline, size: 18),
                      ),
                      ButtonSegment(
                        value: 'rutina',
                        label: Text('Rutina'),
                        icon: Icon(Icons.fitness_center_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: 'reto',
                        label: Text('Reto'),
                        icon: Icon(Icons.flag_outlined, size: 18),
                      ),
                    ],
                    selected: {tipo},
                    onSelectionChanged: (sel) {
                      tipoController.value = sel.first;
                    },
                    showSelectedIcon: false,
                  );
                },
              ),
              const SizedBox(height: 16),
              // Descripción
              TextField(
                controller: descController,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: '¿Qué quieres compartir?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Botón publicar
              FilledButton.icon(
                onPressed: () async {
                  final desc = descController.text.trim();
                  if (desc.isEmpty) return;

                  await publicarEnFeed(
                    ref,
                    descripcion: desc,
                    tipo: tipoController.value,
                  );

                  if (ctx.mounted) Navigator.pop(ctx);
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Publicar'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Fila de chips de filtro temporal.
class _FiltrosRow extends StatelessWidget {
  const _FiltrosRow({
    required this.filtroActual,
    required this.onCambiar,
  });

  final String filtroActual;
  final ValueChanged<String> onCambiar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FiltroChip(
          label: 'Todo',
          seleccionado: filtroActual == 'todo',
          onTap: () => onCambiar('todo'),
        ),
        const SizedBox(width: 8),
        _FiltroChip(
          label: 'Hoy',
          seleccionado: filtroActual == 'hoy',
          onTap: () => onCambiar('hoy'),
        ),
        const SizedBox(width: 8),
        _FiltroChip(
          label: 'Semana',
          seleccionado: filtroActual == 'semana',
          onTap: () => onCambiar('semana'),
        ),
        const SizedBox(width: 8),
        _FiltroChip(
          label: 'Mes',
          seleccionado: filtroActual == 'mes',
          onTap: () => onCambiar('mes'),
        ),
      ],
    );
  }
}

class _FiltroChip extends StatelessWidget {
  const _FiltroChip({
    required this.label,
    required this.seleccionado,
    required this.onTap,
  });

  final String label;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: seleccionado
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: seleccionado
              ? null
              : Border.all(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: seleccionado
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
