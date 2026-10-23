package com.synaptixfit.application.port.input.analytics;

import com.synaptixfit.domain.model.analytics.StudyWeekSummary;
import java.util.UUID;

/** Cómo va el estudio esta semana: concentración, bloques, repasos y simulacros. */
public interface GetStudyWeekSummaryUseCase {

    StudyWeekSummary getStudyWeekSummary(UUID userId);
}
