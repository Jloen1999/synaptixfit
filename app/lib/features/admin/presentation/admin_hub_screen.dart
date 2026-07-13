import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/admin_auditoria_provider.dart';
import '../application/admin_contenido_provider.dart';
import '../application/admin_ejercicio_provider.dart';
import '../application/admin_metricas_provider.dart';
import '../application/admin_provider.dart'
    show adminUsuariosProvider, esAdminProvider, lockdownStateProvider;
import 'admin_panel_screen.dart';
import 'widgets/admin_auditoria_list.dart';
import 'widgets/admin_contenido_list.dart';
import 'widgets/admin_ejercicio_list.dart';
import 'widgets/admin_kpi_dashboard.dart';

const _kAnchoRail = 600.0;

/// Pantalla principal del panel de administracion.
///
/// NavigationRail lateral en pantallas anchas y FilterChips horizontales
/// en pantallas estrechas. Cinco pestanas: KPIs, Usuarios, Contenido,
/// Ejercicios y Auditoria.
class AdminHubScreen extends ConsumerStatefulWidget {
  const AdminHubScreen({super.key});

  @override
  ConsumerState<AdminHubScreen> createState() => _AdminHubScreenState();
}

class _AdminHubScreenState extends ConsumerState<AdminHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _indicePestana = 0;

  static const _pestanas = <_PestanaAdmin>[
    _PestanaAdmin(
      indice: 0,
      icono: Icons.dashboard_rounded,
      iconoActivo: Icons.dashboard_rounded,
      etiqueta: 'KPIs',
    ),
    _PestanaAdmin(
      indice: 1,
      icono: Icons.people_outline_rounded,
      iconoActivo: Icons.people_rounded,
      etiqueta: 'Usuarios',
    ),
    _PestanaAdmin(
      indice: 2,
      icono: Icons.flag_outlined,
      iconoActivo: Icons.flag_rounded,
      etiqueta: 'Contenido',
      requiereBadge: true,
    ),
    _PestanaAdmin(
      indice: 3,
      icono: Icons.fitness_center_outlined,
      iconoActivo: Icons.fitness_center_rounded,
      etiqueta: 'Ejercicios',
    ),
    _PestanaAdmin(
      indice: 4,
      icono: Icons.history_rounded,
      iconoActivo: Icons.history_rounded,
      etiqueta: 'Auditoria',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _pestanas.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _indicePestana = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refrescarTodo() {
    ref.invalidate(adminMetricasProvider);
    ref.invalidate(adminUsuariosProvider);
    ref.invalidate(adminAuditoriaProvider);
    ref.invalidate(adminContenidoReportadoProvider);
    ref.invalidate(adminEjerciciosProvider);
    ref.invalidate(lockdownStateProvider);
  }

  void _navegarA(int indice) {
    setState(() => _indicePestana = indice);
    _tabController.animateTo(indice);
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = ref.watch(esAdminProvider);
    final cs = Theme.of(context).colorScheme;

    return esAdmin.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 44, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('Error al verificar permisos',
                  style: TextStyle(color: cs.onSurface)),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(esAdminProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (isAdmin) {
        if (!isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/dashboard');
          });
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No tienes permisos de administrador',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        }

        final metricasAsync = ref.watch(adminMetricasProvider);
        final contenidoBadge = metricasAsync.whenOrNull(
              data: (m) => m.contenidoReportadoPendiente,
            ) ??
            0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final esAncho = constraints.maxWidth >= _kAnchoRail;
            if (esAncho) {
              return _buildRail(context, contenidoBadge);
            }
            return _buildChips(context, contenidoBadge);
          },
        );
      },
    );
  }

  Widget _buildRail(BuildContext context, int badgeContenido) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administracion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refrescar',
            onPressed: _refrescarTodo,
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _indicePestana,
            onDestinationSelected: _navegarA,
            labelType: NavigationRailLabelType.all,
            groupAlignment: -0.5,
            minWidth: 72,
            backgroundColor: cs.surfaceContainerLow,
            indicatorColor: cs.primary.withValues(alpha: 0.1),
            selectedIconTheme: IconThemeData(
              color: cs.primary,
              size: 20,
            ),
            unselectedIconTheme: IconThemeData(
              color: cs.onSurface.withValues(alpha: 0.45),
              size: 20,
            ),
            selectedLabelTextStyle: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.45),
              fontSize: 11,
            ),
            destinations: [
              for (final p in _pestanas)
                NavigationRailDestination(
                  icon: p.construirIcono(context, badgeContenido),
                  label: Text(p.etiqueta),
                ),
            ],
          ),
          VerticalDivider(thickness: 1, width: 1, color: cs.outlineVariant),
          Expanded(
            child: _construirContenidoPestana(),
          ),
        ],
      ),
    );
  }

  Widget _buildChips(BuildContext context, int badgeContenido) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administracion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refrescar',
            onPressed: _refrescarTodo,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _pestanas.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final p = _pestanas[i];
                  final seleccionado = _indicePestana == i;
                  return FilterChip(
                    selected: seleccionado,
                    onSelected: (_) => _navegarA(i),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (p.requiereBadge && badgeContenido > 0)
                          Badge(
                            isLabelVisible: true,
                            label: Text('$badgeContenido'),
                            child: Icon(
                              seleccionado ? p.iconoActivo : p.icono,
                              size: 18,
                            ),
                          )
                        else
                          Icon(
                            seleccionado ? p.iconoActivo : p.icono,
                            size: 18,
                          ),
                        const SizedBox(width: 6),
                        Text(p.etiqueta),
                      ],
                    ),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    side: seleccionado
                        ? BorderSide(color: cs.primary.withValues(alpha: 0.3))
                        : BorderSide.none,
                    selectedColor: cs.primary.withValues(alpha: 0.1),
                    backgroundColor:
                        cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      body: _construirContenidoPestana(),
    );
  }

  Widget _construirContenidoPestana() {
    return TabBarView(
      controller: _tabController,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        AdminKpiDashboard(),
        AdminPanelScreen(),
        AdminContenidoList(),
        AdminEjercicioList(),
        AdminAuditoriaList(),
      ],
    );
  }
}

/// Descriptor inmutable de una pestana del panel de administracion.
class _PestanaAdmin {
  final int indice;
  final IconData icono;
  final IconData iconoActivo;
  final String etiqueta;
  final bool requiereBadge;

  const _PestanaAdmin({
    required this.indice,
    required this.icono,
    required this.iconoActivo,
    required this.etiqueta,
    this.requiereBadge = false,
  });

  Widget construirIcono(BuildContext context, int badge) {
    if (requiereBadge && badge > 0) {
      return Badge(
        isLabelVisible: true,
        label: Text('$badge'),
        child: Icon(icono),
      );
    }
    return Icon(icono);
  }
}
