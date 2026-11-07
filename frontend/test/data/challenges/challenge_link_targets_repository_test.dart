import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/data/remote_data_source/challenges/challenge_references_remote_data_source.dart';
import 'package:synaptixfit/data/repository/challenge_references_repository.dart';
import 'package:synaptixfit/domain/enums/challenge_link_type.dart';
import 'package:synaptixfit/domain/models/challenges/challenge_references.dart';
import 'package:synaptixfit/domain/models/result/result.dart';

class _Remote extends Mock implements ChallengeReferencesRemoteDataSource {}

/// El selector de vínculos ofrece las entregas y los días de rutina como dos
/// listas independientes: si una no carga, la otra sigue disponible.
void main() {
  late _Remote remote;
  final from = DateTime(2026, 11, 1);
  final to = DateTime(2026, 11, 30);
  const day = ChallengeLinkOption(
    id: 'd1',
    type: ChallengeLinkType.routineDay,
    title: 'Fuerza',
    weekNumber: 1,
    dayNumber: 1,
  );

  setUp(() => remote = _Remote());

  DioException offline() => DioException(
    requestOptions: RequestOptions(path: '/'),
    type: DioExceptionType.connectionError,
  );

  test('si fallan las entregas, siguen los días de rutina', () async {
    when(
      () => remote.deadlinesBetween(any(), from: from, to: to),
    ).thenThrow(offline());
    when(remote.routineDayTargets).thenAnswer((_) async => [day]);

    final result = await ChallengeReferencesRepository(
      remote,
    ).linkTargets(from: from, to: to);

    expect(result.valueOrNull, [day]);
  });

  test('si fallan las dos, se avisa del error', () async {
    when(
      () => remote.deadlinesBetween(any(), from: from, to: to),
    ).thenThrow(offline());
    when(remote.routineDayTargets).thenThrow(offline());

    final result = await ChallengeReferencesRepository(
      remote,
    ).linkTargets(from: from, to: to);

    expect(result, isA<Failure<List<ChallengeLinkOption>, Object>>());
  });
}
