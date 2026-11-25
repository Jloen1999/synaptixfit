import 'dart:async';

import 'package:dio/dio.dart';

import '../../../domain/enums/data_topic.dart';

/// Detecta en las respuestas correctas de la API las peticiones que cambian
/// datos (POST, PUT, PATCH, DELETE) y emite qué [DataTopic] tocaron.
///
/// Se hace aquí, y no en cada repositorio, para que ninguna acción nueva se
/// olvide de avisar: basta con que su ruta empiece por un prefijo conocido.
class DataChangeInterceptor extends Interceptor {
  DataChangeInterceptor({this.debounce = const Duration(milliseconds: 350)});

  /// Agrupa ráfagas (p. ej. guardar y después completar) en un solo aviso.
  final Duration debounce;

  final _controller = StreamController<Set<DataTopic>>.broadcast();
  final _pending = <DataTopic>{};
  Timer? _timer;

  Stream<Set<DataTopic>> get changes => _controller.stream;

  static const _mutating = {'POST', 'PUT', 'PATCH', 'DELETE'};

  /// Peticiones que no cambian nada que otra pantalla muestre. Marcar
  /// insignias como celebradas se excluye además para no crear un bucle (el
  /// armazón lo hace al refrescarse); `/badges/evaluate` ya no lo llama el
  /// cliente, pero sigue excluido por seguridad.
  /// Acciones de solo lectura que van por POST y llevan un id en medio de la
  /// ruta: se reconocen por el final. Leer las preguntas que ya trae un
  /// apunte llama a la IA pero no guarda nada (ADR 0058).
  static const _ignoredEndings = ['/document-questions'];

  /// Acciones con un id en medio de la ruta que tocan más que su prefijo:
  /// publicar un apunte en el muro (ADR 0064) también cambia lo social.
  static const _endings = <String, Set<DataTopic>>{
    '/wall': {DataTopic.academic, DataTopic.social},
  };

  static const _ignored = [
    '/api/v1/auth/',
    '/api/v1/badges/evaluate',
    '/api/v1/badges/notified',
    // Aceptar la política (ADR 0034) no cambia nada que se vea.
    '/api/v1/me/legal-acceptance',
    // Ver una rutina compartida es un POST (el token va en el cuerpo, ADR
    // 0043), pero no cambia nada.
    '/api/v1/shared-routines/preview',
  ];

  /// Prefijo de ruta → áreas afectadas. Casi toda acción puede dar XP o
  /// mover un reto, por eso estudio, entrenamiento y planificador incluyen
  /// [DataTopic.gamification] y [DataTopic.challenges]. Entrenar también
  /// publica en el feed y notifica ([DataTopic.social]); cambiar la privacidad
  /// en `/me` privatiza en el servidor rutinas, retos, apuntes y planes.
  static const _routes = <String, Set<DataTopic>>{
    '/api/v1/training': {
      DataTopic.training,
      DataTopic.planner,
      DataTopic.challenges,
      DataTopic.gamification,
      DataTopic.social,
    },
    '/api/v1/routines': {DataTopic.training, DataTopic.planner},
    // Copiar una rutina desde un enlace (ADR 0043).
    '/api/v1/shared-routines': {DataTopic.training, DataTopic.planner},
    '/api/v1/planner': {
      DataTopic.planner,
      DataTopic.academic,
      DataTopic.challenges,
      DataTopic.gamification,
    },
    '/api/v1/study-materials': {
      DataTopic.academic,
      DataTopic.planner,
      DataTopic.challenges,
      DataTopic.gamification,
    },
    '/api/v1/test-sessions': {
      DataTopic.academic,
      DataTopic.challenges,
      DataTopic.gamification,
    },
    '/api/v1/question-banks': {DataTopic.academic, DataTopic.gamification},
    '/api/v1/questions': {DataTopic.academic},
    '/api/v1/subjects': {
      DataTopic.academic,
      DataTopic.planner,
      DataTopic.challenges,
    },
    '/api/v1/notes': {DataTopic.academic},
    '/api/v1/teaching-guide-imports': {DataTopic.academic, DataTopic.planner},
    '/api/v1/files': {DataTopic.academic},
    '/api/v1/study': {DataTopic.academic},
    '/api/v1/challenges': {
      DataTopic.challenges,
      DataTopic.planner,
      DataTopic.gamification,
      DataTopic.social,
    },
    '/api/v1/badges': {DataTopic.gamification, DataTopic.social},
    // Pausar o reanudar la racha: Progreso y el aviso de racha en peligro.
    '/api/v1/streak': {DataTopic.gamification, DataTopic.social},
    // Antes que /profile: aplicar la matrícula crea asignaturas (leerla no
    // cambia nada).
    '/api/v1/profile/enrollment/read': {},
    '/api/v1/profile/enrollment/apply': {
      DataTopic.profile,
      DataTopic.academic,
      DataTopic.planner,
    },
    '/api/v1/profile': {DataTopic.profile, DataTopic.training},
    // La foto de perfil (ADR 0052) solo se ve en el perfil y en lo social;
    // antes que `/me`, que refresca mucho más (privacidad).
    '/api/v1/me/avatar': {DataTopic.profile, DataTopic.social},
    '/api/v1/me': {
      DataTopic.profile,
      DataTopic.training,
      DataTopic.academic,
      DataTopic.challenges,
      DataTopic.planner,
    },
    '/api/v1/social': {DataTopic.social},
    // Estudiamos juntos (ADR 0045), antes que /together: entrar o salir de la
    // sala apunta las rondas terminadas como Pomodoros (racha, retos, XP).
    '/api/v1/together/study-rooms': {
      DataTopic.social,
      DataTopic.planner,
      DataTopic.challenges,
      DataTopic.gamification,
    },
    // Con amigos (ADR 0044): empezar a entrenar juntos crea una sesión y puede
    // copiar la rutina.
    '/api/v1/together': {DataTopic.social, DataTopic.training},
    '/api/v1/notifications': {DataTopic.social},
  };

  /// Cambios que no hizo esta app (el canal en directo, ADR 0047): se agrupan
  /// con los propios para no refrescar dos veces seguidas.
  void publish(Set<DataTopic> topics) {
    if (topics.isEmpty) return;
    _pending.addAll(topics);
    _timer?.cancel();
    _timer = Timer(debounce, _flush);
  }

  /// Áreas que cambia una petición, o vacío si no cambia ninguna.
  static Set<DataTopic> topicsFor(String method, String path) {
    if (!_mutating.contains(method.toUpperCase())) return const {};
    if (_ignored.any(path.startsWith) || _ignoredEndings.any(path.endsWith)) {
      return const {};
    }
    for (final MapEntry(key: ending, value: topics) in _endings.entries) {
      if (path.startsWith('/api/v1/notes/') && path.endsWith(ending)) {
        return topics;
      }
    }
    for (final MapEntry(key: prefix, value: topics) in _routes.entries) {
      if (path == prefix || path.startsWith('$prefix/')) return topics;
    }
    return const {};
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    final topics = topicsFor(options.method, options.uri.path);
    if (topics.isNotEmpty) {
      _pending.addAll(topics);
      _timer?.cancel();
      _timer = Timer(debounce, _flush);
    }
    handler.next(response);
  }

  void _flush() {
    if (_pending.isEmpty) return;
    _controller.add(Set.unmodifiable(_pending));
    _pending.clear();
  }
}
