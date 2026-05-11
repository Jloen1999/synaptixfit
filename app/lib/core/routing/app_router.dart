import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/academico/presentation/configuracion_academica_screen.dart';
import '../../features/academico/presentation/apuntes_screen.dart';
import '../../features/academico/presentation/gestion_asignaturas_screen.dart';
import '../../features/academico/presentation/plan_academico_screen.dart';
import '../../features/academico/presentation/plan_semanal_screen.dart';
import '../../features/academico/presentation/crear_plan_semanal_screen.dart';
import '../../features/auth/presentation/acceso_screen.dart';
import '../../features/auth/presentation/perfil_fisico_screen.dart';
import '../../features/bienestar/presentation/detalle_ejercicio_screen.dart';
import '../../features/bienestar/presentation/explorador_ejercicios_screen.dart';
import '../../features/bienestar/presentation/nueva_rutina_screen.dart';
import '../../features/bienestar/presentation/rutina_detalle_screen.dart';
import '../../features/bienestar/presentation/rutinas_comunidad_screen.dart';
import '../../features/bienestar/presentation/sesion_completada_screen.dart';
import '../../features/bienestar/presentation/sesion_en_vivo_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/notificaciones/presentation/notificaciones_screen.dart';
import '../../features/perfil/presentation/perfil_screen.dart';
import '../../features/retos/presentation/crear_reto_complejo_screen.dart';
import '../../features/retos/presentation/crear_reto_simple_screen.dart';
import '../../features/retos/presentation/detalle_reto_screen.dart';
import '../../features/retos/presentation/retos_screen.dart';
import '../../features/social/presentation/muro_social_screen.dart';
import '../../features/splash/presentation/presentacion_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'shell_route.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PresentacionScreen(),
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/acceso',
      builder: (context, state) => const AccesoScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const PerfilFisicoScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return SynaptixShellRoute(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/academico',
            builder: (context, state) => const PlanAcademicoScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/bienestar',
            builder: (context, state) => const RutinasComunidadScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/retos',
            builder: (context, state) => const RetosScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/social',
            builder: (context, state) => const MuroSocialScreen(),
          ),
        ]),
      ],
    ),
    GoRoute(
      path: '/bienestar/ejercicio/:id',
      builder: (context, state) => DetalleEjercicioScreen(
        id: state.pathParameters['id'] ?? 'sin-id',
      ),
    ),
    GoRoute(
      path: '/bienestar/sesion-completada',
      builder: (context, state) => const SesionCompletadaScreen(),
    ),
    GoRoute(
      path: '/bienestar/rutina/sesion',
      builder: (context, state) => const LiveSessionScreen(),
    ),
    GoRoute(
      path: '/bienestar/rutina/:id',
      builder: (context, state) => RutinaDetalleScreen(
        rutinaId: state.pathParameters['id'] ?? 'sin-id',
      ),
    ),
    GoRoute(
      path: '/bienestar/nueva-rutina',
      builder: (context, state) => const NuevaRutinaScreen(),
    ),
    GoRoute(
      path: '/retos/simple',
      builder: (context, state) => const CrearRetoSimpleScreen(),
    ),
    GoRoute(
      path: '/retos/complejo',
      builder: (context, state) => const CrearRetoComplejoScreen(),
    ),
    GoRoute(
      path: '/retos/:id',
      builder: (context, state) => DetalleRetoScreen(
        id: state.pathParameters['id'] ?? 'sin-id',
      ),
    ),
    GoRoute(
      path: '/plan-semanal',
      builder: (context, state) => const PlanSemanalScreen(),
    ),
    GoRoute(
      path: '/plan-semanal/crear',
      builder: (context, state) => const CrearPlanSemanalScreen(),
    ),
    GoRoute(
      path: '/academico/asignaturas',
      builder: (context, state) => const GestionAsignaturasScreen(),
    ),
    GoRoute(
      path: '/academico/apuntes',
      builder: (context, state) => const ApuntesScreen(),
    ),
    GoRoute(
      path: '/academico/configuracion',
      builder: (context, state) => const ConfiguracionAcademicaScreen(),
    ),
    GoRoute(
      path: '/academico/apuntes/editor',
      builder: (context, state) => const ApuntesEditorScreen(),
    ),
    GoRoute(
      path: '/notificaciones',
      builder: (context, state) => const NotificacionesScreen(),
    ),
    GoRoute(
      path: '/perfil',
      builder: (context, state) => const PerfilScreen(),
    ),
  ],
  errorBuilder: (context, state) {
    return Scaffold(
      body: Center(
        child: Text('Ruta no encontrada: ${state.uri.path}'),
      ),
    );
  },
);
