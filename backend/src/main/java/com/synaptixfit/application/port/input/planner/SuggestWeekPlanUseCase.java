package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.WeekPlanSuggestions;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Propone (sin guardar) los bloques de estudio y deporte de una semana a partir de los objetivos, las
 * asignaturas activas, las entregas próximas, las rutinas activas y los huecos ocupados. Usa IA y,
 * si no está disponible, un plan heurístico.
 */
public interface SuggestWeekPlanUseCase {

    record Command(UUID userId, LocalDate weekStart, double studyHours, int sportSessions,
                   int minutesPerSportSession, int maxStudyBlockMinutes) {
    }

    WeekPlanSuggestions.Suggestion suggest(Command command);
}
