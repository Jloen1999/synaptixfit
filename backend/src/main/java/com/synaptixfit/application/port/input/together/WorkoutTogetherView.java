package com.synaptixfit.application.port.input.together;

import com.synaptixfit.domain.model.together.MemberStatus;
import com.synaptixfit.domain.model.together.Person;
import com.synaptixfit.domain.model.together.WorkoutTogether;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Un «Entrenamos juntos» tal como lo ve una persona (ADR 0044): el día de rutina, los ejercicios por su posición y,
 * de cada persona, cómo va y qué huecos tiene hechos. Nunca pesos, repeticiones ni esfuerzo de nadie.
 *
 * @param mySessionId mi sesión, si ya he empezado
 * @param myMinutes   minutos de mi sesión si la he terminado (para la tarjeta conjunta); nulo si no
 */
public record WorkoutTogetherView(UUID id, Person host, String routineName, String dayName, int dayNumber,
                                  LocalDate date, boolean today, MemberStatus myStatus, UUID mySessionId,
                                  Integer myMinutes, List<Slot> exercises, List<Member> members) {

    public record Slot(int index, UUID exerciseId, String name) {
    }

    /** @param me es quien mira */
    public record Member(Person person, MemberStatus status, WorkoutTogether.MemberState state,
                         List<Integer> doneSlots, boolean me) {
    }
}
