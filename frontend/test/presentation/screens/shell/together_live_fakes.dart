import 'dart:async';

import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/enums/together_enums.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/social/together.dart';
import 'package:synaptixfit/domain/models/social/together_live.dart';
import 'package:synaptixfit/domain/use_cases/social/together/get_together_overview_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together/get_workout_together_use_case.dart';
import 'package:synaptixfit/domain/use_cases/social/together_live/watch_together_live_use_case.dart';
import 'package:synaptixfit/domain/use_cases/sync/publish_data_changes_use_case.dart';
import 'package:synaptixfit/presentation/screens/shell/bloc/together_live_bloc.dart';

/// Dobles del canal en directo de «Con amigos» (ADR 0047) para los tests del
/// bloc y del host.
const ana = TogetherPerson(id: 'ana', name: 'Ana');
const me = TogetherPerson(id: 'me', name: 'Yo');

/// Entreno juntos de hoy con Ana y conmigo dentro.
WorkoutTogether workout({
  DateTime? startedAt,
  TogetherPerson? startedBy,
  DateTime? pausedAt,
  String? mySessionId = 's-me',
  WorkoutMemberState myState = WorkoutMemberState.training,
}) => WorkoutTogether(
  id: 'w1',
  host: ana,
  date: DateTime(2026, 11, 16),
  today: true,
  myStatus: TogetherMemberStatus.joined,
  mySessionId: mySessionId,
  startedAt: startedAt,
  startedBy: startedBy,
  pausedAt: pausedAt,
  members: [
    const WorkoutTogetherMember(
      person: ana,
      status: TogetherMemberStatus.joined,
      state: WorkoutMemberState.training,
    ),
    WorkoutTogetherMember(
      person: me,
      status: TogetherMemberStatus.joined,
      state: myState,
      me: true,
    ),
  ],
);

/// Cada escucha abre un «canal» que el test controla.
class FakeWatchLive implements WatchTogetherLiveUseCaseContract {
  final channels = <StreamController<AppResult<TogetherLiveSignal>>>[];

  StreamController<AppResult<TogetherLiveSignal>> get last => channels.last;

  /// Canales abiertos ahora mismo (con alguien escuchando).
  int get open => channels.where((c) => c.hasListener && !c.isClosed).length;

  @override
  Stream<AppResult<TogetherLiveSignal>> call() {
    final c = StreamController<AppResult<TogetherLiveSignal>>();
    channels.add(c);
    return c.stream;
  }

  void signal(TogetherLiveTopic topic, [String? id]) =>
      last.add(Success(TogetherLiveSignal(topic, id)));

  void drop() => last.add(const Failure(AppError.network()));
}

class FakePublish implements PublishDataChangesUseCaseContract {
  final published = <Set<DataTopic>>[];

  @override
  void call(Set<DataTopic> topics) {
    if (topics.isNotEmpty) published.add(topics);
  }
}

class FakeGetWorkout implements GetWorkoutTogetherUseCaseContract {
  FakeGetWorkout(this.current);

  WorkoutTogether current;

  @override
  Future<AppResult<WorkoutTogether>> call(String id) async => Success(current);
}

class FakeOverview implements GetTogetherOverviewUseCaseContract {
  FakeOverview([this.value = const TogetherOverview()]);

  TogetherOverview value;

  @override
  Future<AppResult<TogetherOverview>> call() async => Success(value);
}

TogetherLiveBloc liveBloc({
  required FakeWatchLive watch,
  FakePublish? publish,
  FakeGetWorkout? getWorkout,
  FakeOverview? overview,
}) => TogetherLiveBloc(
  watch: watch,
  publish: publish ?? FakePublish(),
  getWorkout: getWorkout ?? FakeGetWorkout(workout()),
  overview: overview ?? FakeOverview(),
  firstRetry: const Duration(milliseconds: 10),
  maxRetry: const Duration(milliseconds: 40),
);

/// Deja que el bloc procese lo pendiente.
Future<void> settle([int ms = 0]) =>
    Future<void>.delayed(Duration(milliseconds: ms));
