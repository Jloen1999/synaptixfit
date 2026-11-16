part of 'guide_tour_bloc.dart';

/// [idle]: aún no se ha preguntado; [checking]: preguntando; [showing]: toca
/// enseñarla; [saving]: cerrada, apuntándola como vista; [done]: ya está
/// (vista, no tocaba o no se pudo).
enum GuideTourStatus { idle, checking, showing, saving, done }

@freezed
abstract class GuideTourState with _$GuideTourState {
  const factory GuideTourState({
    @Default(GuideTourStatus.idle) GuideTourStatus status,
    GuideId? guide,
    String? accountId,
  }) = _GuideTourState;
}
