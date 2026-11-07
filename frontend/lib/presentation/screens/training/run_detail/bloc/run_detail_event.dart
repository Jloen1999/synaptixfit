part of 'run_detail_bloc.dart';

@freezed
sealed class RunDetailEvent with _$RunDetailEvent {
  const factory RunDetailEvent.started(String blockId) = RunDetailStarted;

  const factory RunDetailEvent.deleteRequested() = RunDetailDeleteRequested;

  const factory RunDetailEvent.deleteUndone() = RunDetailDeleteUndone;

  const factory RunDetailEvent.deleteCommitted() = RunDetailDeleteCommitted;

  /// Imagen solo con las cifras (nunca el mapa: diría dónde vive la persona).
  const factory RunDetailEvent.shared(Uint8List png, String text) =
      RunDetailShared;
}
