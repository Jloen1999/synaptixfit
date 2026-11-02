package com.synaptixfit.domain.model.academic;

import java.time.Instant;
import java.util.List;

/**
 * Intervalos que resultarían de cada nivel de autoevaluación (0-5) con la fatiga física actual y, si se
 * practicó hace poco, la nota que se propone con esa práctica ({@code practice}, puede ser nulo).
 */
public record ReviewPreview(double loadToday, double maxDailyLoad, double fatigueCoefficient, List<Option> options,
                            PracticeScore practice) {

    public ReviewPreview(double loadToday, double maxDailyLoad, double fatigueCoefficient, List<Option> options) {
        this(loadToday, maxDailyLoad, fatigueCoefficient, options, null);
    }

    public record Option(int quality, double adjustedQuality, int intervalDays, Instant nextReviewAt,
                         MasteryState resultingState) {
    }

    public ReviewPreview {
        options = List.copyOf(options);
    }
}
