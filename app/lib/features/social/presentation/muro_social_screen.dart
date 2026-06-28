import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../dashboard/application/timeline_provider.dart';
import '../../insignias/application/insignias_provider.dart';
import '../../retos/application/retos_core.dart';
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
  RealtimeChannel? _channel;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _suscribirRealtime();
  }

  /// Suscribe el muro a los cambios en tiempo real de las tablas sociales para
  /// que el feed se actualice de inmediato (nuevos logros, likes, comentarios)
  /// sin necesidad de recarga manual.
  void _suscribirRealtime() {
    final client = Supabase.instance.client;
    _channel = client
        .channel('public:social_feed')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'actividades_sociales',
          callback: (_) => _refrescarFeed(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'interacciones_sociales',
          callback: (_) => _refrescarFeed(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comentarios_feed',
          callback: (_) => _refrescarFeed(),
        )
        .subscribe();
  }

  /// Refresca el feed con un pequeño debounce para coalescer ráfagas de
  /// eventos en tiempo real (varios likes/comentarios casi simultáneos) y
  /// evitar invalidaciones/refetch innecesarios.
  void _refrescarFeed() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      ref.invalidate(socialFeedProvider);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    final ch = _channel;
    if (ch != null) {
      Supabase.instance.client.removeChannel(ch);
    }
    super.dispose();
  }

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _CrearPublicacionSheet(),
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

// =============================================================================
// Crear publicación (BottomSheet CLEAN UI con selector de entidad)
// =============================================================================

/// Entidad seleccionable para vincular a una publicación.
///
/// Unifica insignias (con [emoji]), rutinas y retos (con [icon]).
class _Entidad {
  const _Entidad({
    required this.id,
    required this.nombre,
    this.emoji,
    this.icon,
    this.subtitulo,
  });

  final String id;
  final String nombre;
  final String? emoji;
  final IconData? icon;
  final String? subtitulo;
}

/// Hoja inferior para crear una publicación con enfoque visual CLEAN UI.
///
/// Según el tipo (Logro / Rutina / Reto) muestra el selector de entidad
/// correspondiente: insignia desbloqueada, rutina o reto del usuario.
class _CrearPublicacionSheet extends ConsumerStatefulWidget {
  const _CrearPublicacionSheet();

  @override
  ConsumerState<_CrearPublicacionSheet> createState() =>
      _CrearPublicacionSheetState();
}

