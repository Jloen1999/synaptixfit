import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/challenge_progress_bar.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/retos_provider.dart';

class RetosScreen extends ConsumerStatefulWidget {
  const RetosScreen({super.key});

  @override
  ConsumerState<RetosScreen> createState() => _RetosScreenState();
}

class _RetosScreenState extends ConsumerState<RetosScreen> {
  int _tabIndex = 0;
  String _busqueda = '';
  String? _filtroTipo;
  String? _filtroComplejidad; // null = todos, 'simple', 'complejo'

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Retos',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Activos')),
                ButtonSegment(value: 1, label: Text('Explorar')),
                ButtonSegment(value: 2, label: Text('Completados')),
              ],
              selected: {_tabIndex},
              onSelectionChanged: (v) =>
                  setState(() => _tabIndex = v.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por título...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _busqueda = ''),
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => setState(() => _busqueda = v.trim().toLowerCase()),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _FiltroChip(
                  label: 'Todos',
                  selected: _filtroTipo == null,
                  onSelected: (_) => setState(() => _filtroTipo = null),
                ),
                const SizedBox(width: 6),
                _FiltroChip(
                  label: 'Fitness',
                  selected: _filtroTipo == 'fitness',
                  onSelected: (_) => setState(
                      () => _filtroTipo = _filtroTipo == 'fitness' ? null : 'fitness'),
                ),
                const SizedBox(width: 6),
                _FiltroChip(
                  label: 'Académico',
                  selected: _filtroTipo == 'academico',
                  onSelected: (_) => setState(() =>
                      _filtroTipo = _filtroTipo == 'academico' ? null : 'academico'),
                ),
                const SizedBox(width: 12),
                _FiltroChip(
                  label: 'Simple',
                  selected: _filtroComplejidad == 'simple',
                  onSelected: (_) => setState(() =>
                      _filtroComplejidad = _filtroComplejidad == 'simple' ? null : 'simple'),
                ),
                const SizedBox(width: 6),
                _FiltroChip(
                  label: 'Complejo',
                  selected: _filtroComplejidad == 'complejo',
                  onSelected: (_) => setState(() =>
                      _filtroComplejidad = _filtroComplejidad == 'complejo' ? null : 'complejo'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildContenido(),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    switch (_tabIndex) {
      case 0:
        return _buildLista(
          async: ref.watch(retosProvider),
          onRefresh: () async {
            ref.invalidate(retosProvider);
            return ref.read(retosProvider.future);
          },
          esExplorar: false,
          showCreate: true,
        );
      case 1:
        return _buildLista(
          async: ref.watch(retosPublicosProvider),
          onRefresh: () async {
            ref.invalidate(retosPublicosProvider);
            return ref.read(retosPublicosProvider.future);
          },
          esExplorar: true,
          showCreate: false,
        );
      case 2:
        return _buildCompletados();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLista({
    required AsyncValue<List<RetoResumen>> async,
    required Future<void> Function() onRefresh,
    bool esExplorar = false,
    bool showCreate = false,
  }) {
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (retos) {
        var filtrados = _aplicarFiltros(retos);

        if (showCreate || filtrados.isNotEmpty) {
          final total = retos.length;
          final progresoMedio = total > 0
              ? (retos.fold<double>(0, (s, r) => s + r.progreso) / total)
              : 0.0;
          final completados =
              retos.where((r) => r.progreso >= 1.0).length;
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
              children: [
                if (showCreate) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Reto simple'),
                          onPressed: () => context.go('/retos/simple'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Reto complejo'),
                          onPressed: () => context.go('/retos/complejo'),
                        ),
                      ),
                    ],
                  ),
                ],
                if (total > 0) ...[
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MiniStat(
                              icon: Icons.flag_outlined,
                              value: '$total',
                              label: 'Activos'),
                          _MiniStat(
                              icon: Icons.check_circle_outline,
                              value: '$completados',
                              label: 'Listos'),
                          _MiniStat(
                              icon: Icons.trending_up,
                              value:
                                  '${(progresoMedio * 100).round()}%',
                              label: 'Progreso'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (filtrados.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: EmptyState(
                      icon: Icons.search_off,
                      title: 'Sin resultados',
                      message:
                          'No hay retos que coincidan con los filtros.',
                    ),
                  ),
                ...filtrados.map((item) => _RetoCard(
                      item: item,
                      esExplorar: esExplorar,
                      onComplete: !esExplorar
                          ? () => _confirmarCompletarDesdeLista(context, item.reto.id)
                          : null,
                      onClone: esExplorar
                          ? () async {
                              final nuevoId =
                                  await clonarReto(item.reto.id);
                              if (nuevoId != null && context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Reto clonado correctamente')),
                                );
                                ref.invalidate(retosProvider);
                                ref.invalidate(retosPublicosProvider);
                              }
                            }
                          : null,
                      onTap: () =>
                          context.push('/retos/${item.reto.id}'),
                    )),
              ],
            ),
          );
        }

        return const EmptyState(
          icon: Icons.flag_outlined,
          title: 'Sin retos activos',
          message: 'Crea un reto para empezar.',
        );
      },
    );
  }

  Widget _buildCompletados() {
    return FutureBuilder<List<_RetoCompletadoInfo>>(
      future: _cargarCompletados(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var completadosInfo = snap.data ?? [];

        // Aplicar filtros
        if (_busqueda.isNotEmpty) {
          completadosInfo = completadosInfo
              .where((c) =>
                  c.reto.titulo.toLowerCase().contains(_busqueda) ||
                  c.reto.meta.toLowerCase().contains(_busqueda))
              .toList();
        }
        if (_filtroTipo != null) {
          completadosInfo = completadosInfo
              .where((c) => c.reto.tipo == _filtroTipo)
              .toList();
        }
        if (_filtroComplejidad == 'simple') {
          completadosInfo = completadosInfo
              .where((c) => !c.tieneHitos)
              .toList();
        } else if (_filtroComplejidad == 'complejo') {
          completadosInfo = completadosInfo
              .where((c) => c.tieneHitos)
              .toList();
        }

        if (completadosInfo.isEmpty) {
          final conFiltros = _busqueda.isNotEmpty ||
              _filtroTipo != null ||
              _filtroComplejidad != null;
          return EmptyState(
            icon: Icons.flag_outlined,
            title: conFiltros ? 'Sin resultados' : 'Sin retos completados',
            message: conFiltros
                ? 'No hay retos que coincidan con los filtros.'
                : 'Completa tu primer reto para verlo aquí.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
          itemCount: completadosInfo.length,
          itemBuilder: (context, index) {
            final c = completadosInfo[index];
            final reto = c.reto;
            final tipoColor = reto.tipo == 'fitness'
                ? Colors.green
                : Colors.blue;
            final tipoIcono = reto.tipo == 'fitness'
                ? Icons.fitness_center_rounded
                : Icons.school_rounded;
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: Icon(tipoIcono, color: tipoColor),
                title: Text(reto.titulo,
                    style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey)),
                subtitle: Text(
                    '${reto.meta} · ${DateFormat('dd/MM/yy').format(reto.fechaFin)}${c.tieneHitos ? "" : " · Simple"}',
                    style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.check_circle,
                    color: Colors.green, size: 22),
                onTap: () => context.push('/retos/${reto.id}'),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<_RetoCompletadoInfo>> _cargarCompletados() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return [];
    final data = await client
        .from('retos')
        .select()
        .eq('usuario_id', user.id)
        .eq('esta_completado', true)
        .order('fecha_fin', ascending: false)
        .limit(20);

    final retos =
        (data as List).map((r) => RetoDb.fromMap(r)).toList();

    if (retos.isEmpty) return [];

    final retoIds = retos.map((r) => r.id).toList();
    final hitosData = await client
        .from('hitos_de_reto')
        .select('reto_id')
        .inFilter('reto_id', retoIds);
    final retosConHitos =
        (hitosData as List).map((h) => h['reto_id'] as String).toSet();

    return retos
        .map((r) => _RetoCompletadoInfo(
              reto: r,
              tieneHitos: retosConHitos.contains(r.id),
            ))
        .toList();
  }

  List<RetoResumen> _aplicarFiltros(List<RetoResumen> retos) {
    var filtrados = retos;
    if (_busqueda.isNotEmpty) {
      filtrados = filtrados
          .where((r) =>
              r.reto.titulo.toLowerCase().contains(_busqueda) ||
              r.reto.meta.toLowerCase().contains(_busqueda))
          .toList();
    }
    if (_filtroTipo != null) {
      filtrados =
          filtrados.where((r) => r.reto.tipo == _filtroTipo).toList();
    }
    if (_filtroComplejidad == 'simple') {
      filtrados = filtrados.where((r) => !r.tieneHitos).toList();
    } else if (_filtroComplejidad == 'complejo') {
      filtrados = filtrados.where((r) => r.tieneHitos).toList();
    }
    return filtrados;
  }

  void _confirmarCompletarDesdeLista(BuildContext context, String retoId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Completar reto'),
        content: const Text('¿Marcar este reto como completado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await completarReto(retoId);
              ref.invalidate(retosProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reto completado'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Completar'),
          ),
        ],
      ),
    );
  }
}

