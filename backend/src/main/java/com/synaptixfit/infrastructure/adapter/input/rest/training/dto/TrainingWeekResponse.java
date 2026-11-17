package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.domain.model.training.TrainingWeek;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * La semana de entreno (lunes a domingo) para los siete puntos de Gimnasio (ADR 0055). {@code done}/{@code total}:
 * días entrenados de los que tocan («2 de 4»). {@code sessionId}: el entreno de ese día, para abrirlo.
 */
public record TrainingWeekResponse(List<TrainingWeekDay> days, int done, int total) {

    /** Un día de la semana (nombre único en el contrato: ya hay otro {@code Day}). */
    public record TrainingWeekDay(LocalDate date, TrainingWeek.DayState state, boolean today, UUID sessionId) {
    }

    public static TrainingWeekResponse from(TrainingWeek week) {
        return new TrainingWeekResponse(week.days().stream()
                .map(d -> new TrainingWeekDay(d.date(), d.state(), d.today(), d.sessionId())).toList(), week.done(), week.total());
    }
}
