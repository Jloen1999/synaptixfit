package com.synaptixfit.application.port.input.insights;

import com.synaptixfit.domain.model.insights.CompletedStudyBlock;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Actividad cognitiva del usuario en [from, to): bloques completados y prácticas sin bloque que
 * cuentan ({@code StudyActivity}). Es la fuente única de los minutos de estudio de Indicadores e Inicio.
 */
public interface GetStudyActivityUseCase {

    List<CompletedStudyBlock> getStudyActivity(UUID userId, Instant from, Instant to);
}
