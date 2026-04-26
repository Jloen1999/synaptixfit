import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/kpi_card.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../application/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _opcionesCreacion = <_OpcionCreacionDashboard>[
    _OpcionCreacionDashboard(
      titulo: 'Nueva rutina',
      descripcion: 'Diseña y guarda tu rutina de entrenamiento.',
      icono: Icons.fitness_center_rounded,
      ruta: '/bienestar/constructor-rutina',
    ),
    _OpcionCreacionDashboard(
      titulo: 'Reto simple',
      descripcion: 'Crea un reto rapido con un objetivo principal.',
      icono: Icons.flag_rounded,
      ruta: '/retos/simple',
    ),
    _OpcionCreacionDashboard(
      titulo: 'Reto complejo',
      descripcion: 'Configura hitos y progreso detallado del reto.',
      icono: Icons.emoji_events_rounded,
      ruta: '/retos/complejo',
    ),
    _OpcionCreacionDashboard(
      titulo: 'Plan de estudio',
      descripcion: 'Organiza tu semana academica y prioridades.',
      icono: Icons.school_rounded,
      ruta: '/plan-semanal',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardProvider);
    return FeatureScaffold(
      title: '',
      centerTitle: false,
      appBarLeading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Image.asset(
          'assets/images/logo.png',
          width: 36,
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.fitness_center_rounded,
            size: 24,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarMenuCreacion(context),
        tooltip: 'Crear',
        child: const Icon(Icons.add),
      ),
      child: data.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SkeletonLoader(height: 140),
              SizedBox(height: 12),
              SkeletonLoader(height: 100),
              SizedBox(height: 12),
              SkeletonLoader(height: 100),
            ],
          ),
        ),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (value) => LayoutBuilder(
          builder: (context, constraints) {
            final useGrid = constraints.maxWidth >= 760;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // -----------------------------------------------------------
                // Tarjeta de saludo premium
                // -----------------------------------------------------------
                _SaludoCard(data: value),
                const SizedBox(height: 16),

                // -----------------------------------------------------------
                // KPIs con progreso
                // -----------------------------------------------------------
                if (!useGrid) ...[
                  KpiCard(
                    title: 'Calorías hoy',
                    value: '${value.calorias} kcal',
                    icon: Icons.local_fire_department_rounded,
                    progress: (value.calorias / 800).clamp(0.0, 1.0),
                    gradientColors: [
                      const Color(0xFFFF6B35).withValues(alpha: 0.12),
                      const Color(0xFFFF6B35).withValues(alpha: 0.04),
                    ],
                    subtitle: 'Meta: 800 kcal',
                  ),
                  const SizedBox(height: 10),
                  KpiCard(
                    title: 'Sesiones',
                    value: '${value.sesiones}',
                    icon: Icons.fitness_center_rounded,
                    progress: value.planSemanal != null
                        ? (value.sesiones /
                                value.planSemanal!.sesionesPlanificadas)
                            .clamp(0.0, 1.0)
                        : null,
                    subtitle: value.planSemanal != null
                        ? '${value.sesionesRestantesSemana} restantes esta semana'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  KpiCard(
                    title: 'Horas estudio',
                    value: value.horasEstudio.toStringAsFixed(1),
                    icon: Icons.school_rounded,
                    progress: (value.horasEstudio / 6).clamp(0.0, 1.0),
                    gradientColors: [
                      const Color(0xFF7B1FA2).withValues(alpha: 0.10),
                      const Color(0xFF7B1FA2).withValues(alpha: 0.03),
                    ],
                    subtitle: 'Meta: 6 hrs/día',
                  ),
                ] else
                  GridView.count(
                    crossAxisCount: constraints.maxWidth >= 1040 ? 3 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: constraints.maxWidth >= 1040 ? 2.2 : 1.7,
                    children: [
                      KpiCard(
                        title: 'Calorías hoy',
                        value: '${value.calorias} kcal',
                        icon: Icons.local_fire_department_rounded,
                        progress: (value.calorias / 800).clamp(0.0, 1.0),
                      ),
                      KpiCard(
                        title: 'Sesiones',
                        value: '${value.sesiones}',
                        icon: Icons.fitness_center_rounded,
                      ),
                      KpiCard(
                        title: 'Horas estudio',
                        value: value.horasEstudio.toStringAsFixed(1),
                        icon: Icons.school_rounded,
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // -----------------------------------------------------------
                // Resumen de bienestar rápido
                // -----------------------------------------------------------
                if (value.perfilBienestar != null) ...[
                  _BienestarResumenCard(perfil: value.perfilBienestar!),
                  const SizedBox(height: 20),
                ],

                // -----------------------------------------------------------
                // Retos activos mejorados
                // -----------------------------------------------------------
                Row(
                  children: [
                    Icon(Icons.flag_rounded,
                        size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Retos activos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (value.retosActivos.isEmpty)
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.inbox_rounded, color: Colors.grey),
                          SizedBox(width: 12),
                          Text('No tienes retos activos por ahora.'),
                        ],
                      ),
                    ),
                  )
                else
                  ...value.retosActivos.map(
                    (reto) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RetoActivoCard(
                        reto: reto,
                        progreso: value.progresoReto(reto.id),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _mostrarMenuCreacion(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crear en SynaptixFit',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Accesos directos a los flujos de creacion mas importantes.',
                  style: Theme.of(sheetContext).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                ..._opcionesCreacion.map(
                  (opcion) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Icon(opcion.icono),
                    ),
                    title: Text(opcion.titulo),
                    subtitle: Text(opcion.descripcion),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.go(opcion.ruta);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OpcionCreacionDashboard {
  const _OpcionCreacionDashboard({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.ruta,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;
  final String ruta;
}

// ---------------------------------------------------------------------------
// Tarjeta de saludo premium con gradiente, avatar, XP y racha
// ---------------------------------------------------------------------------
class _SaludoCard extends StatelessWidget {
  const _SaludoCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final nombre = data.usuario.nombreCompleto.split(' ').first;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF002546), Color(0xFF0D3B66), Color(0xFF1A5276)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF002546).withValues(alpha: 0.3),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, $nombre 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nivel ${data.usuario.nivel}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Racha con ícono de fuego
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '${data.racha}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barra de XP
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${data.usuario.xpTotal} / ${data.xpParaSiguienteNivel} XP',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Nivel ${data.usuario.nivel + 1}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: data.xpProgreso.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF72FE8F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (data.notificacionesNoLeidas.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_rounded,
                      size: 14, color: Colors.white.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Text(
                    '${data.notificacionesNoLeidas.length} notificaciones sin leer',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta resumen de bienestar
// ---------------------------------------------------------------------------
class _BienestarResumenCard extends StatelessWidget {
  const _BienestarResumenCard({required this.perfil});

  final dynamic perfil;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.secondary.withValues(alpha: 0.06),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_rounded,
                    size: 18, color: theme.colorScheme.secondary),
                const SizedBox(width: 6),
                Text(
                  'Resumen de bienestar',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _BienestarChip(
                  label: 'IMC ${perfil.imc.toStringAsFixed(1)}',
                  sublabel: perfil.imcCategoria,
                  icon: Icons.monitor_weight_rounded,
                ),
                const SizedBox(width: 10),
                _BienestarChip(
                  label: '${perfil.pesoKg.toStringAsFixed(1)} kg',
                  sublabel: 'Peso actual',
                  icon: Icons.scale_rounded,
                ),
                const SizedBox(width: 10),
                _BienestarChip(
                  label: _objetivoLabel(perfil.objetivoPrincipal),
                  sublabel: 'Objetivo',
                  icon: Icons.flag_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _objetivoLabel(String objetivo) => switch (objetivo) {
        'fitness_general' => 'Fitness',
        'perder_peso' => 'Perder peso',
        'ganar_masa' => 'Masa muscular',
        'fuerza' => 'Fuerza',
        'resistencia' => 'Resistencia',
        'movilidad' => 'Movilidad',
        _ => objetivo,
      };
}

class _BienestarChip extends StatelessWidget {
  const _BienestarChip({
    required this.label,
    required this.sublabel,
    required this.icon,
  });

  final String label;
  final String sublabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              sublabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de reto activo mejorada
// ---------------------------------------------------------------------------
class _RetoActivoCard extends StatelessWidget {
  const _RetoActivoCard({required this.reto, required this.progreso});

  final dynamic reto;
  final double progreso;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esFitness = reto.tipo == 'fitness';
    final color =
        esFitness ? theme.colorScheme.primary : const Color(0xFF7B1FA2);
    final diasRestantes = reto.fechaFin.difference(DateTime.now()).inDays;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Progreso circular
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progreso.clamp(0.0, 1.0),
                    strokeWidth: 4,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  Text(
                    '${(progreso * 100).round()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
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
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          esFitness ? '💪 Fitness' : '📚 Académico',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (diasRestantes > 0)
                        Text(
                          '$diasRestantes días',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reto.titulo,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progreso.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
