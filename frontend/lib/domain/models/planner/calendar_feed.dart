import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_feed.freezed.dart';

/// Estado del enlace de suscripción al calendario (el enlace en sí no se
/// puede volver a ver: solo existe al crearlo).
@freezed
abstract class CalendarFeedStatus with _$CalendarFeedStatus {
  const factory CalendarFeedStatus({
    @Default(false) bool active,
    DateTime? activeSince,
  }) = _CalendarFeedStatus;
}

/// Enlace recién creado para suscribirse desde Google, Apple u Outlook.
@freezed
abstract class CalendarFeedLink with _$CalendarFeedLink {
  const factory CalendarFeedLink({
    /// `https://…/calendar-feed/<token>.ics`.
    required String url,
    required DateTime createdAt,
  }) = _CalendarFeedLink;

  const CalendarFeedLink._();

  /// Mismo enlace con el esquema `webcal://`, que abre la app de calendario.
  String get webcalUrl => url.replaceFirst(RegExp('^https?://'), 'webcal://');
}
