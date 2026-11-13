package com.synaptixfit.application.port.input.planner;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Da la experiencia de planificar la semana, sin botón: el planificador lo pide cada vez que añade eventos.
 * Solo la concede una vez por semana y si la semana ya tiene suficientes eventos planificados (ADR 0038).
 */
public interface RewardWeekPlanningUseCase {

    /**
     * @param day cualquier día de la semana
     * @return la experiencia dada ahora (0 si no tocaba o ya se dio)
     */
    int rewardWeek(UUID userId, LocalDate day);
}
