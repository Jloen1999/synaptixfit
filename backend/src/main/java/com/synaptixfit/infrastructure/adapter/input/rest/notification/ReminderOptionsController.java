package com.synaptixfit.infrastructure.adapter.input.rest.notification;

import com.synaptixfit.application.port.input.notification.ChangeReminderOptionsUseCase;
import com.synaptixfit.application.port.input.notification.GetReminderOptionsUseCase;
import com.synaptixfit.domain.model.notification.ReminderOptions;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.time.LocalTime;
import java.util.HashSet;
import java.util.List;
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

    /**
     * Opciones de avisos. {@code eventLeadMinutes}: 5, 15, 30 o 60; {@code deadlineDaysBefore}: uno o varios de 1, 3
     * y 7; {@code taskTiming}: {@code EVENING_BEFORE} o {@code MORNING_OF}; {@code morningSummaryAt}: hora local
     * («08:00»), nula si {@code morningSummary} es false. Al guardar, los tres interruptores son obligatorios y el resto
     * es opcional: lo que no se manda no cambia (una app antigua solo manda los interruptores);
     * {@code morningSummary=false} apaga el resumen y {@code true} sin hora lo enciende a su hora de antes o a las 8:00.
     */
    public record ReminderOptionsDto(@NotNull Boolean streak, @NotNull Boolean checkIn, @NotNull Boolean classes,
                                     Integer eventLeadMinutes, List<Integer> deadlineDaysBefore,
                                     ReminderOptions.TaskTiming taskTiming, Boolean morningSummary,
                                     LocalTime morningSummaryAt) {
        static ReminderOptionsDto from(ReminderOptions o) {
            return new ReminderOptionsDto(o.streak(), o.checkIn(), o.classes(), o.eventLeadMinutes(),
                    o.deadlineDaysBefore().stream().sorted().toList(), o.taskTiming(), o.morningSummary(),
                    o.morningSummaryAt());
        }

        ReminderOptions.Change toChange() {
            return new ReminderOptions.Change(streak, checkIn, classes, eventLeadMinutes,
                    deadlineDaysBefore == null ? null : new HashSet<>(deadlineDaysBefore), taskTiming,
                    morningSummaryAt, morningSummary);
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
        return ReminderOptionsDto.from(change.change(userId, r.toChange()));
    }
}
