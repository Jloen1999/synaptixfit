import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/remote_data_source/api/data_change_interceptor.dart';
import 'package:synaptixfit/data/remote_data_source/api/sse_parser.dart';
import 'package:synaptixfit/data/remote_data_source/social/live/together_live_remote_data_source.dart';
import 'package:synaptixfit/data/repository/together_live_repository.dart';
import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/social/together_live.dart';

class _Remote implements TogetherLiveRemoteDataSource {
  _Remote(this.events);

  final StreamController<SseEvent> events;

  @override
  Stream<SseEvent> open() => events.stream;
}

/// Canal en directo de «Con amigos» en la capa data (ADR 0047).
void main() {
  group('SSE', () {
    Future<List<SseEvent>> parse(List<String> chunks) =>
        Stream<List<int>>.fromIterable([
          for (final c in chunks) utf8.encode(c),
        ]).transform(sseTransformer()).toList();

    test('mensajes con nombre, datos en varias líneas y a trozos', () async {
      final events = await parse([
        'event:ready\ndata:{}\n\n',
        ': ping\n\n',
        'event: change\r\nda',
        'ta: {"type":"workout",\ndata: "id":"w1"}\n\n',
      ]);
      expect(events.map((e) => e.event), ['ready', 'change']);
      expect(events.last.data, '{"type":"workout",\n"id":"w1"}');
    });

    test('el latido (comentario) no es un mensaje', () async {
      expect(await parse([': ping\n\n', ': ping\n\n']), isEmpty);
    });
  });

  group('TogetherLiveRepository', () {
    test('traduce «ready» y «change», ignora lo que no entiende y sabe si '
        'está conectado', () async {
      final events = StreamController<SseEvent>();
      final repo = TogetherLiveRepository(_Remote(events));
      final got = <TogetherLiveSignal>[];
      final sub = repo.watch().listen((r) {
        if (r case Success(:final value)) got.add(value);
      });
      expect(repo.connected, isFalse);

      events
        ..add(const SseEvent('ready', '{}'))
        ..add(const SseEvent('change', '{"type":"studyRoom","id":"r1"}'))
        ..add(const SseEvent('change', '{"type":"chat","id":"x"}'))
        ..add(const SseEvent('otro', '{}'));
      await Future<void>.delayed(Duration.zero);

      expect(got, const [
        TogetherLiveSignal(TogetherLiveTopic.connected),
        TogetherLiveSignal(TogetherLiveTopic.studyRoom, 'r1'),
      ]);
      expect(repo.connected, isTrue);
      await sub.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(repo.connected, isFalse);
    });

    test('un corte llega como fallo y deja de estar conectado', () async {
      final events = StreamController<SseEvent>();
      final repo = TogetherLiveRepository(_Remote(events));
      final results = <Object>[];
      final done = Completer<void>();
      repo.watch().listen(results.add, onDone: done.complete);
      events.add(const SseEvent('ready', '{}'));
      await Future<void>.delayed(Duration.zero);
      events.addError(const FormatException('cortado'));
      await events.close();
      await done.future;
      expect(results.last, isA<Failure>());
      expect(repo.connected, isFalse);
    });
  });

  test(
    'el interceptor publica cambios que llegan de fuera, agrupados',
    () async {
      final interceptor = DataChangeInterceptor(debounce: Duration.zero);
      final got = <Set<DataTopic>>[];
      final sub = interceptor.changes.listen(got.add);
      interceptor
        ..publish({DataTopic.studyRoom})
        ..publish({DataTopic.social});
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(got, [
        {DataTopic.studyRoom, DataTopic.social},
      ]);
      await sub.cancel();
    },
  );

  test('cada aviso dice qué pantallas leen otra vez', () {
    expect(
      const TogetherLiveSignal(TogetherLiveTopic.workout, 'w1').dataTopics,
      {DataTopic.workoutTogether},
    );
    expect(
      const TogetherLiveSignal(TogetherLiveTopic.connected).dataTopics,
      isEmpty,
    );
  });
}
