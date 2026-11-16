part of 'guide_tour_bloc.dart';

@freezed
sealed class GuideTourEvent with _$GuideTourEvent {
  /// La pantalla ya tiene su contenido y nada encima: ¿toca la guía?
  const factory GuideTourEvent.requested({
    required GuideId guide,
    required String accountId,
  }) = GuideTourRequested;

  /// Se cerró la guía (terminada, saltada o con «atrás»): queda vista.
  const factory GuideTourEvent.closed() = GuideTourClosed;

  /// No se pudo enseñar (no hay nada que señalar): no se apunta como vista.
  const factory GuideTourEvent.abandoned() = GuideTourAbandoned;
}
