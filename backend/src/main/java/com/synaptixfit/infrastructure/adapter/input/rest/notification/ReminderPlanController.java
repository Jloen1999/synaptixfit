package com.synaptixfit.infrastructure.adapter.input.rest.notification;

import com.synaptixfit.application.port.input.notification.GetReminderPlanUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.notification.dto.ReminderPlanResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Plan de recordatorios locales del móvil (ADR 0013); delega en {@link GetReminderPlanUseCase}. */
@Tag(name = "Notifications")
@RestController
@RequestMapping("/api/v1/notifications")
public class ReminderPlanController {

    private final GetReminderPlanUseCase getReminderPlan;

    public ReminderPlanController(GetReminderPlanUseCase getReminderPlan) {
        this.getReminderPlan = getReminderPlan;
    }

    @GetMapping("/reminder-plan")
    public ReminderPlanResponse reminderPlan(@CurrentUserId UUID userId,
                                             @RequestParam(defaultValue = "7") int days) {
        return ReminderPlanResponse.from(getReminderPlan.getReminderPlan(userId, days));
    }
}
