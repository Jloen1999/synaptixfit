import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/kpi_card.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/challenge_progress_bar.dart';
import '../../../shared/models/db_models.dart';
import '../../../core/design_system/sv_colors.dart';
import '../../retos/application/retos_provider.dart';
import '../application/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _opcionesCreacion = <_OpcionCreacionDashboard>[
    _OpcionCreacionDashboard(
      titulo: 'Nueva rutina',
      descripcion: 'Diseña tu rutina de ejercicios.',
      icono: Icons.fitness_center_rounded,
      ruta: '/bienestar/nueva-rutina',
    ),
    _OpcionCreacionDashboard(
      titulo: 'Reto simple',
      descripcion: 'Crea un reto con un objetivo.',
      icono: Icons.flag_rounded,
      ruta: '/retos/simple',
    ),
    _OpcionCreacionDashboard(
      titulo: 'Reto complejo',
      descripcion: 'Reto con hitos y progreso.',
      icono: Icons.emoji_events_rounded,
      ruta: '/retos/complejo',
    ),
    _OpcionCreacionDashboard(
      titulo: 'Plan semanal de estudio',
      descripcion: 'Organiza tu semana y horarios.',
      icono: Icons.school_rounded,
      ruta: '/plan-semanal',
    ),
    _OpcionCreacionDashboard(
      titulo: 'Nuevo apunte',
      descripcion: 'Escribe un apunte con Markdown.',
      icono: Icons.article_outlined,
      ruta: '/academico/apuntes/editor',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardProvider);

    return FeatureScaffold(
      title: '',
      centerTitle: false,
      hideAppBar: true,
      child: data.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SkeletonLoader(height: 160),
              SizedBox(height: 12),
              SkeletonLoader(height: 80),
              SizedBox(height: 12),
              SkeletonLoader(height: 80),
              SizedBox(height: 12),
              SkeletonLoader(height: 80),
            ],
          ),
        ),
        error: (error, _) {
          final msg = error.toString();
          final esErrorRed = msg.contains('SocketException') ||
              msg.contains('Failed host lookup') ||
              msg.contains('No address associated');
          return Center(
            child: EmptyState(
              title: esErrorRed ? 'Sin conexión' : 'Error al cargar',
              message: esErrorRed
                  ? 'No se pudo conectar con el servidor. Comprueba tu conexión a internet.'
                  : 'No se pudo cargar el dashboard.',
              icon:
                  esErrorRed ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
              action: TextButton(
                onPressed: () => ref.invalidate(dashboardProvider),
                child: const Text('Reintentar'),
              ),
            ),
          );
        },
        data: (value) {
          final topPadding = MediaQuery.of(context).padding.top + 8;
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;
              final isVeryWide = constraints.maxWidth >= 1040;

              return ListView(
                padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
                children: [
                  _SaludoCard(data: value),
                  const SizedBox(height: 18),
                  if (!isWide)
                    ..._buildKpiColumn(value)
                  else
                    _buildKpiGrid(value, isVeryWide),
                  const SizedBox(height: 20),
                  if (value.perfilBienestar != null) ...[
                    _BienestarResumenCard(perfil: value.perfilBienestar!),
                    const SizedBox(height: 20),
                  ],
                  _buildRetosSection(context, value),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildKpiColumn(dynamic value) => [
        KpiCard(
          title: 'Calorías hoy',
          value: '${value.calorias}',
          subtitle: 'Meta: 800 kcal',
          icon: Icons.local_fire_department_rounded,
          progress: (value.calorias / 800).clamp(0.0, 1.0),
          accentColor: SVColors.kpiCalorias,
        ),
        const SizedBox(height: 10),
        KpiCard(
          title: 'Sesiones completadas',
          value: '${value.sesiones}',
          subtitle: value.planSemanal != null
              ? '${value.sesionesRestantesSemana} restantes esta semana'
              : null,
          icon: Icons.fitness_center_rounded,
          progress: value.planSemanal != null
              ? (value.sesiones / value.planSemanal!.sesionesPlanificadas)
                  .clamp(0.0, 1.0)
              : null,
          accentColor: SVColors.kpiSesiones,
        ),
        const SizedBox(height: 10),
        KpiCard(
          title: 'Horas de estudio',
          value: value.horasEstudio.toStringAsFixed(1),
          subtitle: 'Meta: 6 h/día',
          icon: Icons.school_rounded,
          progress: (value.horasEstudio / 6).clamp(0.0, 1.0),
          accentColor: SVColors.kpiEstudio,
        ),
      ];

  Widget _buildKpiGrid(dynamic value, bool isVeryWide) {
    return GridView.count(
      crossAxisCount: isVeryWide ? 3 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isVeryWide ? 2.3 : 1.8,
      children: [
        KpiCard(
          title: 'Calorías hoy',
          value: '${value.calorias}',
          subtitle: 'Meta: 800 kcal',
          icon: Icons.local_fire_department_rounded,
          progress: (value.calorias / 800).clamp(0.0, 1.0),
          accentColor: SVColors.kpiCalorias,
        ),
        KpiCard(
          title: 'Sesiones completadas',
          value: '${value.sesiones}',
          subtitle: value.planSemanal != null
              ? '${value.sesionesRestantesSemana} restantes'
              : null,
          icon: Icons.fitness_center_rounded,
          accentColor: SVColors.kpiSesiones,
        ),
        KpiCard(
          title: 'Horas de estudio',
          value: value.horasEstudio.toStringAsFixed(1),
          subtitle: 'Meta: 6 h/día',
          icon: Icons.school_rounded,
          accentColor: SVColors.kpiEstudio,
        ),
        if (isVeryWide)
          KpiCard(
            title: 'Racha actual',
            value: '${value.racha} días',
            subtitle: '¡Sigue así!',
            icon: Icons.local_fire_department_rounded,
            progress: (value.racha / 30).clamp(0.0, 1.0),
            accentColor: SVColors.kpiRacha,
          ),
      ],
    );
  }

  Widget _buildRetosSection(BuildContext context, dynamic value) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Retos activos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            if (value.retosActivos.isNotEmpty)
              Text(
                '${value.retosActivos.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: SVColors.onSurfaceMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (value.retosActivos.isEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    color: SVColors.onSurfaceMuted.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'No tienes retos activos. ¡Crea uno!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: SVColors.onSurfaceMuted,
                    ),
                  ),
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
                tieneHitos: value.tieneHitosReto(reto.id),
                onTap: () => context.push('/retos/${reto.id}'),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _mostrarMenuCreacion(BuildContext context) async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crear en SynaptixFit',
                    softWrap: true,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Accesos directos a los flujos de creación.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: SVColors.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._opcionesCreacion.map(
                    (opcion) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            opcion.icono,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          opcion.titulo,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          opcion.descripcion,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: SVColors.onSurfaceMuted,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: SVColors.onSurfaceMuted,
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          context.push(opcion.ruta);
                        },
                      ),
                    ),
                  ),
                ],
              ),
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

  final dynamic data;

  @override
  Widget build(BuildContext context) {
    final usuario = data.usuario;
    final nombre = usuario.nombreCompleto.split(' ').first;
    final tieneAvatar =
        usuario.urlAvatar != null && usuario.urlAvatar!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF002546), Color(0xFF0D3B66), Color(0xFF153E5C)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF002546).withValues(alpha: 0.35),
            offset: const Offset(0, 10),
            blurRadius: 30,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/perfil'),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF72FE8F).withValues(alpha: 0.4),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: tieneAvatar
                        ? Image.network(
                            usuario.urlAvatar!,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _avatarFallback(
                                nombre, Colors.white.withValues(alpha: 0.18)),
                          )
                        : _avatarFallback(
                            nombre, Colors.white.withValues(alpha: 0.18)),
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
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Nivel ${usuario.nivel} · ${usuario.xpTotal} XP',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8A838).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE8A838).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 5),
                    Text(
                      '${data.racha}',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Barra de XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${data.usuario.xpTotal} / ${data.xpParaSiguienteNivel} XP',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.lock_open_rounded,
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Nivel ${data.usuario.nivel + 1}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: data.xpProgreso.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF72FE8F),
                  ),
                ),
              ),
            ],
          ),
          if (data.notificacionesNoLeidas.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_rounded,
                    size: 15,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${data.notificacionesNoLeidas.length} notificaciones sin leer',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatarFallback(String nombre, Color bgColor) {
    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: Text(
        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Resumen de bienestar',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _BienestarChip(
                label: 'IMC ${perfil.imc.toStringAsFixed(1)}',
                sublabel: perfil.imcCategoria,
                icon: Icons.monitor_weight_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              _BienestarChip(
                label: '${perfil.pesoKg.toStringAsFixed(1)} kg',
                sublabel: 'Peso actual',
                icon: Icons.scale_rounded,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 10),
              _BienestarChip(
                label: _objetivoLabel(perfil.objetivoPrincipal),
                sublabel: 'Objetivo',
                icon: Icons.flag_rounded,
                color: SVColors.accent,
              ),
            ],
          ),
        ],
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
    required this.color,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: SVColors.onSurfaceMuted,
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
// Tarjeta de reto activo mejorada con tareas expandibles y botón confirmar
// ---------------------------------------------------------------------------
class _RetoActivoCard extends ConsumerStatefulWidget {
  const _RetoActivoCard({
    required this.reto,
    required this.progreso,
    required this.tieneHitos,
    this.onTap,
  });

