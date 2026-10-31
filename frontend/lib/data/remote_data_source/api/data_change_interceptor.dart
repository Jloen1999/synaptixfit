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
  static const _ignored = [
    '/api/v1/auth/',
    '/api/v1/badges/evaluate',
    '/api/v1/badges/notified',
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
    // Antes que /profile: aplicar la matrícula crea asignaturas (leerla no
    // cambia nada).
    '/api/v1/profile/enrollment/read': {},
    '/api/v1/profile/enrollment/apply': {
      DataTopic.profile,
      DataTopic.academic,
      DataTopic.planner,
    },
    '/api/v1/profile': {DataTopic.profile, DataTopic.training},
    '/api/v1/me': {
      DataTopic.profile,
      DataTopic.training,
      DataTopic.academic,
      DataTopic.challenges,
      DataTopic.planner,
    },
    '/api/v1/social': {DataTopic.social},
    '/api/v1/notifications': {DataTopic.social},
  };

  /// Áreas que cambia una petición, o vacío si no cambia ninguna.
  static Set<DataTopic> topicsFor(String method, String path) {
    if (!_mutating.contains(method.toUpperCase())) return const {};
    if (_ignored.any(path.startsWith)) return const {};
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
