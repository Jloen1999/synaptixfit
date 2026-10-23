package com.synaptixfit.domain.model.academic;

import java.time.Instant;
import java.util.List;

/**
 * Intervalos que resultarían de cada nivel de autoevaluación (0-5) con la fatiga física actual.
 * El cliente los muestra en el modal de evaluación.
 */
public record ReviewPreview(double loadToday, double maxDailyLoad, double fatigueCoefficient, List<Option> options) {

    public record Option(int quality, double adjustedQuality, int intervalDays, Instant nextReviewAt,
                         MasteryState resultingState) {
    }

    public ReviewPreview {
        options = List.copyOf(options);
    }
}
