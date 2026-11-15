package com.synaptixfit.infrastructure.adapter.input.rest.together.dto;

import com.synaptixfit.application.port.input.together.StudyRoomView;
import com.synaptixfit.domain.model.together.MemberStatus;
import com.synaptixfit.domain.model.together.StudyRoom;
import com.synaptixfit.domain.model.together.StudyRoomReaction;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Sala de «Estudiamos juntos» (ADR 0045): la fase y cuándo termina según el servidor, con {@code serverTime} para que
 * el móvil corrija su reloj, y quién está, quién está invitado y quién se ha ido. {@code mySubjectId} es solo la
 * asignatura propia: la de los demás nunca sale.
 */
public record StudyRoomResponse(UUID id, PersonResponse creator, int focusMinutes, int breakMinutes,
                                int rounds, StudyRoom.Phase phase, int round, Instant phaseEndsAt,
                                Instant startedAt, Instant endsAt, Instant serverTime, MemberStatus myStatus,
                                UUID mySubjectId, List<StudyRoomMember> members) {

    public record StudyRoomMember(PersonResponse person, MemberStatus status, StudyRoomReaction reaction, boolean me) {
    }

    public static StudyRoomResponse from(StudyRoomView v) {
        return new StudyRoomResponse(v.id(), PersonResponse.from(v.creator()), v.focusMinutes(),
                v.breakMinutes(), v.rounds(), v.phase(), v.round(), v.phaseEndsAt(), v.startedAt(), v.endsAt(),
                v.serverTime(), v.myStatus(), v.mySubjectId(),
                v.members().stream().map(m -> new StudyRoomMember(PersonResponse.from(m.person()), m.status(),
                        m.reaction(), m.me())).toList());
    }
}
