package com.synaptixfit.application.port.input.planner;

import com.synaptixfit.domain.model.planner.FocusSession;
import com.synaptixfit.domain.model.planner.FocusXpStatus;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Registra una fase Pomodoro terminada (el temporizador vive en el cliente). Una fase de
 * concentración completada da XP con tope diario y publica {@code FocusSessionCompleted}.
 */
public interface RecordFocusSessionUseCase {

    /**
     * @param date      día del ciclo (nulo: hoy en la zona del planificador)
     * @param blockId   bloque propio en el que se hizo (opcional, informativo: no lo completa)
     * @param subjectId asignatura propia trabajada (opcional; si falta, la del bloque)
     */
    record Command(UUID userId, FocusSession.FocusPhase phase, int durationMinutes, int cycles, boolean completed,
                   LocalDate date, UUID blockId, UUID subjectId) {
    }

    /**
     * Fase guardada y motivo de su XP ({@code session.xpAwarded()}): el cliente muestra el aviso de
     * tope diario con {@code xpStatus}, sin repetir la regla de {@code FocusRewards}.
     */
    record Result(FocusSession session, FocusXpStatus xpStatus) {
    }

    Result record(Command command);
}
