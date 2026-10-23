package com.synaptixfit.infrastructure.adapter.input.rest.notification.dto;

import com.synaptixfit.domain.model.notification.NotificationMode;
import com.synaptixfit.domain.model.notification.NotificationType;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.time.LocalTime;
import java.util.Set;

/** Sustituye las preferencias. Horas de silencio: ambas nulas o ambas informadas y distintas. */
public record UpdateNotificationPreferencesRequest(@NotNull Set<NotificationType> activeCategories,
                                                   LocalTime quietHoursStart,
                                                   LocalTime quietHoursEnd,
                                                   @NotNull @Min(0) @Max(50) Integer dailyLimit,
                                                   @NotNull NotificationMode mode) {
}
