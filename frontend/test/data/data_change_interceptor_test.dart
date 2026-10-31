import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/api/data_change_interceptor.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';

void main() {
  group('topicsFor', () {
    test('terminar una sesión avisa a retos, logros y social (feed)', () {
      expect(
        DataChangeInterceptor.topicsFor(
          'POST',
          '/api/v1/training/sessions/s1/finish',
        ),
        containsAll([
          DataTopic.training,
          DataTopic.challenges,
          DataTopic.gamification,
          DataTopic.social,
        ]),
      );
    });

    test('aplicar la matrícula refresca estudios; leerla no cambia nada', () {
      expect(
        DataChangeInterceptor.topicsFor(
          'POST',
          '/api/v1/profile/enrollment/apply',
        ),
        containsAll([DataTopic.academic, DataTopic.planner]),
      );
      expect(
        DataChangeInterceptor.topicsFor(
          'POST',
          '/api/v1/profile/enrollment/read',
        ),
        isEmpty,
      );
    });

    test('cambiar la privacidad en /me avisa a lo que se privatiza', () {
      expect(DataChangeInterceptor.topicsFor('PATCH', '/api/v1/me'), {
        DataTopic.profile,
        DataTopic.training,
        DataTopic.academic,
        DataTopic.challenges,
        DataTopic.planner,
      });
    });

    test('completar un bloque del planificador avisa a estudio y retos', () {
      expect(
        DataChangeInterceptor.topicsFor(
          'PUT',
          '/api/v1/planner/blocks/b1/completion',
        ),
        containsAll([
          DataTopic.planner,
          DataTopic.academic,
          DataTopic.challenges,
        ]),
      );
    });

    test('aplicar un plan docente refresca Académico y el planificador', () {
      expect(
        DataChangeInterceptor.topicsFor(
          'POST',
          '/api/v1/teaching-guide-imports/i1/apply',
        ),
        {DataTopic.academic, DataTopic.planner},
      );
    });

    test('las lecturas no avisan', () {
      expect(
        DataChangeInterceptor.topicsFor('GET', '/api/v1/training'),
        isEmpty,
      );
    });

    test('evaluar o marcar insignias no avisa (evita bucles)', () {
      expect(
        DataChangeInterceptor.topicsFor('POST', '/api/v1/badges/evaluate'),
        isEmpty,
      );
      expect(
        DataChangeInterceptor.topicsFor('POST', '/api/v1/badges/notified'),
        isEmpty,
      );
    });

    test('el login no avisa y un prefijo parecido no confunde', () {
      expect(
        DataChangeInterceptor.topicsFor('POST', '/api/v1/auth/login'),
        isEmpty,
      );
      expect(
        DataChangeInterceptor.topicsFor('POST', '/api/v1/studyx'),
        isEmpty,
      );
    });
  });

  test('agrupa una ráfaga de cambios en un solo aviso', () async {
    final interceptor = DataChangeInterceptor(debounce: Duration.zero);
    final emitted = <Set<DataTopic>>[];
    final sub = interceptor.changes.listen(emitted.add);
    for (final path in ['/api/v1/notes/n1', '/api/v1/challenges/c1']) {
      interceptor.onResponse(
        Response<void>(
          requestOptions: RequestOptions(path: path, method: 'DELETE'),
          statusCode: 204,
        ),
        ResponseInterceptorHandler(),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await sub.cancel();
    expect(emitted, hasLength(1));
    expect(
      emitted.single,
      containsAll([DataTopic.academic, DataTopic.challenges]),
    );
  });
}
