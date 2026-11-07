package com.synaptixfit.infrastructure.adapter.input.rest.notification;

import com.synaptixfit.application.port.input.notification.ChangeReminderOptionsUseCase;
import com.synaptixfit.application.port.input.notification.GetReminderOptionsUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.notification.dto.ReminderOptionsDto;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Opciones de avisos del móvil (ADR 0033 y 0035): racha en riesgo, registro diario y clase a punto de empezar, que se
 * apagan uno a uno; antelación de eventos y clases, de entregas y exámenes y de tareas de reto; y el resumen de la
 * mañana. Al cambiarlas, el móvil vuelve a pedir el plan de avisos.
 */
@Tag(name = "Notifications")
@RestController
@RequestMapping("/api/v1/notifications/reminder-options")
public class ReminderOptionsController {

    private final GetReminderOptionsUseCase get;
    private final ChangeReminderOptionsUseCase change;

    public ReminderOptionsController(GetReminderOptionsUseCase get, ChangeReminderOptionsUseCase change) {
        this.get = get;
        this.change = change;
    }

    @GetMapping
    public ReminderOptionsDto get(@CurrentUserId UUID userId) {
        return ReminderOptionsDto.from(get.get(userId));
    }

    @PutMapping
    public ReminderOptionsDto change(@CurrentUserId UUID userId, @Valid @RequestBody ReminderOptionsDto r) {
        return ReminderOptionsDto.from(change.change(userId, r.toChange()));
    }
}
