import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/admin_auditoria_provider.dart';
import '../application/admin_contenido_provider.dart';
import '../application/admin_ejercicio_provider.dart';
import '../application/admin_metricas_provider.dart';
import '../application/admin_provider.dart';
import 'admin_panel_screen.dart';
import 'widgets/admin_auditoria_list.dart';
import 'widgets/admin_contenido_list.dart';
import 'widgets/admin_ejercicio_list.dart';
import 'widgets/admin_kpi_dashboard.dart';

/// Pantalla principal del panel de administración con pestañas.
///
/// Panel de administración con 5 pestañas: KPIs, Usuarios, Contenido, Ejercicios y Auditoría.
/// Verifica el rol de administrador al inicio y redirige al dashboard
/// si el usuario no tiene permisos.
class AdminHubScreen extends ConsumerStatefulWidget {
  const AdminHubScreen({super.key});

  @override
  ConsumerState<AdminHubScreen> createState() => _AdminHubScreenState();
}

class _AdminHubScreenState extends ConsumerState<AdminHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = ref.watch(esAdminProvider);

    return esAdmin.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error al verificar permisos'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(esAdminProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (isAdmin) {
        if (!isAdmin) {
          // Redirigir al dashboard si no es admin
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/dashboard');
            }
          });
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tienes permisos de administrador',
                    style: TextStyle(fontSize: 16),
                  ),
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

        return Scaffold(
          appBar: AppBar(
            title: const Text('Panel de Administración'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refrescar',
                onPressed: _refrescarTodo,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                const Tab(icon: Icon(Icons.dashboard), text: 'KPIs'),
                const Tab(icon: Icon(Icons.people), text: 'Usuarios'),
                Tab(
                  icon: Badge(
                    isLabelVisible: contenidoBadge > 0,
                    label: Text('$contenidoBadge'),
                    child: const Icon(Icons.flag),
                  ),
                  text: 'Contenido',
                ),
                const Tab(icon: Icon(Icons.fitness_center), text: 'Ejercicios'),
                const Tab(icon: Icon(Icons.history), text: 'Auditoría'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              AdminKpiDashboard(),
              AdminPanelScreen(),
              AdminContenidoList(),
              AdminEjercicioList(),
              AdminAuditoriaList(),
            ],
          ),
        );
      },
    );
  }
}
