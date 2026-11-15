package com.synaptixfit.domain.model.training;

import java.util.UUID;

/**
 * Nombre legible de una sesión: rutina y día que se entrenó («Tracción: dominadas y bíceps»). Si el
 * día no tiene nombre se queda nulo y el cliente muestra «Día N»; en sesiones libres o si la rutina
 * se borró, todo es nulo. {@code coverImageUrl}: foto de su tarjeta (ADR 0042), la del primer ejercicio del día
 * (la misma que la del próximo entreno) o, en una sesión libre, la del primer ejercicio apuntado; nula si no hay.
 */
public record SessionLabel(UUID sessionId, String routineName, String dayName, Integer dayNumber,
                           Integer weekNumber, String coverImageUrl) {

    public SessionLabel(UUID sessionId, String routineName, String dayName, Integer dayNumber, Integer weekNumber) {
        this(sessionId, routineName, dayName, dayNumber, weekNumber, null);
    }

    /**
     * Foto de la tarjeta: la del día entrenado si la tiene y, si no (sesión libre o día sin foto), la del primer
     * ejercicio apuntado. Sin ninguna, nula: el cliente pone el color de reserva.
     *
     * @param dayCover      imagen fija del primer ejercicio del día con imagen ({@link ExerciseRef#stillImage})
     * @param firstSetCover imagen fija del primer ejercicio apuntado con imagen
     */
    public SessionLabel withCover(String dayCover, String firstSetCover) {
        String cover = dayCover != null && !dayCover.isBlank() ? dayCover
                : firstSetCover != null && !firstSetCover.isBlank() ? firstSetCover : null;
        return new SessionLabel(sessionId, routineName, dayName, dayNumber, weekNumber, cover);
    }
}
