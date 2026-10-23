import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/profile/notification_category.dart';
import '../../../../domain/enums/profile/notification_mode.dart';
import '../../../../domain/models/profile/notification_preferences.dart';

part 'notification_preferences_dto.freezed.dart';
part 'notification_preferences_dto.g.dart';

@freezed
abstract class NotificationPreferencesDto with _$NotificationPreferencesDto {
  const factory NotificationPreferencesDto({
    @Default(<String>[]) List<String> activeCategories,
    String? quietHoursStart,
    String? quietHoursEnd,
    @Default(0) int dailyLimit,
    String? mode,
  }) = _NotificationPreferencesDto;

  const NotificationPreferencesDto._();

  factory NotificationPreferencesDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesDtoFromJson(json);

  NotificationPreferences toDomain() => NotificationPreferences(
    activeCategories: activeCategories
        .map(NotificationCategory.fromApi)
        .whereType<NotificationCategory>()
        .toSet(),
    quietHoursStart: ClockTime.tryParse(quietHoursStart),
    quietHoursEnd: ClockTime.tryParse(quietHoursEnd),
    dailyLimit: dailyLimit,
    mode: NotificationMode.fromApi(mode),
  );
}

/// Cuerpo de PUT `/notifications/preferences`.
Map<String, dynamic> notificationPreferencesToJson(
  NotificationPreferences preferences,
) => {
  'activeCategories': [
    for (final category in NotificationCategory.values)
      if (preferences.activeCategories.contains(category)) category.apiValue,
  ],
  'quietHoursStart': preferences.quietHoursStart?.apiValue,
  'quietHoursEnd': preferences.quietHoursEnd?.apiValue,
  'dailyLimit': preferences.dailyLimit,
  'mode': preferences.mode.apiValue,
};
