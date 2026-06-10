import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../../../core/design_system/sv_colors.dart';
import '../application/dashboard_provider.dart';
import 'widgets/saludo_card.dart';
import 'widgets/smart_banner_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/plan_week_bar.dart';
import 'widgets/cognitive_load_bar.dart';
import 'widgets/estado_section.dart';
import 'widgets/kpi_grid.dart';
import 'widgets/bienestar_card.dart';
import 'widgets/retos_section.dart';
import 'widgets/rutinas_section.dart';

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
      descripcion: 'Reto con tareas y progreso.',
      icono: Icons.emoji_events_rounded,
      ruta: '/retos/complejo',
    ),
    _OpcionCreacionDashboard(
      titulo: 'Plan semanal de estudio',
      descripcion: 'Organiza tu semana y horarios.',
      icono: Icons.school_rounded,
      ruta: '/plan-semanal/crear',
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
                  // 1. SaludoCard — greeting + avatar + XP + nivel + streaks
                  Consumer(
                    builder: (context, ref, _) {
                      final adherencia =
                          ref.watch(adherenciaAcademicaProvider).valueOrNull;
                      return SaludoCard(
                        data: value,
                        rachaEntrenamiento: value.racha,
                        diasEstudio: adherencia?.rachaDias.round() ?? 0,
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  // 2. SmartBannerCard — consejo IA (Gemini o fallback)
                  const SmartBannerCard(),
                  const SizedBox(height: 14),
                  // 3. QuickActionsRow — 4 chips de acceso rápido
                  const QuickActionsRow(),
                  const SizedBox(height: 16),
                  // 4. PlanWeekBar — "Semana X de Y" (auto-hide si no hay rutina)
                  const PlanWeekBar(),
                  const SizedBox(height: 12),
                  // 5. CognitiveLoadBar — barra de carga cognitiva (auto-hide si no hay datos)
                  const CognitiveLoadBar(),
                  const SizedBox(height: 12),
                  // 6. EstadoSection — EnergyRing + Adherencia (+ Estudio si hay carga)
                  const EstadoSection(),
                  const SizedBox(height: 14),
                  // 7. KpiGrid — calorías + sesiones
                  KpiGrid(
                    data: value,
                    isWide: isWide,
                    isVeryWide: isVeryWide,
                  ),
                  const SizedBox(height: 14),
                  // 8. BienestarCard — IMC, peso, objetivo (si hay perfil)
                  if (value.perfilBienestar != null) ...[
                    BienestarCard(perfil: value.perfilBienestar!),
                    const SizedBox(height: 14),
                  ],
                  // 9. RetosSection — retos activos con progreso
                  RetosSection(data: value),
                  const SizedBox(height: 14),
                  // 10. RutinasSection — rutinas activas
                  RutinasSection(data: value),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Menú de creación rápida con opciones del dashboard.
  /// Conservado por si se reactiva como FAB o gesture en el futuro.
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
