package com.synaptixfit.application.port.input.together;

import com.synaptixfit.domain.model.together.StudyRoomTimes;
import java.util.Set;
import java.util.UUID;

/** Crea una sala de «Estudiamos juntos» con 1-4 amigos mutuos y sus minutos; quien la crea queda dentro (ADR 0045). */
public interface CreateStudyRoomUseCase {

    StudyRoomView create(Command command);

    /** @param subjectId asignatura propia con la que cuentan las rondas (opcional) */
    record Command(UUID userId, StudyRoomTimes times, int rounds, Set<UUID> friendIds, UUID subjectId) {
    }
}
