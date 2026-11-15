import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../../domain/enums/together_enums.dart';
import '../../../../../../domain/errors/app_error.dart';
import '../../../../../../domain/models/planner/planner_options.dart';
import '../../../../../../domain/models/result/app_result.dart';
import '../../../../../../domain/models/result/result.dart';
import '../../../../../../domain/models/social/together.dart';
import '../../../../../../domain/use_cases/planner/get_planner_subjects_use_case.dart';
import '../../../../../../domain/use_cases/social/together/choose_study_room_subject_use_case.dart';
import '../../../../../../domain/use_cases/social/together/decline_study_room_use_case.dart';
import '../../../../../../domain/use_cases/social/together/get_study_room_use_case.dart';
import '../../../../../../domain/use_cases/social/together/join_study_room_use_case.dart';
import '../../../../../../domain/use_cases/social/together/leave_study_room_use_case.dart';
import '../../../../../../domain/use_cases/social/together/react_in_study_room_use_case.dart';
import '../../../../../../domain/use_cases/social/together/start_study_room_use_case.dart';
import '../../../../../mixins/deferred_commit_mixin.dart';

part 'study_room_bloc.freezed.dart';
part 'study_room_event.dart';
part 'study_room_state.dart';

/// Sala de «Estudiamos juntos» (ADR 0045). Mientras la pantalla está abierta
/// vuelve a leer cada [pollInterval] (sin WebSocket) y guarda la diferencia
/// entre el reloj del servidor y el del móvil ([StudyRoomState.clockOffset])
/// para que la cuenta atrás sea la misma en todos los móviles. La fase la
/// decide el servidor: al acabar la cuenta atrás la pantalla pide leer otra vez.
/// Salir se aplaza hasta que se cierra su aviso con «Deshacer»
/// ([DeferredCommitMixin]): deshacer no toca el servidor y no se pierden los
/// minutos de la ronda en curso.
class StudyRoomBloc extends Bloc<StudyRoomEvent, StudyRoomState>
    with DeferredCommitMixin<StudyRoomState> {
  StudyRoomBloc({
    required this._get,
    required this._join,
    required this._decline,
    required this._leave,
    required this._start,
    required this._chooseSubject,
    required this._react,
    required this._subjects,
    this.pollInterval = const Duration(seconds: 12),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const StudyRoomState()) {
    on<StudyRoomStarted>(_onStarted);
    on<StudyRoomPolled>(_onPolled);
    on<StudyRoomJoined>(_onJoined);
    on<StudyRoomDeclined>(_onDeclined);
    on<StudyRoomLeft>(_onLeft);
    on<StudyRoomLeaveUndone>(_onLeaveUndone);
    on<StudyRoomLeaveCommitted>(_onLeaveCommitted);
    on<StudyRoomStartRequested>(_onStart);
    on<StudyRoomSubjectChosen>(_onSubject);
    on<StudyRoomReacted>(_onReacted);
  }

  final GetStudyRoomUseCaseContract _get;
  final JoinStudyRoomUseCaseContract _join;
  final DeclineStudyRoomUseCaseContract _decline;
  final LeaveStudyRoomUseCaseContract _leave;
  final StartStudyRoomUseCaseContract _start;
  final ChooseStudyRoomSubjectUseCaseContract _chooseSubject;
  final ReactInStudyRoomUseCaseContract _react;
  final GetPlannerSubjectsUseCaseContract _subjects;
  final Duration pollInterval;
  final DateTime Function() _now;
  Timer? _timer;

  String get _id => state.id!;

  static const _leaveKey = 'leave';

  /// Ya no se está en la sala (salió, la bloquearon o se borró): no hay nada
  /// que reintentar ni que consultar.
  static bool _gone(AppError error) =>
      error == const AppError.business('STUDY_ROOM_NOT_FOUND');

  /// Estado con la sala recién leída y el desfase de reloj de esa lectura.
  StudyRoomState _with(StudyRoom room) => state.copyWith(
    status: StudyRoomStatus.ready,
    room: room,
    clockOffset: room.serverTime.difference(_now()),
  );

  Future<void> _onStarted(
    StudyRoomStarted event,
    Emitter<StudyRoomState> emit,
  ) async {
    emit(
      state.copyWith(
        id: event.id,
        status: StudyRoomStatus.loading,
        error: null,
      ),
    );
    final result = await _get(event.id);
    emit(switch (result) {
      Success(:final value) => _with(value),
      Failure(:final error) => state.copyWith(
        status: StudyRoomStatus.failure,
        error: error,
      ),
    });
    _poll();
    // Las asignaturas son solo para mi selector: si fallan, se elige «Ninguna».
    final subjects = (await _subjects()).valueOrNull;
    if (subjects != null) emit(state.copyWith(subjects: subjects));
  }

  void _poll() {
    _timer?.cancel();
    _timer = Timer.periodic(
      pollInterval,
      (_) => add(const StudyRoomEvent.polled()),
    );
  }

  /// Lectura silenciosa: un fallo de red no cambia lo que se ve. Con la sala
  /// terminada, o si ya no se está dentro, deja de preguntar.
  Future<void> _onPolled(
    StudyRoomPolled event,
    Emitter<StudyRoomState> emit,
  ) async {
    if (state.id == null || state.busy) return;
    final result = await _get(_id);
    switch (result) {
      case Success(:final value):
        emit(_with(value));
        if (value.phase.over) _timer?.cancel();
      case Failure(:final error) when _gone(error):
        _timer?.cancel();
        emit(state.copyWith(status: StudyRoomStatus.failure, error: error));
      case Failure():
        break;
    }
  }

  Future<void> _run(
    Emitter<StudyRoomState> emit,
    Future<AppResult<StudyRoom>> Function() action,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await action();
    emit(switch (result) {
      Success(:final value) => _with(value).copyWith(busy: false),
      Failure(:final error) => state.copyWith(busy: false, actionError: error),
    });
    emit(state.copyWith(actionError: null));
  }

  Future<void> _onJoined(StudyRoomJoined event, Emitter<StudyRoomState> emit) =>
      _run(emit, () => _join(_id));

  Future<void> _onStart(
    StudyRoomStartRequested event,
    Emitter<StudyRoomState> emit,
  ) => _run(emit, () => _start(_id));

  Future<void> _onSubject(
    StudyRoomSubjectChosen event,
    Emitter<StudyRoomState> emit,
  ) => _run(emit, () => _chooseSubject(_id, subjectId: event.subjectId));

  Future<void> _onReacted(
    StudyRoomReacted event,
    Emitter<StudyRoomState> emit,
  ) => _run(emit, () => _react(_id, reaction: event.reaction));

  Future<void> _onDeclined(
    StudyRoomDeclined event,
    Emitter<StudyRoomState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _decline(_id);
    emit(switch (result) {
      Success() => state.copyWith(busy: false, closed: true),
      Failure(:final error) => state.copyWith(busy: false, actionError: error),
    });
    emit(state.copyWith(actionError: null));
  }

  /// Salir no pregunta: se aplaza y la pantalla avisa con «Deshacer».
  void _onLeft(StudyRoomLeft event, Emitter<StudyRoomState> emit) {
    if (state.busy || !(state.room?.joined ?? false) || !defer(_leaveKey)) {
      return;
    }
    emit(state.copyWith(leaving: true, left: true));
    emit(state.copyWith(left: false));
  }

  void _onLeaveUndone(
    StudyRoomLeaveUndone event,
    Emitter<StudyRoomState> emit,
  ) {
    if (release(_leaveKey)) emit(state.copyWith(leaving: false));
  }

  Future<void> _onLeaveCommitted(
    StudyRoomLeaveCommitted event,
    Emitter<StudyRoomState> emit,
  ) async {
    if (release(_leaveKey)) await commitDeferred(_leaveKey);
  }

  /// Sale de verdad. Fuera de la sala ya no hay nada que consultar.
  @override
  Future<void> commitDeferred(String id) async {
    _timer?.cancel();
    await _leave(_id);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
