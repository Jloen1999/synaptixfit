import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/academico/presentation/academic_screen.dart';
import '../../features/academico/domain/archivo_asignatura_dto.dart';
import '../../features/academico/presentation/archivo_visor_screen.dart';
import '../../features/academico/presentation/asignatura_detalle_screen.dart';
import '../../features/academico/presentation/configuracion_academica_screen.dart';
import '../../features/academico/presentation/apuntes_screen.dart';
import '../../features/academico/presentation/plan_semanal_screen.dart';
import '../../features/academico/presentation/inbox_screen.dart';
import '../../features/academico/presentation/canvas_screen.dart';
import '../../features/academico/presentation/practica_screen.dart';
import '../../features/academico/presentation/flashcards_screen.dart';
import '../../features/academico/presentation/flashcards_results_screen.dart';
import '../../shared/models/db_models.dart';
import '../../features/analitica/presentation/analitica_screen.dart';
import '../../features/auth/presentation/acceso_screen.dart';
import '../../features/auth/presentation/onboarding_cuenta_screen.dart';
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
import '../../features/perfil/presentation/selector_asignaturas_screen.dart';
import '../../features/retos/presentation/crear_reto_screen.dart';
import '../../features/retos/presentation/detalle_reto_screen.dart';
import '../../features/retos/presentation/retos_screen.dart';
import '../../features/social/presentation/progreso_screen.dart';
import '../../features/splash/presentation/presentacion_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/pomodoro/presentation/pomodoro_screen.dart';
import '../../features/escanear/presentation/escanear_screen.dart';
import '../../features/insignias/presentation/insignias_screen.dart';
import '../../features/admin/presentation/admin_hub_screen.dart';
import '../../features/admin/presentation/admin_usuario_detalle.dart';
import 'shell_route.dart';

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}

final _authListenable = _AuthChangeNotifier();

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: _authListenable,
  redirect: (context, state) {
    final autenticado = Supabase.instance.client.auth.currentUser != null;
    final location = state.uri.toString();

    // Rutas publicas (sin autenticacion requerida)
    final esRutaPublica = location == '/' ||
        location == '/splash' ||
        location == '/acceso' ||
        location.startsWith('/onboarding');

    if (!autenticado && !esRutaPublica) return '/acceso';
    return null;
  },
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
      path: '/onboarding/academico',
      builder: (context, state) => const ConfiguracionAcademicaScreen(),
    ),
    GoRoute(
      path: '/onboarding/cuenta',
      builder: (context, state) => const OnboardingCuentaScreen(),
    ),
    GoRoute(
      path: '/onboarding/fisico',
      builder: (context, state) => const PerfilFisicoScreen(),
    ),
    GoRoute(
      path: '/onboarding/asignaturas',
      builder: (context, state) =>
          const SelectorAsignaturasScreen(esOnboarding: true),
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
            builder: (context, state) => const AcademicScreen(),
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
            path: '/progreso',
            builder: (context, state) => const ProgresoScreen(),
          ),
        ]),
      ],
    ),
    GoRoute(
      path: '/bienestar/ejercicio/:id',
      builder: (context, state) => DetalleEjercicioScreen(
        id: state.pathParameters['id'] ?? 'sin-id',
        showAddButton: !(state.extra is bool && state.extra == true),
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
      path: '/bienestar/explorador',
      builder: (context, state) => const ExploradorEjerciciosScreen(),
    ),
    GoRoute(
      path: '/bienestar/nueva-rutina',
      builder: (context, state) {
        final extra = state.extra;
        final autoRecomendar = extra is Map && extra['autoRecomendar'] == true;
        return NuevaRutinaScreen(autoRecomendar: autoRecomendar);
      },
    ),
    GoRoute(
      path: '/retos/crear',
      builder: (context, state) {
        final extra = state.extra;
        final prefilledSubjectId =
            extra is Map ? extra['prefilledSubjectId'] as String? : null;
        return CrearRetoScreen(prefilledSubjectId: prefilledSubjectId);
      },
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
    // CanvasScreen — planificador autosuficiente
    GoRoute(
      path: '/academico/planificar',
      builder: (context, state) => const CanvasScreen(),
    ),
    // InboxScreen (fallback / legacy)
    GoRoute(
      path: '/academico/planificar/inbox',
      builder: (context, state) => const InboxScreen(),
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
      path: '/academico/asignatura/:id',
      builder: (context, state) => AsignaturaDetalleScreen(
        asignaturaId: state.pathParameters['id'] ?? '',
        asignaturaInicial:
            state.extra is AsignaturaDb ? state.extra as AsignaturaDb : null,
      ),
    ),
    GoRoute(
      path: '/academico/apuntes/editor',
      builder: (context, state) => const ApuntesEditorScreen(),
    ),
    GoRoute(
      path: '/academico/archivo/visor',
      builder: (context, state) {
        final archivo = state.extra as ArchivoAsignaturaDto;
        return ArchivoVisorScreen(archivo: archivo);
      },
    ),
    GoRoute(
      path: '/academico/practica/:materialId',
      builder: (context, state) => PracticaScreen(
        materialId: state.pathParameters['materialId'] ?? '',
        sessionId: state.uri.queryParameters['sessionId'],
        modoRevision: state.uri.queryParameters['revision'] == 'true',
      ),
    ),
    GoRoute(
      path: '/academico/flashcards/:materialId',
      builder: (context, state) => FlashcardScreen(
        materialId: state.pathParameters['materialId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/academico/flashcards/:materialId/revision',
      builder: (context, state) {
        final extra = state.extra as List<int>?;
        return FlashcardScreen(
          materialId: state.pathParameters['materialId'] ?? '',
          revisionIds: extra,
        );
      },
    ),
    GoRoute(
      path: '/academico/flashcards/:materialId/resultados',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return FlashcardResultsScreen(
          materialId: state.pathParameters['materialId'] ?? '',
          dominadas: extra['dominadas'] as int,
          dudosas: extra['dudosas'] as int,
          falladas: extra['falladas'] as int,
          total: extra['total'] as int,
          falladasIds:
              (extra['falladasIds'] as List).map((e) => e as int).toList(),
          preguntas:
              (extra['preguntas'] as List).map((e) => e as PreguntaDb).toList(),
        );
      },
    ),
    GoRoute(
      path: '/notificaciones',
      builder: (context, state) => const NotificacionesScreen(),
    ),
    GoRoute(
      path: '/analitica',
      builder: (context, state) => const AnaliticaScreen(),
    ),
    GoRoute(
      path: '/perfil',
      builder: (context, state) => const PerfilScreen(),
    ),
    GoRoute(
      path: '/perfil/asignaturas/selector',
      builder: (context, state) => const SelectorAsignaturasScreen(),
    ),
    GoRoute(
      path: '/pomodoro',
      builder: (context, state) => const PomodoroScreen(),
    ),
    GoRoute(
      path: '/escanear',
      builder: (context, state) => const EscanearScreen(),
    ),
    GoRoute(
      path: '/insignias',
      builder: (context, state) => const InsigniasScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminHubScreen(),
    ),
    GoRoute(
      path: '/admin/usuario/:id',
      builder: (context, state) => AdminUsuarioDetalleScreen(
        usuarioId: state.pathParameters['id'] ?? '',
      ),
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
