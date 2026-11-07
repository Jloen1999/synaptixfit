package com.synaptixfit.infrastructure.adapter.input.rest.notification.dto;

import com.synaptixfit.domain.model.notification.ReminderOptions;
import jakarta.validation.constraints.NotNull;
import java.time.LocalTime;
import java.util.HashSet;
import java.util.List;

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
    public static ReminderOptionsDto from(ReminderOptions o) {
        return new ReminderOptionsDto(o.streak(), o.checkIn(), o.classes(), o.eventLeadMinutes(),
                o.deadlineDaysBefore().stream().sorted().toList(), o.taskTiming(), o.morningSummary(),
                o.morningSummaryAt());
    }

    public ReminderOptions.Change toChange() {
        return new ReminderOptions.Change(streak, checkIn, classes, eventLeadMinutes,
                deadlineDaysBefore == null ? null : new HashSet<>(deadlineDaysBefore), taskTiming,
                morningSummaryAt, morningSummary);
    }
}
