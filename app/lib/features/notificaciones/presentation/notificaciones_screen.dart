import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/notification_card.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  late List<NotificacionDb> _notificaciones;
  final Set<String> _archivadas = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _notificaciones = [];
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _cargando = false);
      return;
    }

    try {
      final data = await client
          .from('notificaciones')
          .select()
          .eq('usuario_id', user.id)
          .order('creado_en', ascending: false);

      if (mounted) {
        setState(() {
          _notificaciones = (data as List)
              .map((n) => NotificacionDb.fromMap(n as Map<String, dynamic>))
              .toList();
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _marcarTodoLeido() {
    setState(() {
      _notificaciones = _notificaciones.map((n) {
        if (!n.estaLeida) {
          return NotificacionDb(
            id: n.id,
            usuarioId: n.usuarioId,
            titulo: n.titulo,
            descripcion: n.descripcion,
            prioridad: n.prioridad,
            tipo: n.tipo,
            urlAccion: n.urlAccion,
            etiquetaAccion: n.etiquetaAccion,
            estaLeida: true,
            creadoEn: n.creadoEn,
            leidaEn: DateTime.now(),
          );
        }
        return n;
      }).toList();
    });
  }

  int _noLeidasPorPrioridad(String prioridad) {
    return _notificaciones
        .where((n) =>
            n.prioridad == prioridad &&
            !n.estaLeida &&
            !_archivadas.contains(n.id))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const FeatureScaffold(
        title: 'Centro de Notificaciones',
        backPath: '/dashboard',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 3,
      child: FeatureScaffold(
        title: 'Centro de Notificaciones',
        backPath: '/dashboard',
        actions: [
          IconButton(
            onPressed: _marcarTodoLeido,
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Marcar todo como leído',
          ),
        ],
        child: Column(
          children: [
            TabBar(
              tabs: [
                _TabWithBadge(
                    label: 'Crítica', count: _noLeidasPorPrioridad('critical')),
                _TabWithBadge(
                    label: 'Recomendada',
                    count: _noLeidasPorPrioridad('recommended')),
                _TabWithBadge(
                    label: 'Informativa',
                    count: _noLeidasPorPrioridad('informative')),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildList('critical'),
                  _buildList('recommended'),
                  _buildList('informative'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String prioridad) {
    final items = _notificaciones
        .where((item) =>
            item.prioridad == prioridad && !_archivadas.contains(item.id))
        .toList()
      ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));

    if (items.isEmpty) {
      return EmptyState(
        title: 'Todo despejado',
        message: _emptyMessage(prioridad),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.archive_rounded,
                color: Theme.of(context).colorScheme.error),
          ),
          onDismissed: (_) {
            setState(() {
              _archivadas.add(item.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Notificación archivada'),
                action: SnackBarAction(
                  label: 'Deshacer',
                  onPressed: () {
                    setState(() {
                      _archivadas.remove(item.id);
                    });
                  },
                ),
              ),
            );
          },
          child: NotificationCard(
            title: item.titulo,
            description: item.descripcion ?? 'Sin descripción',
            priority: item.prioridad,
            type: item.tipo,
            isRead: item.estaLeida,
            actionLabel: item.etiquetaAccion,
            onTap: () {
              // Marcar como leída al tocar
              setState(() {
                final idx = _notificaciones.indexWhere((n) => n.id == item.id);
                if (idx >= 0 && !_notificaciones[idx].estaLeida) {
                  _notificaciones[idx] = NotificacionDb(
                    id: item.id,
                    usuarioId: item.usuarioId,
                    titulo: item.titulo,
                    descripcion: item.descripcion,
                    prioridad: item.prioridad,
                    tipo: item.tipo,
                    urlAccion: item.urlAccion,
                    etiquetaAccion: item.etiquetaAccion,
                    estaLeida: true,
                    creadoEn: item.creadoEn,
                    leidaEn: DateTime.now(),
                  );
                }
              });
            },
            onAction: item.urlAccion != null ? () {} : null,
          ),
        );
      },
    );
  }

  String _emptyMessage(String prioridad) => switch (prioridad) {
        'critical' => 'No tienes alertas críticas. ¡Excelente!',
        'recommended' => 'No hay recomendaciones pendientes.',
        _ => 'No hay notificaciones informativas.',
      };
}

// ---------------------------------------------------------------------------
// Tab con badge de conteo
// ---------------------------------------------------------------------------
class _TabWithBadge extends StatelessWidget {
  const _TabWithBadge({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
