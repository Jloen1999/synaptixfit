package com.synaptixfit.infrastructure.adapter.input.rest.together.dto;

import com.synaptixfit.domain.model.together.StudyRoom;
import com.synaptixfit.domain.model.together.StudyRoomLength;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.Set;
import java.util.UUID;

/**
 * Sala de «Estudiamos juntos» con 1-4 amigos: 25 + 5 ({@code SHORT}) o 50 + 10 ({@code LONG}) minutos por ronda,
 * de 1 a 4 rondas, y la asignatura propia con la que cuentan (opcional).
 */
public record CreateStudyRoomRequest(@NotNull StudyRoomLength length,
                                     @NotNull @Min(StudyRoom.MIN_ROUNDS) @Max(StudyRoom.MAX_ROUNDS) Integer rounds,
                                     @NotEmpty @Size(max = StudyRoom.MAX_FRIENDS) Set<UUID> friendIds,
                                     UUID subjectId) {
}
