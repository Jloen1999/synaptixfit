import '../../models/result/app_result.dart';
import '../../models/training/run.dart';
import '../../repositories/run_repository_contract.dart';

/// GPS mientras se graba una carrera: los puntos, el aviso fijo con las cifras
/// («Grabando tu carrera · 3,2 km · 18:40») y la vibración al cambiar de paso.
/// En web y escritorio [supported] es `false`: se graba desde el móvil.
abstract interface class TrackRunUseCaseContract {
  bool get supported;

  Stream<AppResult<RunFix>> watch({
    required String notificationTitle,
    required String notificationText,
    required String channelName,
  });

  Future<void> updateNotification({
    required String title,
    required String text,
    required String channelName,
  });

  Future<void> vibrate();
}

class TrackRunUseCase implements TrackRunUseCaseContract {
  const TrackRunUseCase(this._repository);

  final RunTrackerRepositoryContract _repository;

  @override
  bool get supported => _repository.supported;

  @override
  Stream<AppResult<RunFix>> watch({
    required String notificationTitle,
    required String notificationText,
    required String channelName,
  }) => _repository.watch(
    notificationTitle: notificationTitle,
    notificationText: notificationText,
    channelName: channelName,
  );

  @override
  Future<void> updateNotification({
    required String title,
    required String text,
    required String channelName,
  }) => _repository.updateNotification(
    title: title,
    text: text,
    channelName: channelName,
  );

  @override
  Future<void> vibrate() => _repository.vibrate();
}
