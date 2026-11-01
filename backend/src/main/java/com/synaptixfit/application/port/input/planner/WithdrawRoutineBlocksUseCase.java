package com.synaptixfit.application.port.input.planner;

import java.util.Set;
import java.util.UUID;

/**
 * Retira del calendario los bloques pendientes (no completados) de una rutina que ya no se van a
 * entrenar: los de unos días concretos (saltados o quitados de la rutina) o los futuros de toda la
 * rutina (pausada, borrada o con el ciclo terminado). Los completados se quedan como historial, salvo
 * los de días quitados de la rutina: al perder el enlace contarían como deporte libre (doble cuenta).
 * Idempotente (lo invocan los oyentes de {@code RoutineDaysSkipped}, {@code RoutineDaysRemoved} y
 * {@code RoutineDeactivated}).
 */
public interface WithdrawRoutineBlocksUseCase {

    /**
     * @param dayIds     días concretos (todas sus fechas); vacío para toda la rutina
     * @param onlyFuture       solo los que aún no han empezado
     * @param includeCompleted también los completados (días que dejan de existir)
     */
    record Command(UUID userId, UUID routineId, Set<UUID> dayIds, boolean onlyFuture, boolean includeCompleted) {

        public Command {
            dayIds = dayIds == null ? Set.of() : Set.copyOf(dayIds);
        }

        public Command(UUID userId, UUID routineId, Set<UUID> dayIds, boolean onlyFuture) {
            this(userId, routineId, dayIds, onlyFuture, false);
        }
    }

    void withdraw(Command command);
}
