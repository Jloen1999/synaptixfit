package com.synaptixfit.application.port.input.insights;

import com.synaptixfit.domain.model.insights.StudyCaloriesSummary;
import java.util.UUID;

/** Minutos y calorías de estudio de hoy: bloques completados y prácticas (Pomodoro, tests, repasos). */
public interface GetStudyCaloriesTodayUseCase {

    StudyCaloriesSummary getStudyCaloriesToday(UUID userId, String timeZone);
}
