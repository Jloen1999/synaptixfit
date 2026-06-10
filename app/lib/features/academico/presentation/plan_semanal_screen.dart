import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../core/design_system/sv_colors.dart';
import '../../retos/application/retos_provider.dart';
import '../application/balance_semanal_provider.dart';
import '../application/entregas_examenes_provider.dart';
import '../application/planes_estudio_provider.dart';

class PlanSemanalScreen extends ConsumerStatefulWidget {
  const PlanSemanalScreen({super.key});

  @override
  ConsumerState<PlanSemanalScreen> createState() => _PlanSemanalScreenState();
}

class _PlanSemanalScreenState extends ConsumerState<PlanSemanalScreen> {
  int _diaSeleccionado = DateTime.now().weekday;
  Timer? _pomodoroTimer;
  int _pomodoroRestante = 0;
  bool _pomodoroActivo = false;

  @override
  void dispose() {
    _pomodoroTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horariosAsync = ref.watch(horariosSemanaActualProvider);
    final balanceAsync = ref.watch(balanceSemanalProvider);
    final retosAsync = ref.watch(retosProvider);

    return FeatureScaffold(
      title: 'Plan Semanal',
      backPath: '/dashboard',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFabMenu(context),
        child: const Icon(Icons.add),
      ),
      child: Column(
        children: [
          _SelectorDias(
            diaSeleccionado: _diaSeleccionado,
            onChanged: (d) => setState(() => _diaSeleccionado = d),
          ),
          Expanded(
            child: horariosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (horarios) {
                return balanceAsync.when(
                  loading: () => ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildBalanceSkeleton(),
                      _buildTimelineSkeleton(),
                    ],
                  ),
                  error: (_, __) => _buildTimeline(context, horarios, []),
                  data: (balance) {
                    return retosAsync.when(
                      loading: () =>
                          _buildContenido(context, horarios, balance, const []),
                      error: (_, __) =>
                          _buildContenido(context, horarios, balance, const []),
                      data: (retos) =>
                          _buildContenido(context, horarios, balance, retos),
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

  Widget _buildContenido(
      BuildContext context,
      List<HorarioAcademicoDb> horarios,
      BalanceSemanalDto balance,
      List<RetoResumen> retos) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        if (retos.isNotEmpty) ...[
          _RetoBanner(retos: retos),
          const SizedBox(height: 12),
        ],
        _buildBalanceHeader(context, balance),
        const SizedBox(height: 16),
        _buildTimeline(context, horarios,
            ref.watch(entregasPendientesProvider).valueOrNull ?? []),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Balance header
  // ---------------------------------------------------------------------------
  Widget _buildBalanceHeader(BuildContext context, BalanceSemanalDto balance) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estudio',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: SVColors.onSurfaceMuted)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: balance.horasEstudioPlaneadas > 0
                              ? (balance.horasEstudioReales /
                                      balance.horasEstudioPlaneadas)
                                  .clamp(0.0, 1.0)
                              : 0,
                          minHeight: 8,
                          backgroundColor: Colors.blue.withValues(alpha: 0.15),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${balance.horasEstudioReales.toStringAsFixed(1)} / ${balance.horasEstudioPlaneadas.toStringAsFixed(1)} h',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Deporte',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: SVColors.onSurfaceMuted)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: balance.horasDeportePlaneadas > 0
                              ? (balance.horasDeporteReales /
                                      balance.horasDeportePlaneadas)
                                  .clamp(0.0, 1.0)
                              : 0,
                          minHeight: 8,
                          backgroundColor:
                              const Color(0xFF00ACC1).withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF00ACC1)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${balance.horasDeporteReales.toStringAsFixed(1)} / ${balance.horasDeportePlaneadas.toStringAsFixed(1)} h',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _balanceColor(balance.estado).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    balance.estado == 'equilibrado'
                        ? Icons.balance_rounded
                        : Icons.warning_amber_rounded,
                    size: 18,
                    color: _balanceColor(balance.estado),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      balance.mensaje,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _balanceColor(balance.estado),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (balance.sugerencia.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                balance.sugerencia,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: SVColors.onSurfaceMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSkeleton() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }

  Widget _buildTimelineSkeleton() {
    return Column(
      children: List.generate(
          3,
          (_) => Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Container(
                  height: 72,
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    children: [
                      SizedBox(width: 40, child: Icon(Icons.schedule)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SkeletonBar(width: 120, height: 10),
                            SizedBox(height: 6),
                            _SkeletonBar(width: 80, height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
    );
  }

  // ---------------------------------------------------------------------------
  // Timeline
  // ---------------------------------------------------------------------------
  Widget _buildTimeline(BuildContext context, List<HorarioAcademicoDb> horarios,
      List<EntregaExamenDb> entregas) {
    final diaSeleccionado = _diaSeleccionado;

    final bloquesDia = horarios.where((h) {
      return h.horaInicio.weekday == diaSeleccionado;
    }).toList();

    final entregasDia = entregas.where((e) {
      return e.fechaLimite.weekday == diaSeleccionado;
    }).toList();

    final todos = <Widget>[];

    for (final b in bloquesDia) {
      todos.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _TimelineCard(
          bloque: b,
          onStartPomodoro:
              b.tipoActividad == 'estudio' ? () => _iniciarPomodoro() : null,
          onIniciarSesion: b.tipoActividad == 'deporte' && b.rutinaId != null
              ? () => _iniciarSesionDeporte(b)
              : null,
        ),
      ));
    }

    for (final e in entregasDia) {
      todos.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _EntregaTimelineCard(entrega: e),
      ));
    }

    if (todos.isEmpty) {
      return const EmptyState(
        icon: Icons.event_note_outlined,
        title: 'Sin actividades este día',
        message: 'Añade bloques de estudio, clases o entrenamientos.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _diaCompletoLabel(diaSeleccionado),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...todos,
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Pomodoro
  // ---------------------------------------------------------------------------
  void _iniciarPomodoro() {
    if (_pomodoroActivo) {
      _pomodoroTimer?.cancel();
      setState(() {
        _pomodoroActivo = false;
        _pomodoroRestante = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pomodoro cancelado'),
            duration: Duration(seconds: 2)),
      );
      return;
    }

    setState(() {
      _pomodoroRestante = 25 * 60;
      _pomodoroActivo = true;
    });

    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_pomodoroRestante <= 0) {
        timer.cancel();
        setState(() {
          _pomodoroActivo = false;
          _pomodoroRestante = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pomodoro completado. Tómate un descanso de 5 min.'),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
      setState(() => _pomodoroRestante--);
    });
  }

  // ---------------------------------------------------------------------------
  // FAB menu
  // ---------------------------------------------------------------------------
  void _mostrarFabMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Añadir rápido',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _FabOption(
                icon: Icons.menu_book_rounded,
                title: 'Bloque de estudio',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/plan-semanal/crear');
                },
              ),
              _FabOption(
                icon: Icons.assignment_outlined,
                title: 'Entrega o examen',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/plan-semanal/crear');
                },
              ),
              _FabOption(
                icon: Icons.fitness_center_rounded,
                title: 'Entrenamiento',
                color: const Color(0xFF00ACC1),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/plan-semanal/crear');
                },
              ),
              _FabOption(
                icon: Icons.calendar_month_outlined,
                title: 'Crear plan completo',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/plan-semanal/crear');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _iniciarSesionDeporte(HorarioAcademicoDb bloque) {
    context.push('/bienestar/rutina/sesion', extra: {
      'rutinaId': bloque.rutinaId,
    });
  }

  static Color _balanceColor(String estado) {
    return switch (estado) {
      'equilibrado' => Colors.green,
      'carga_estudio' => Colors.orange,
      'carga_deporte' => Colors.blue,
      _ => SVColors.onSurfaceMuted,
    };
  }

  static String _diaCompletoLabel(int d) {
    return [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ][d - 1];
  }
}

// ---------------------------------------------------------------------------
// Selector de días
// ---------------------------------------------------------------------------
class _SelectorDias extends StatelessWidget {
  const _SelectorDias({required this.diaSeleccionado, required this.onChanged});

  final int diaSeleccionado;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (i) {
          final d = i + 1;
          final activo = d == diaSeleccionado;
          return GestureDetector(
            onTap: () => onChanged(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activo
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Text(
                  ['L', 'M', 'X', 'J', 'V', 'S', 'D'][i],
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: activo
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline cards
// ---------------------------------------------------------------------------
class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.bloque,
    this.onStartPomodoro,
    this.onIniciarSesion,
  });

  final HorarioAcademicoDb bloque;
  final VoidCallback? onStartPomodoro;
  final VoidCallback? onIniciarSesion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, icono) = _estiloBloque(bloque.tipoActividad);

    final horaInicio =
        '${bloque.horaInicio.hour.toString().padLeft(2, '0')}:${bloque.horaInicio.minute.toString().padLeft(2, '0')}';
    final horaFin =
        '${bloque.horaFin.hour.toString().padLeft(2, '0')}:${bloque.horaFin.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.15)),
      ),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Icon(icono, size: 20, color: color),
                const SizedBox(height: 4),
                Text(horaInicio,
                    style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _tipoLabel(bloque.tipoActividad),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (bloque.prioridad == 'alta')
                        Icon(Icons.flag_rounded,
                            size: 12, color: Colors.red.shade300),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _nombreBloque(bloque),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (bloque.temas != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Tema: ${bloque.temas}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: SVColors.onSurfaceMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$horaInicio - $horaFin',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: SVColors.onSurfaceMuted,
                        ),
                      ),
                      const Spacer(),
                      if (onStartPomodoro != null)
                        _ActionChip(
                          label: 'Pomodoro',
                          icon: Icons.timer_outlined,
                          color: Colors.blue,
                          onTap: onStartPomodoro!,
                        ),
                      if (onIniciarSesion != null) ...[
                        const SizedBox(width: 6),
                        _ActionChip(
                          label: 'Iniciar',
                          icon: Icons.play_arrow_rounded,
                          color: const Color(0xFF00ACC1),
                          onTap: onIniciarSesion!,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _nombreBloque(HorarioAcademicoDb b) {
    return b.asignaturaId;
  }

  static (Color, IconData) _estiloBloque(String tipo) {
    return switch (tipo) {
      'clase' => (Colors.purple, Icons.school_rounded),
      'deporte' => (const Color(0xFF00ACC1), Icons.fitness_center_rounded),
      _ => (Colors.blue, Icons.menu_book_rounded),
    };
  }

  static String _tipoLabel(String tipo) {
    return switch (tipo) {
      'clase' => 'Clase',
      'deporte' => 'Deporte',
      _ => 'Estudio',
    };
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 9, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _EntregaTimelineCard extends ConsumerWidget {
  const _EntregaTimelineCard({required this.entrega});

  final EntregaExamenDb entrega;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final diasRestantes = entrega.fechaLimite.difference(DateTime.now()).inDays;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      color: theme.colorScheme.surfaceContainerLowest,
      child: InkWell(
        onTap: () async {
          await toggleEntregaCompletada(entrega.id, !entrega.estaCompletado);
          ref.invalidate(entregasPendientesProvider);
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: entrega.estaCompletado ? Colors.grey : Colors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                entrega.estaCompletado
                    ? Icons.check_circle
                    : (entrega.tipo == 'examen'
                        ? Icons.quiz_outlined
                        : Icons.assignment_outlined),
                size: 20,
                color: entrega.estaCompletado ? Colors.grey : Colors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _tipoEntregaLabel(entrega.tipo),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: _dificultadColor(entrega.dificultad)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _dificultadLabel(entrega.dificultad),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _dificultadColor(entrega.dificultad),
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entrega.titulo,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        decoration: entrega.estaCompletado
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      diasRestantes > 0
                          ? 'Vence en $diasRestantes días'
                          : diasRestantes == 0
                              ? 'Vence hoy'
                              : 'Vencido',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: diasRestantes <= 1
                            ? Colors.red
                            : SVColors.onSurfaceMuted,
                        fontWeight: diasRestantes <= 1 ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _tipoEntregaLabel(String t) {
    return {
          'examen': 'Examen',
          'entrega': 'Entrega',
          'presentacion': 'Presentación',
          'otro': 'Otro'
        }[t] ??
        t;
  }

  static String _dificultadLabel(String d) {
    return {'baja': 'Baja', 'media': 'Media', 'alta': 'Alta'}[d] ?? d;
  }

  static Color _dificultadColor(String d) {
    return {
          'baja': Colors.green,
          'media': Colors.orange,
          'alta': Colors.red
        }[d] ??
        Colors.grey;
  }
}

// ---------------------------------------------------------------------------
// Reto banner
// ---------------------------------------------------------------------------
class _RetoBanner extends StatelessWidget {
  const _RetoBanner({required this.retos});

  final List<RetoResumen> retos;

  @override
  Widget build(BuildContext context) {
    final academicos = retos.where((r) => r.reto.tipo == 'academico').toList();
    if (academicos.isEmpty) return const SizedBox.shrink();

    final primero = academicos.first;
    return Card(
      elevation: 0,
      color: const Color(0xFF7B1FA2).withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            BorderSide(color: const Color(0xFF7B1FA2).withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: Color(0xFF7B1FA2), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                primero.reto.titulo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7B1FA2),
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 60,
                height: 6,
                child: LinearProgressIndicator(
                  value: primero.progreso,
                  backgroundColor:
                      const Color(0xFF7B1FA2).withValues(alpha: 0.15),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF7B1FA2)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(primero.progreso * 100).round()}%',
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7B1FA2)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FAB option
// ---------------------------------------------------------------------------
class _FabOption extends StatelessWidget {
  const _FabOption({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: SVColors.onSurfaceMuted),
        onTap: onTap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton
// ---------------------------------------------------------------------------
class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: SVColors.onSurfaceMuted.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
