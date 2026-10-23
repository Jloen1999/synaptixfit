package com.synaptixfit.application.port.input.notification;

import com.synaptixfit.domain.model.notification.ReminderPlan;
import java.util.UUID;

/** Plan de recordatorios locales que el móvil debe programar en los próximos {@code days} días (1..7). */
public interface GetReminderPlanUseCase {

    ReminderPlan getReminderPlan(UUID userId, int days);
}
