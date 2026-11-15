package com.synaptixfit.infrastructure.adapter.input.rest.together.dto;

import com.synaptixfit.application.port.input.together.WorkoutTogetherView;
import com.synaptixfit.domain.model.together.MemberStatus;
import com.synaptixfit.domain.model.together.WorkoutTogether;
import com.synaptixfit.infrastructure.adapter.input.rest.support.LocalizedNames;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * «Entrenamos juntos» (ADR 0044): ejercicios por su posición (con el nombre en el idioma de la petición) y, de cada
 * persona, cómo va y qué posiciones tiene hechas. Sin pesos, repeticiones ni esfuerzo. A la vez (ADR 0047): la hora
 * de inicio común ({@code startedAt}, nula hasta que alguien pulsa «Empezar») y quién empezó, y la pausa del grupo y
 * quién la puso.
 */
public record WorkoutTogetherResponse(UUID id, PersonResponse host, String routineName, String dayName,
                                      int dayNumber, LocalDate date, boolean today, MemberStatus myStatus,
                                      UUID mySessionId, Integer myMinutes, List<WorkoutTogetherSlot> exercises,
                                      List<WorkoutTogetherMember> members, Instant startedAt,
                                      PersonResponse startedBy, Instant pausedAt, PersonResponse pausedBy) {

    public record WorkoutTogetherSlot(int index, UUID exerciseId, String name) {
    }

    public record WorkoutTogetherMember(PersonResponse person, MemberStatus status,
                                        WorkoutTogether.MemberState state,
                         List<Integer> doneSlots, boolean me) {
    }

    public static WorkoutTogetherResponse from(WorkoutTogetherView v) {
        return new WorkoutTogetherResponse(v.id(), PersonResponse.from(v.host()), v.routineName(), v.dayName(),
                v.dayNumber(), v.date(), v.today(), v.myStatus(), v.mySessionId(), v.myMinutes(),
                v.exercises().stream().map(s -> new WorkoutTogetherSlot(s.index(), s.exerciseId(),
                        LocalizedNames.exercise(s.exerciseId(), s.name()))).toList(),
                v.members().stream().map(m -> new WorkoutTogetherMember(PersonResponse.from(m.person()), m.status(),
                        m.state(),
                        m.doneSlots(), m.me())).toList(),
                v.startedAt(), v.startedBy() == null ? null : PersonResponse.from(v.startedBy()), v.pausedAt(),
                v.pausedBy() == null ? null : PersonResponse.from(v.pausedBy()));
    }
}
