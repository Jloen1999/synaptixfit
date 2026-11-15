package com.synaptixfit.domain.exception.together;

import com.synaptixfit.domain.exception.NotFoundException;
import java.util.UUID;

/** La sala de «Estudiamos juntos» no existe, no te invitaron o saliste de ella (ADR 0045). */
public class StudyRoomNotFoundException extends NotFoundException {

    public StudyRoomNotFoundException(UUID id) {
        super("STUDY_ROOM_NOT_FOUND", "Study room " + id + " not found");
    }
}
