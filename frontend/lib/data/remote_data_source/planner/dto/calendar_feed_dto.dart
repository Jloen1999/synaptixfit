import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/planner/calendar_feed.dart';
import 'planner_json.dart';

part 'calendar_feed_dto.freezed.dart';
part 'calendar_feed_dto.g.dart';

/// Respuesta de `GET /planner/calendar-feed`: si hay enlace y desde cuándo.
@freezed
abstract class CalendarFeedStatusDto with _$CalendarFeedStatusDto {
  const factory CalendarFeedStatusDto({
    @Default(false) bool active,
    String? activeSince,
  }) = _CalendarFeedStatusDto;

  const CalendarFeedStatusDto._();

  factory CalendarFeedStatusDto.fromJson(Map<String, dynamic> json) =>
      _$CalendarFeedStatusDtoFromJson(json);

  CalendarFeedStatus toDomain() => CalendarFeedStatus(
    active: active,
    activeSince: PlannerJson.instantOrNull(activeSince),
  );
}

/// Respuesta de `POST /planner/calendar-feed`: el token se ve solo esta vez.
@freezed
abstract class CalendarFeedCreatedDto with _$CalendarFeedCreatedDto {
  const factory CalendarFeedCreatedDto({
    required String token,
    required String createdAt,
  }) = _CalendarFeedCreatedDto;

  const CalendarFeedCreatedDto._();

  factory CalendarFeedCreatedDto.fromJson(Map<String, dynamic> json) =>
      _$CalendarFeedCreatedDtoFromJson(json);

  /// [url]: la dirección pública que compone el data source con el token.
  CalendarFeedLink toDomain(String url) =>
      CalendarFeedLink(url: url, createdAt: PlannerJson.instant(createdAt));
}
