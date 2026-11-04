package com.synaptixfit.infrastructure.adapter.input.rest.notification;

import com.synaptixfit.application.port.input.notification.ChangeReminderOptionsUseCase;
import com.synaptixfit.application.port.input.notification.GetReminderOptionsUseCase;
import com.synaptixfit.domain.model.notification.ReminderOptions;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Avisos opcionales del móvil (racha en riesgo, registro diario, clase en 15 min), que se apagan uno a uno. */
@Tag(name = "Notifications")
@RestController
@RequestMapping("/api/v1/notifications/reminder-options")
public class ReminderOptionsController {

    /** Avisos opcionales: {@code streak}, {@code checkIn} y {@code classes}. */
    public record ReminderOptionsDto(@NotNull Boolean streak, @NotNull Boolean checkIn, @NotNull Boolean classes) {
        static ReminderOptionsDto from(ReminderOptions o) {
            return new ReminderOptionsDto(o.streak(), o.checkIn(), o.classes());
        }
    }

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
        return ReminderOptionsDto.from(change.change(userId, new ReminderOptions(r.streak(), r.checkIn(),
                r.classes())));
    }
}
