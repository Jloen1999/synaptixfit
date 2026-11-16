import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/data/local_data_source/guide_progress_storage.dart';
import 'package:synaptixfit/data/repository/guide_progress_repository.dart';
import 'package:synaptixfit/domain/enums/guide_id.dart';

/// Lo guardado en el teléfono, en memoria.
class _MemoryStorage implements GuideProgressStorage {
  final values = <String, List<String>>{};

  @override
  Future<List<String>> read(String accountId) async =>
      values[accountId] ?? const [];

  @override
  Future<void> write(String accountId, List<String> guides) async =>
      values[accountId] = guides;

  @override
  Future<void> clear(String accountId) async => values.remove(accountId);
}

/// Las guías vistas se guardan por su nombre y por cuenta (ADR 0049).
void main() {
  late _MemoryStorage storage;
  late GuideProgressRepository repository;

  setUp(() {
    storage = _MemoryStorage();
    repository = GuideProgressRepository(storage);
  });

  test('apunta cada guía una sola vez y la devuelve', () async {
    await repository.markSeen('a', GuideId.liveSession);
    await repository.markSeen('a', GuideId.liveSession);
    expect(storage.values['a'], ['liveSession']);
    expect((await repository.seen('a')).valueOrNull, {GuideId.liveSession});
  });

  test('un nombre que esta versión no conoce se ignora', () async {
    storage.values['a'] = ['home', 'otraPantalla'];
    expect((await repository.seen('a')).valueOrNull, {GuideId.home});
  });

  test('olvidar las guías solo toca esa cuenta', () async {
    await repository.markSeen('a', GuideId.home);
    await repository.markSeen('b', GuideId.home);
    await repository.reset('a');
    expect((await repository.seen('a')).valueOrNull, isEmpty);
    expect((await repository.seen('b')).valueOrNull, {GuideId.home});
  });
}
