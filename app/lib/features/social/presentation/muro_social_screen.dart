import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feed_card.dart';
import '../../../shared/widgets/feature_scaffold.dart';

class MuroSocialScreen extends StatefulWidget {
  const MuroSocialScreen({super.key});

  @override
  State<MuroSocialScreen> createState() => _MuroSocialScreenState();
}

class _MuroSocialScreenState extends State<MuroSocialScreen> {
  String _filtroTemporal = 'todo';
  final Set<String> _likedActividades = {};
  List<ActividadSocialDb> _actividades = [];
  final Map<String, String> _nombresUsuarios = {};
  final Map<String, int> _likesCache = {};
  final Map<String, int> _comentariosCache = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final client = Supabase.instance.client;

    try {
      final data = await client
          .from('actividades_sociales')
          .select()
          .order('creado_en', ascending: false);

      final actividades = (data as List)
          .map((a) => ActividadSocialDb.fromMap(a as Map<String, dynamic>))
          .toList();

      // Cargar nombres de usuarios
      final userIds = actividades.map((a) => a.usuarioId).toSet();
      for (final uid in userIds) {
        final userMap = await client
            .from('usuarios')
            .select('nombre_completo')
            .eq('id', uid)
            .maybeSingle();
        _nombresUsuarios[uid] =
            userMap?['nombre_completo'] as String? ?? 'Usuario';
      }

      // Cargar conteos de interacciones
      for (final actividad in actividades) {
        final interacciones = await client
            .from('interacciones_sociales')
            .select('tipo_interaccion')
            .eq('actividad_id', actividad.id);

        final lista = interacciones as List;
        _likesCache[actividad.id] =
            lista.where((i) => i['tipo_interaccion'] == 'like').length;
        _comentariosCache[actividad.id] =
            lista.where((i) => i['tipo_interaccion'] == 'comment').length;
      }

      if (mounted) {
        setState(() {
          _actividades = actividades;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<ActividadSocialDb> get _publicacionesFiltradas {
    final ahora = DateTime.now();
    var lista = [..._actividades];

    switch (_filtroTemporal) {
      case 'hoy':
        lista = lista
            .where((a) =>
                a.creadoEn.year == ahora.year &&
                a.creadoEn.month == ahora.month &&
                a.creadoEn.day == ahora.day)
            .toList();
        break;
      case 'semana':
        final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
        lista = lista
            .where((a) => a.creadoEn.isAfter(DateTime(
                inicioSemana.year, inicioSemana.month, inicioSemana.day)))
            .toList();
        break;
      case 'mes':
        lista = lista
            .where((a) =>
                a.creadoEn.year == ahora.year &&
                a.creadoEn.month == ahora.month)
            .toList();
        break;
    }

    lista.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
    return lista;
  }

  String _tiempoRelativo(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${fecha.day}/${fecha.month}';
  }

  Future<void> _onRefresh() async {
    await _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const FeatureScaffold(
        title: 'Muro Social',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final publicaciones = _publicacionesFiltradas;

    return FeatureScaffold(
      title: 'Muro Social',
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.share_outlined),
      ),
      child: Column(
        children: [
          // Filtros temporales
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                _FiltroChip(
                  label: 'Todo',
                  seleccionado: _filtroTemporal == 'todo',
                  onTap: () => setState(() => _filtroTemporal = 'todo'),
                ),
                const SizedBox(width: 8),
                _FiltroChip(
                  label: 'Hoy',
                  seleccionado: _filtroTemporal == 'hoy',
                  onTap: () => setState(() => _filtroTemporal = 'hoy'),
                ),
                const SizedBox(width: 8),
                _FiltroChip(
                  label: 'Semana',
                  seleccionado: _filtroTemporal == 'semana',
                  onTap: () => setState(() => _filtroTemporal = 'semana'),
                ),
                const SizedBox(width: 8),
                _FiltroChip(
                  label: 'Mes',
                  seleccionado: _filtroTemporal == 'mes',
                  onTap: () => setState(() => _filtroTemporal = 'mes'),
                ),
              ],
            ),
          ),
          // Lista con pull-to-refresh
          Expanded(
            child: publicaciones.isEmpty
                ? const EmptyState(
                    title: 'Sin actividad',
                    message: 'Sé el primero en compartir un logro 🏆',
                  )
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final useGrid = constraints.maxWidth >= 980;
                        if (useGrid) {
                          return GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: publicaciones.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.5,
                            ),
                            itemBuilder: (context, index) =>
                                _buildFeedItem(publicaciones[index]),
                          );
                        }

                        return ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: publicaciones.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) =>
                              _buildFeedItem(publicaciones[index]),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedItem(ActividadSocialDb actividad) {
    final isLiked = _likedActividades.contains(actividad.id);
    final baseLikes = _likesCache[actividad.id] ?? 0;
    final totalLikes = isLiked ? baseLikes + 1 : baseLikes;

    return FeedCard(
      userName: _nombresUsuarios[actividad.usuarioId] ?? 'Usuario',
      achievement: actividad.descripcion,
      likes: totalLikes,
      comments: _comentariosCache[actividad.id] ?? 0,
      activityType: actividad.tipo,
      timeAgo: _tiempoRelativo(actividad.creadoEn),
      isLiked: isLiked,
      onLike: () {
        setState(() {
          if (isLiked) {
            _likedActividades.remove(actividad.id);
          } else {
            _likedActividades.add(actividad.id);
          }
        });
      },
      onComment: () {},
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