class _RetoCard extends StatelessWidget {
  const _RetoCard({
    required this.item,
    required this.esExplorar,
    this.onClone,
    this.onComplete,
    required this.onTap,
  });

  final RetoResumen item;
  final bool esExplorar;
  final VoidCallback? onClone;
  final VoidCallback? onComplete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reto = item.reto;
    final tipoIcono = reto.tipo == 'fitness'
        ? Icons.fitness_center_rounded
        : Icons.school_rounded;
    final tipoColor =
        reto.tipo == 'fitness' ? Colors.green : Colors.blue;
    final diasRestantes =
        reto.fechaFin.difference(DateTime.now()).inDays;
    final textoDias = diasRestantes > 0
        ? '$diasRestantes d'
        : diasRestantes == 0
            ? 'Hoy'
            : 'Vencido';

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tipoColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tipoIcono,
                            size: 14, color: tipoColor),
                        const SizedBox(width: 4),
                        Text(
                          reto.tipo == 'fitness'
                              ? 'Fitness'
                              : 'Académico',
                          style: TextStyle(
                              fontSize: 11,
                              color: tipoColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                   ),
                   if (item.tieneHitos) ...[
                     const SizedBox(width: 6),
                     Container(
                       padding: const EdgeInsets.symmetric(
                           horizontal: 6, vertical: 2),
                       decoration: BoxDecoration(
                         color: Colors.deepPurple.withValues(alpha: 0.1),
                         borderRadius: BorderRadius.circular(6),
                       ),
                       child: const Text('Complejo',
                           style: TextStyle(
                               fontSize: 10,
                               color: Colors.deepPurple,
                               fontWeight: FontWeight.w600)),
                     ),
                   ] else ...[
                     const SizedBox(width: 6),
                     Container(
                       padding: const EdgeInsets.symmetric(
                           horizontal: 6, vertical: 2),
                       decoration: BoxDecoration(
                         color: Colors.green.withValues(alpha: 0.1),
                         borderRadius: BorderRadius.circular(6),
                       ),
                       child: const Text('Simple',
                           style: TextStyle(
                               fontSize: 10,
                               color: Colors.green,
                               fontWeight: FontWeight.w600)),
                     ),
                   ],
                  const Spacer(),
                  Text(textoDias,
                      style: TextStyle(
                        fontSize: 11,
                        color: diasRestantes <= 3
                            ? Colors.red
                            : Colors.grey,
                        fontWeight: FontWeight.w500,
                      )),
                   if (onClone != null) ...[
                     const SizedBox(width: 4),
                     InkWell(
                       onTap: onClone,
                       borderRadius: BorderRadius.circular(8),
                       child: const Padding(
                         padding: EdgeInsets.all(4),
                         child: Icon(Icons.copy,
                             size: 16, color: Colors.grey),
                       ),
                     ),
                   ],
                   if (onComplete != null) ...[
                     const SizedBox(width: 4),
                     InkWell(
                       onTap: onComplete,
                       borderRadius: BorderRadius.circular(8),
                       child: const Padding(
                         padding: EdgeInsets.all(4),
                         child: Icon(Icons.check_circle_outline,
                             size: 18, color: Colors.green),
                       ),
                     ),
                   ],
                ],
              ),
              const SizedBox(height: 8),
              Text(reto.titulo,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              if (reto.meta.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(reto.meta,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 8),
              ChallengeProgressBar(
                progress: item.progreso,
              ),
              const SizedBox(height: 2),
              Text('${(item.progreso * 100).round()}% completado',
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetoCompletadoInfo {
  const _RetoCompletadoInfo({
    required this.reto,
    required this.tieneHitos,
  });

  final RetoDb reto;
  final bool tieneHitos;
}

class _FiltroChip extends StatelessWidget {
  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: onSelected,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