class _CrearPublicacionSheetState
    extends ConsumerState<_CrearPublicacionSheet> {
  String _tipo = 'milestone_reached';
  final TextEditingController _descCtrl = TextEditingController();
  _Entidad? _seleccion;
  bool _publicando = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  void _seleccionarTipo(String tipo) {
    if (tipo == _tipo) return;
    setState(() {
      _tipo = tipo;
      _seleccion = null;
    });
  }

  String get _tituloSelector => switch (_tipo) {
        'rutina' => 'Selecciona una rutina',
        'reto' => 'Selecciona un reto',
        _ => 'Selecciona un logro',
      };

  String _entidadTipoMeta() => switch (_tipo) {
        'rutina' => 'rutina',
        'reto' => 'reto',
        _ => 'insignia',
      };

  Future<void> _publicar() async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty || _publicando) return;
    setState(() => _publicando = true);

    String? metadata;
    final sel = _seleccion;
    if (sel != null) {
      metadata = jsonEncode({
        'entidad_tipo': _entidadTipoMeta(),
        'entidad_id': sel.id,
        'entidad_nombre': sel.nombre,
        if (sel.emoji != null) 'entidad_icono': sel.emoji,
      });
    }

    await publicarEnFeed(
      ref,
      descripcion: desc,
      tipo: _tipo,
      metadata: metadata,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final puedePublicar = _descCtrl.text.trim().isNotEmpty && !_publicando;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Asa de arrastre
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Encabezado
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Crear publicación',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  visualDensity: VisualDensity.compact,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Selector de tipo
            _buildTipoSelector(theme),
            const SizedBox(height: 22),
            // Selector de entidad
            _seccionLabel(_tituloSelector, theme),
            _buildSelectorEntidad(theme),
            const SizedBox(height: 22),
            // Descripción
            _seccionLabel('¿Qué quieres compartir?', theme),
            TextField(
              controller: _descCtrl,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Escribe algo para tu comunidad…',
                filled: true,
                fillColor: cs.surfaceContainerLow,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Botón publicar
            FilledButton.icon(
              onPressed: puedePublicar ? _publicar : null,
              icon: _publicando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_publicando ? 'Publicando…' : 'Publicar'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccionLabel(String text, ThemeData theme) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      );

  Widget _buildTipoSelector(ThemeData theme) {
    const tipos = [
      ('milestone_reached', 'Logro', Icons.workspace_premium_rounded),
      ('rutina', 'Rutina', Icons.fitness_center_rounded),
      ('reto', 'Reto', Icons.flag_rounded),
    ];
    return Row(
      children: [
        for (var i = 0; i < tipos.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _TipoPublicacionPill(
              label: tipos[i].$2,
              icon: tipos[i].$3,
              seleccionado: _tipo == tipos[i].$1,
              onTap: () => _seleccionarTipo(tipos[i].$1),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectorEntidad(ThemeData theme) {
    switch (_tipo) {
      case 'rutina':
        return _listaEntidades(
          ref.watch(rutinasUsuarioProvider).whenData(
                (lista) => lista
                    .map((r) => _Entidad(
                          id: r.id,
                          nombre: r.nombre,
                          icon: Icons.fitness_center_rounded,
                          subtitulo:
                              '${r.cantidadEjercicios} ejercicios · ${r.duracionSemanas} sem',
                        ))
                    .toList(),
              ),
          'Aún no tienes rutinas para compartir.',
          theme,
        );
      case 'reto':
        return _listaEntidades(
          ref.watch(todosRetosProvider).whenData(
                (lista) => lista
                    .map((r) => _Entidad(
                          id: r.reto.id,
                          nombre: r.reto.titulo,
                          icon: Icons.flag_rounded,
                          subtitulo: r.reto.estaCompletado
                              ? 'Completado'
                              : 'En progreso',
                        ))
                    .toList(),
              ),
          'Aún no tienes retos para compartir.',
          theme,
        );
      default:
        return _listaEntidades(
          ref.watch(insigniasUsuarioProvider).whenData(
                (lista) => lista
                    .map((i) => _Entidad(
                          id: i.id,
                          nombre: i.nombre,
                          emoji: i.icono,
                          subtitulo: i.descripcion,
                        ))
                    .toList(),
              ),
          'Aún no has desbloqueado insignias.',
          theme,
        );
    }
  }

  Widget _listaEntidades(
    AsyncValue<List<_Entidad>> async,
    String mensajeVacio,
    ThemeData theme,
  ) {
    return async.when(
      data: (items) {
        if (items.isEmpty) return _hintVacio(mensajeVacio, theme);
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final e = items[i];
              final seleccionada = _seleccion?.id == e.id;
              return _EntidadTile(
                entidad: e,
                seleccionada: seleccionada,
                onTap: () =>
                    setState(() => _seleccion = seleccionada ? null : e),
              );
            },
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => _hintVacio('No se pudo cargar la lista.', theme),
    );
  }

  Widget _hintVacio(String mensaje, ThemeData theme) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          mensaje,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
}

/// Pastilla plana del selector de tipo de publicación (CLEAN UI).
class _TipoPublicacionPill extends StatelessWidget {
  const _TipoPublicacionPill({
    required this.label,
    required this.icon,
    required this.seleccionado,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: seleccionado ? cs.primary : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: seleccionado
              ? null
              : Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 20,
                color: seleccionado ? cs.onPrimary : cs.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
                color: seleccionado ? cs.onPrimary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile seleccionable de entidad (insignia / rutina / reto) en CLEAN UI.
class _EntidadTile extends StatelessWidget {
  const _EntidadTile({
    required this.entidad,
    required this.seleccionada,
    required this.onTap,
  });

  final _Entidad entidad;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: seleccionada
              ? cs.primary.withValues(alpha: 0.10)
              : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionada
                ? cs.primary.withValues(alpha: 0.6)
                : cs.outlineVariant.withValues(alpha: 0.4),
            width: seleccionada ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: entidad.emoji != null
                  ? Text(entidad.emoji!, style: const TextStyle(fontSize: 20))
                  : Icon(entidad.icon ?? Icons.star_rounded,
                      size: 20, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entidad.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (entidad.subtitulo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      entidad.subtitulo!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              seleccionada
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 22,
              color: seleccionada
                  ? cs.primary
                  : cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
