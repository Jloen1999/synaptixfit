package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.ActivityType;
import java.time.Instant;
import java.util.UUID;

/**
 * Apunta una actividad que ya pasó (deporte o estudio): crea el bloque en esa franja y lo marca completado
 * (experiencia, semana y carga física o cognitiva, como al completar cualquier bloque de ese tipo).
 */
public interface LogPastActivityUseCase {

    /**
     * @param title     qué fue («Fútbol», «Temas 3 y 4»); opcional
     * @param effort    esfuerzo percibido (1-10); obligatorio en deporte
     * @param type      {@code SPORT} (por defecto) o {@code STUDY}
     * @param subjectId asignatura del estudio (opcional)
     */
    record Command(UUID userId, Instant start, int minutes, String title, Integer effort, ActivityType type,
                   UUID subjectId) {
    }

    SetBlockCompletionUseCase.Result logPastActivity(Command command);
}
