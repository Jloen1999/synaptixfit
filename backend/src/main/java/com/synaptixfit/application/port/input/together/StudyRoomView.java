package com.synaptixfit.application.port.input.together;

import com.synaptixfit.domain.model.together.MemberStatus;
import com.synaptixfit.domain.model.together.Person;
import com.synaptixfit.domain.model.together.StudyRoom;
import com.synaptixfit.domain.model.together.StudyRoomLength;
import com.synaptixfit.domain.model.together.StudyRoomReaction;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Una sala de «Estudiamos juntos» tal como la ve una persona (ADR 0045): la fase calculada por el servidor, la hora
 * del servidor para que el móvil corrija su reloj y quién está, quién está invitado y quién se ha ido. La asignatura
 * es solo la propia: la de los demás nunca sale.
 *
 * @param round       ronda en curso (en el descanso, la que acaba de terminar); 0 si no ha empezado
 * @param phaseEndsAt cuándo termina la fase (en la espera, cuándo caduca la sala); nulo si ya terminó
 * @param serverTime  hora del servidor al responder
 * @param mySubjectId mi asignatura para las rondas; nula si no elegí ninguna
 */
public record StudyRoomView(UUID id, Person creator, StudyRoomLength length, int focusMinutes, int breakMinutes,
                            int rounds, StudyRoom.Phase phase, int round, Instant phaseEndsAt, Instant startedAt,
                            Instant endsAt, Instant serverTime, MemberStatus myStatus, UUID mySubjectId,
                            List<Member> members) {

    /** @param reaction su última reacción si es reciente; {@code me} es quien mira */
    public record Member(Person person, MemberStatus status, StudyRoomReaction reaction, boolean me) {
    }
}
