package com.synaptixfit.domain.port.output.planner;

import com.synaptixfit.domain.model.planner.FocusSession;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Persistencia de los ciclos Pomodoro ({@code sesiones_focus}). */
public interface FocusSessionRepositoryPort {

    FocusSession save(FocusSession session);

    /** XP de Pomodoro ya concedida al usuario en ese día (para el tope diario). */
    int sumXpAwarded(UUID userId, LocalDate date);

    /** Registros con fecha en [from, to] (ambas incluidas). */
    List<FocusSession> findByUserBetween(UUID userId, LocalDate from, LocalDate to);
}
