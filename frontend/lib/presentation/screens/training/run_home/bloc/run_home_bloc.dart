import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/data_topic.dart';
import '../../../../../domain/enums/device_permission.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/run.dart';
import '../../../../../domain/models/training/sport_activity.dart';
import '../../../../../domain/use_cases/profile/get_device_permission_status_use_case.dart';
import '../../../../../domain/use_cases/progress/share_achievement_image_use_case.dart';
import '../../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';
import '../../../../../domain/use_cases/training/delete_run_workout_use_case.dart';
import '../../../../../domain/use_cases/training/get_current_position_use_case.dart';
import '../../../../../domain/use_cases/training/get_run_week_use_case.dart';
import '../../../../../domain/use_cases/training/list_pending_runs_use_case.dart';
import '../../../../../domain/use_cases/training/list_planned_runs_use_case.dart';
import '../../../../../domain/use_cases/training/list_run_workout_templates_use_case.dart';
import '../../../../../domain/use_cases/training/list_run_workouts_use_case.dart';
import '../../../../../domain/use_cases/training/list_sport_activities_use_case.dart';
import '../../../../../domain/use_cases/training/load_run_recording_use_case.dart';
import '../../../../../domain/use_cases/training/schedule_run_workout_use_case.dart';
import '../../../../../domain/use_cases/training/track_run_use_case.dart';
import '../../../../../domain/use_cases/training/upload_pending_runs_use_case.dart';
import '../../../../mixins/data_change_refresh_mixin.dart';

part 'run_home_bloc.freezed.dart';
part 'run_home_event.dart';
part 'run_home_state.dart';

/// Apartado «Correr» de Entreno (ADR 0037): sube primero las carreras que
/// esperaban conexión y carga «Esta semana», «Tus actividades», «Tus entrenos
/// de carrera», lo que hay en el calendario y la carrera sin terminar. Pide la
/// posición para «Estás aquí» solo si el permiso ya está dado: el permiso se
/// pide justo antes de la primera carrera, nunca al entrar.
class RunHomeBloc extends Bloc<RunHomeEvent, RunHomeState>
    with DataChangeRefreshMixin {
  RunHomeBloc({
    required this._uploadPending,
    required this._getWeek,
    required this._listActivities,
    required this._listWorkouts,
    required this._listTemplates,
    required this._listPlanned,
    required this._listPending,
    required this._loadRecording,
    required this._deleteWorkout,
    required this._scheduleWorkout,
    required this._permissionStatus,
    required this._position,
    required this._track,
    required this._share,
    required this._watchDataChanges,
  }) : super(const RunHomeState()) {
    on<RunHomeStarted>((_, emit) async {
      watchDataChanges(
        _watchDataChanges,
        topics: const {DataTopic.training, DataTopic.planner},
        onChanged: const RunHomeEvent.refreshed(),
      );
      emit(
        state.copyWith(
          status: RunHomeStatus.loading,
          supported: _track.supported,
        ),
      );
      await _load(emit);
      await _locate(emit);
    });
    on<RunHomeRefreshed>((_, emit) => _load(emit));
    on<RunHomeWorkoutDeleted>((e, emit) async {
      final result = await _deleteWorkout(e.workoutId);
      switch (result) {
        case Success():
          emit(
            state.copyWith(
              workouts: [
                for (final w in state.workouts)
                  if (w.id != e.workoutId) w,
              ],
            ),
          );
        case Failure(:final error):
          _notify(emit, error: error);
      }
    });
    on<RunHomeWorkoutScheduled>((e, emit) async {
      final result = await _scheduleWorkout(e.workoutId, e.start);
      switch (result) {
        case Success():
          _notify(emit, notice: RunHomeNotice.scheduled);
          await _load(emit);
        case Failure(:final error):
          _notify(emit, error: error);
      }
    });
    on<RunHomeShared>((e, emit) async {
      final result = await _share(
        png: e.png,
        fileName: 'synaptixfit-semana.png',
        text: e.text,
      );
      if (result case Failure(:final error)) _notify(emit, error: error);
    });
  }

  final UploadPendingRunsUseCaseContract _uploadPending;
  final GetRunWeekUseCaseContract _getWeek;
  final ListSportActivitiesUseCaseContract _listActivities;
  final ListRunWorkoutsUseCaseContract _listWorkouts;
  final ListRunWorkoutTemplatesUseCaseContract _listTemplates;
  final ListPlannedRunsUseCaseContract _listPlanned;
  final ListPendingRunsUseCaseContract _listPending;
  final LoadRunRecordingUseCaseContract _loadRecording;
  final DeleteRunWorkoutUseCaseContract _deleteWorkout;
  final ScheduleRunWorkoutUseCaseContract _scheduleWorkout;
  final GetDevicePermissionStatusUseCaseContract _permissionStatus;
  final GetCurrentPositionUseCaseContract _position;
  final TrackRunUseCaseContract _track;
  final ShareAchievementImageUseCaseContract _share;
  final WatchDataChangesUseCaseContract _watchDataChanges;

  /// «Tus actividades» enseña las últimas; el resto, en «Ver todas».
  static const recentActivities = 3;

  Future<void> _load(Emitter<RunHomeState> emit) async {
    // Lo que quedó sin subir va primero: así sale ya en la semana.
    final uploaded = await _uploadPending();
    final (
      week,
      activities,
      workouts,
      templates,
      planned,
      pending,
      current,
    ) = await (
      _getWeek(),
      _listActivities(page: 0, size: recentActivities),
      _listWorkouts(),
      _listTemplates(),
      _listPlanned(),
      _listPending(),
      _loadRecording(),
    ).wait;
    if (week.errorOrNull case final error? when state.week == null) {
      emit(state.copyWith(status: RunHomeStatus.failure, error: error));
      return;
    }
    emit(
      state.copyWith(
        status: RunHomeStatus.ready,
        error: null,
        week: week.valueOrNull ?? state.week,
        activities: activities.valueOrNull?.items ?? state.activities,
        totalActivities:
            activities.valueOrNull?.totalItems ?? state.totalActivities,
        workouts: workouts.valueOrNull ?? state.workouts,
        templates: templates.valueOrNull ?? state.templates,
        planned: planned.valueOrNull ?? state.planned,
        pendingUploads: pending.valueOrNull?.length ?? 0,
        unfinished: current.valueOrNull,
      ),
    );
    if ((uploaded.valueOrNull ?? const <RunSaved>[]).isNotEmpty) {
      _notify(emit, notice: RunHomeNotice.uploaded);
    }
  }

  /// «Estás aquí» solo con el permiso ya concedido (no se pide al entrar).
  Future<void> _locate(Emitter<RunHomeState> emit) async {
    if (!_track.supported) return;
    final status = (await _permissionStatus(
      DevicePermission.location,
    )).valueOrNull;
    if (status != DevicePermissionStatus.granted) return;
    final fix = (await _position()).valueOrNull;
    if (fix != null) {
      emit(state.copyWith(here: (fix.latitude, fix.longitude)));
    }
  }

  void _notify(
    Emitter<RunHomeState> emit, {
    RunHomeNotice? notice,
    AppError? error,
  }) {
    emit(state.copyWith(notice: notice, actionError: error));
    emit(state.copyWith(notice: null, actionError: null));
  }
}
