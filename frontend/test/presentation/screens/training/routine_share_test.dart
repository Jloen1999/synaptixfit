import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/academic/material_sharing.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/routine.dart';
import 'package:synaptixfit/domain/models/training/routine_share.dart';
import 'package:synaptixfit/domain/repositories/routine_repository_contract.dart';
import 'package:synaptixfit/domain/repositories/share_repository_contract.dart';
import 'package:synaptixfit/domain/use_cases/training/copy_shared_routine_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_routine_share_status_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/preview_shared_routine_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/share_routine_link_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/stop_sharing_routine_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/routine_share/bloc/routine_share_bloc.dart';
import 'package:synaptixfit/presentation/screens/training/shared_routine/bloc/shared_routine_bloc.dart';

final _until = DateTime.utc(2026, 12, 15);

const _routine = Routine(
  id: 'r2',
  ownerId: 'u2',
  owned: true,
  name: 'Mi rutina',
  visibility: Visibility.private,
  status: RoutineStatus.paused,
  durationWeeks: 4,
  exerciseCount: 5,
  totalDays: 8,
  completedDays: 0,
);

const _preview = SharedRoutinePreview(
  name: 'Mi rutina',
  durationWeeks: 4,
  daysPerWeek: 2,
  exerciseCount: 5,
);

class _Status implements GetRoutineShareStatusUseCaseContract {
  _Status(this.until);

  final DateTime? until;

  @override
  Future<AppResult<DateTime?>> call(String routineId) async => Success(until);
}

class _Share implements ShareRoutineLinkUseCaseContract {
  final messages = <String>[];

  @override
  Future<AppResult<RoutineShareLink>> call(
    String routineId, {
    required String message,
  }) async {
    messages.add(message);
    return Success(
      RoutineShareLink(
        url: 'https://app/#/training/shared/t',
        expiresAt: _until,
      ),
    );
  }
}

class _Stop implements StopSharingRoutineUseCaseContract {
  int calls = 0;

  @override
  Future<AppResult<Unit>> call(String routineId) async {
    calls++;
    return const Success(unit);
  }
}

class _Preview implements PreviewSharedRoutineUseCaseContract {
  _Preview({this.gone = false});

  final bool gone;

  @override
  Future<AppResult<SharedRoutinePreview>> call(String token) async => gone
      ? const Failure(AppError.business('ROUTINE_SHARE_LINK_NOT_FOUND'))
      : const Success(_preview);
}

class _Copy implements CopySharedRoutineUseCaseContract {
  final tokens = <String>[];

  @override
  Future<AppResult<Routine>> call(String token) async {
    tokens.add(token);
    return const Success(_routine);
  }
}

/// Repositorios falsos para el caso de uso que comparte el enlace.
class _ShareRepo implements ShareRepositoryContract {
  final texts = <String>[];

  @override
  Future<AppResult<bool>> shareText({
    required String text,
    String? subject,
  }) async {
    texts.add(text);
    return const Success(true);
  }

  @override
  Future<AppResult<bool>> shareImage({
    required Uint8List png,
    required String fileName,
    required String text,
  }) async => const Success(true);

  @override
  Future<AppResult<bool>> shareFile(MaterialFile file) async =>
      const Success(true);
}

void main() {
  group('Compartir una rutina por enlace (ADR 0043)', () {
    late _Share share;
    late _Stop stop;

    blocTest<RoutineShareBloc, RoutineShareState>(
      'compartir crea el enlace y dice hasta cuándo vale',
      build: () {
        share = _Share();
        return RoutineShareBloc(
          status: _Status(null),
          share: share,
          stop: _Stop(),
        );
      },
      act: (bloc) => bloc
        ..add(const RoutineShareEvent.started('r1'))
        ..add(const RoutineShareEvent.shareRequested('Te paso mi rutina')),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.status, RoutineShareStatus.ready);
        expect(bloc.state.sharedUntil, _until);
        expect(bloc.state.busy, isFalse);
        expect(share.messages, ['Te paso mi rutina']);
      },
    );

    blocTest<RoutineShareBloc, RoutineShareState>(
      'dejar de compartir borra la fecha y avisa una vez',
      build: () {
        stop = _Stop();
        return RoutineShareBloc(
          status: _Status(_until),
          share: _Share(),
          stop: stop,
        );
      },
      seed: () => RoutineShareState(
        routineId: 'r1',
        status: RoutineShareStatus.ready,
        sharedUntil: _until,
      ),
      act: (bloc) => bloc.add(const RoutineShareEvent.stopRequested()),
      expect: () => [
        isA<RoutineShareState>().having((s) => s.busy, 'ocupado', isTrue),
        isA<RoutineShareState>()
            .having((s) => s.isShared, 'compartida', isFalse)
            .having((s) => s.stopped, 'aviso', isTrue),
        isA<RoutineShareState>().having((s) => s.stopped, 'consumido', isFalse),
      ],
      verify: (_) => expect(stop.calls, 1),
    );

    test('el caso de uso manda el mensaje con la dirección', () async {
      final repo = _ShareRepo();
      final result = await ShareRoutineLinkUseCase(
        _FakeRoutineLinks(),
        repo,
      ).call('r1', message: 'Mira');
      expect(result, isA<Success>());
      expect(repo.texts.single, 'Mira\nhttps://app/#/training/shared/t');
    });

    late _Copy copy;
    blocTest<SharedRoutineBloc, SharedRoutineState>(
      'quien abre el enlace ve el resumen y la copia con un toque',
      build: () {
        copy = _Copy();
        return SharedRoutineBloc(preview: _Preview(), copy: copy);
      },
      act: (bloc) => bloc
        ..add(const SharedRoutineEvent.started('tok'))
        ..add(const SharedRoutineEvent.copyRequested()),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.preview, _preview);
        expect(bloc.state.copied, isNull);
        expect(copy.tokens, ['tok']);
      },
    );

    blocTest<SharedRoutineBloc, SharedRoutineState>(
      'un enlace caducado deja el error para explicarlo',
      build: () =>
          SharedRoutineBloc(preview: _Preview(gone: true), copy: _Copy()),
      act: (bloc) => bloc.add(const SharedRoutineEvent.started('tok')),
      verify: (bloc) {
        expect(bloc.state.status, SharedRoutineStatus.failure);
        expect(
          bloc.state.error,
          const AppError.business('ROUTINE_SHARE_LINK_NOT_FOUND'),
        );
      },
    );
  });
}

/// Solo `createShareLink` hace falta en el caso de uso de compartir.
class _FakeRoutineLinks extends _UnusedRoutineRepository {
  @override
  Future<AppResult<RoutineShareLink>> createShareLink(String routineId) async =>
      Success(
        RoutineShareLink(
          url: 'https://app/#/training/shared/t',
          expiresAt: _until,
        ),
      );
}

/// El resto del contrato no se usa en estas pruebas.
class _UnusedRoutineRepository implements RoutineRepositoryContract {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