  final RetoDb reto;
  final double progreso;
  final bool tieneHitos;
  final VoidCallback? onTap;

  @override
  ConsumerState<_RetoActivoCard> createState() => _RetoActivoCardState();
}

class _RetoActivoCardState extends ConsumerState<_RetoActivoCard> {
  bool _expanded = false;
  bool _confirmando = false;
  final Map<String, bool> _optimistas = {};

  @override
  Widget build(BuildContext context) {
    final reto = widget.reto;
    final theme = Theme.of(context);
    final esFitness = reto.tipo == 'fitness';
    final color =
        esFitness ? theme.colorScheme.primary : const Color(0xFF7B1FA2);
    final diasRestantes = reto.fechaFin.difference(DateTime.now()).inDays;

    final expandible = widget.tieneHitos;
    final tareasAsync =
        _expanded ? ref.watch(tareasDeRetoProvider(reto.id)) : null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      color: theme.colorScheme.surfaceContainerLowest,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: tipo badge + complejidad + días restantes
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      esFitness ? '💪 Fitness' : '📚 Académico',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  widget.tieneHitos
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text('Complejo',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.w600)),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text('Simple',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600)),
                        ),
                  const Spacer(),
                  Icon(Icons.schedule_rounded,
                      size: 11, color: SVColors.onSurfaceMuted),
                  const SizedBox(width: 2),
                  Text(
                    diasRestantes > 0
                        ? '$diasRestantes d'
                        : diasRestantes == 0
                            ? 'Hoy'
                            : 'Vencido',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: diasRestantes <= 3
                          ? SVColors.error
                          : SVColors.onSurfaceMuted,
                      fontWeight: diasRestantes <= 3 ? FontWeight.w600 : null,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Titulo
              Text(
                reto.titulo,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Barra de progreso + Completar a la izquierda
              Row(
                children: [
                  // Botón Completar a la izquierda
                  InkWell(
                    onTap: _confirmando ? null : () => _confirmarCompletar(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _confirmando
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check,
                                    size: 12, color: Colors.green),
                                SizedBox(width: 3),
                                Text('Completar',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChallengeProgressBar(progress: widget.progreso),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${(widget.progreso * 100).round()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              // Tareas expandibles
              if (expandible) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _expanded ? 'Ocultar tareas' : 'Ver tareas',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (_expanded && tareasAsync != null)
                  tareasAsync.when(
                    data: (tareas) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: [
                          ...tareas.map((t) {
                            final completado = _optimistas.containsKey(t.id)
                                ? _optimistas[t.id]!
                                : t.estaCompletado;
                            return InkWell(
                              onTap: () async {
                                final nuevoValor = !completado;
                                setState(() => _optimistas[t.id] = nuevoValor);
                                try {
                                  await toggleTareaCompletada(
                                    t.id,
                                    widget.reto.id,
                                    completada: nuevoValor,
                                    ref: ref,
                                  );
                                } catch (_) {
                                  if (mounted) {
                                    setState(() => _optimistas.remove(t.id));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Error al ${nuevoValor ? "completar" : "desmarcar"} tarea'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      completado
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      size: 18,
                                      color: completado
                                          ? Colors.green
                                          : Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        t.titulo,
                                        style: TextStyle(
                                          fontSize: 12,
                                          decoration: completado
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color:
                                              completado ? Colors.grey : null,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${t.porcentajePeso}%',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (e, _) =>
                        Text('Error: $e', style: const TextStyle(fontSize: 11)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarCompletar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Completar reto'),
        content: Text('¿Marcar "${widget.reto.titulo}" como completado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, completar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _confirmando = true);
      try {
        await completarReto(widget.reto.id, ref);
      } finally {
        if (mounted) setState(() => _confirmando = false);
      }
    }
  }
}
