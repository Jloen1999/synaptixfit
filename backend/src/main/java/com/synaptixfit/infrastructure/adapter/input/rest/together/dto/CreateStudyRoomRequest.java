package com.synaptixfit.infrastructure.adapter.input.rest.together.dto;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.together.StudyRoom;
import com.synaptixfit.domain.model.together.StudyRoomTimes;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.Set;
import java.util.UUID;

/**
 * Sala de «Estudiamos juntos» con 1-4 amigos: minutos de concentración (15-90) y de descanso (1-30) de cada ronda, de
 * 1 a 4 rondas, y la asignatura propia con la que cuentan (opcional). {@code length} ({@code SHORT}/{@code LONG}) es
 * lo que mandaban las versiones de la app anteriores al ADR 0053: solo se usa si faltan los minutos.
 */
public record CreateStudyRoomRequest(Integer focusMinutes, Integer breakMinutes, String length,
                                     @NotNull @Min(StudyRoom.MIN_ROUNDS) @Max(StudyRoom.MAX_ROUNDS) Integer rounds,
                                     @NotEmpty @Size(max = StudyRoom.MAX_FRIENDS) Set<UUID> friendIds,
                                     UUID subjectId) {

    /**
     * Los minutos pedidos (el dominio comprueba los límites). Sin ninguno de los dos, el atajo que mandaba la versión
     * antigua; con solo uno, es un error: no se adivina el otro.
     */
    public StudyRoomTimes times() {
        if (focusMinutes == null && breakMinutes == null) {
            return "LONG".equals(length) ? StudyRoomTimes.LONG : StudyRoomTimes.SHORT;
        }
        if (focusMinutes == null || breakMinutes == null) {
            String missing = focusMinutes == null ? "focusMinutes" : "breakMinutes";
            throw new FieldValidationException(missing, "REQUIRED", missing + " is required");
        }
        return new StudyRoomTimes(focusMinutes, breakMinutes);
    }
}
